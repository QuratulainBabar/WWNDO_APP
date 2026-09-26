import fs from 'fs';
import path from 'path';

const tablesPath = 'lib/l10n/string_tables.dart';
const src = fs.readFileSync(tablesPath, 'utf8');
const enBlock = src.match(/const Map<String, String> _en = \{([\s\S]*?)\n\};/);
if (!enBlock) throw new Error('en block not found');

const entries = [
  ...enBlock[1].matchAll(
    /'([^']+)':\s*(?:'((?:\\'|[^'])*)'|"((?:\\"|[^"])*)")/g,
  ),
];
const englishToKey = new Map();
for (const m of entries) {
  const key = m[1];
  const val = (m[2] ?? m[3] ?? '').replace(/\\'/g, "'").replace(/\\"/g, '"');
  if (!val || val.includes('{')) continue;
  if (!englishToKey.has(val)) englishToKey.set(val, key);
}

const phrases = [...englishToKey.keys()].sort((a, b) => b.length - a.length);

function walk(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) {
      if (name === 'l10n') continue;
      walk(p, out);
    } else if (name.endsWith('.dart')) out.push(p);
  }
  return out;
}

const files = [
  ...walk('lib/features'),
  ...walk('lib/core/widgets'),
  ...walk('lib/core/auth'),
];

let changedFiles = 0;
let replacements = 0;

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function escapeDartSingle(s) {
  return s.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

for (const file of files) {
  let text = fs.readFileSync(file, 'utf8');
  const original = text;
  let fileHits = 0;

  for (const phrase of phrases) {
    const short = phrase.length <= 3;
    const escaped = escapeRegex(phrase);
    const dartLit = escapeDartSingle(phrase);

    const patterns = [
      [`const Text\\('${escaped}'`, `Text(context.tr('${dartLit}'`],
      [`Text\\('${escaped}'`, `Text(context.tr('${dartLit}'`],
      [`title: '${escaped}'`, `title: context.tr('${dartLit}'`],
      [`label: '${escaped}'`, `label: context.tr('${dartLit}'`],
      [`hintText: '${escaped}'`, `hintText: context.tr('${dartLit}'`],
      [`subtitle: '${escaped}'`, `subtitle: context.tr('${dartLit}'`],
      [`helpText: '${escaped}'`, `helpText: context.tr('${dartLit}'`],
    ];

    const usePatterns = short
      ? patterns.filter(
          ([from]) =>
            from.startsWith('Text') ||
            from.startsWith('const Text') ||
            from.startsWith('title') ||
            from.startsWith('label') ||
            from.startsWith('hint') ||
            from.startsWith('subtitle'),
        )
      : patterns;

    for (const [from, to] of usePatterns) {
      const re = new RegExp(from, 'g');
      text = text.replace(re, (match, offset) => {
        const before = text.slice(Math.max(0, offset - 30), offset);
        if (
          before.includes('context.tr(') ||
          before.includes('context.l10n') ||
          before.includes('.translate(') ||
          before.includes('import ')
        ) {
          return match;
        }
        fileHits += 1;
        return to;
      });
    }
  }

  if (text !== original) {
    if (!text.includes('l10n/app_localizations.dart')) {
      const importRe = /^(import .+;\r?\n)+/m;
      const m = text.match(importRe);
      if (m) {
        let rel = path
          .relative(path.dirname(file), 'lib/l10n/app_localizations.dart')
          .replace(/\\/g, '/');
        if (!rel.startsWith('.')) rel = `./${rel}`;
        text = text.replace(importRe, `${m[0]}import '${rel}';\n`);
      }
    }
    fs.writeFileSync(file, text);
    changedFiles += 1;
    replacements += fileHits;
    console.log(`updated ${file} hits=${fileHits}`);
  }
}

console.log(
  `DONE files=${changedFiles} replacements=${replacements} phrases=${phrases.length}`,
);
