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
const phrases = [];
const seen = new Set();
for (const m of entries) {
  const val = (m[2] ?? m[3] ?? '').replace(/\\'/g, "'").replace(/\\"/g, '"');
  if (!val || val.includes('{') || val.length < 2) continue;
  if (seen.has(val)) continue;
  seen.add(val);
  phrases.push(val);
}
phrases.sort((a, b) => b.length - a.length);

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

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function escapeDartSingle(s) {
  return s.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function alreadyLocalized(line) {
  return (
    line.includes('context.tr(') ||
    line.includes('context.l10n') ||
    line.includes('.translate(') ||
    line.trimStart().startsWith('//') ||
    line.trimStart().startsWith('*') ||
    line.includes('import ')
  );
}

const files = [
  ...walk('lib/features'),
  ...walk('lib/core/widgets'),
  ...walk('lib/core/auth'),
];

let changedFiles = 0;
let replacements = 0;

for (const file of files) {
  let lines = fs.readFileSync(file, 'utf8').split(/(?<=\n)/);
  let fileHits = 0;
  let touched = false;

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    if (alreadyLocalized(line)) continue;

    for (const phrase of phrases) {
      if (phrase.length <= 2 && !['OK', 'No', 'To'].includes(phrase)) continue;
      const esc = escapeRegex(phrase);
      const lit = escapeDartSingle(phrase);

      const rules = [
        [new RegExp(`const Text\\('${esc}'\\)`), `Text(context.tr('${lit}'))`],
        [new RegExp(`Text\\('${esc}'\\)`), `Text(context.tr('${lit}'))`],
        [new RegExp(`const Text\\("${esc}"\\)`), `Text(context.tr('${lit}'))`],
        [new RegExp(`Text\\("${esc}"\\)`), `Text(context.tr('${lit}'))`],
        [new RegExp(`title:\\s*'${esc}'`), `title: context.tr('${lit}')`],
        [new RegExp(`label:\\s*'${esc}'`), `label: context.tr('${lit}')`],
        [new RegExp(`hintText:\\s*'${esc}'`), `hintText: context.tr('${lit}')`],
        [new RegExp(`subtitle:\\s*'${esc}'`), `subtitle: context.tr('${lit}')`],
        [new RegExp(`helpText:\\s*'${esc}'`), `helpText: context.tr('${lit}')`],
        [new RegExp(`tooltip:\\s*'${esc}'`), `tooltip: context.tr('${lit}')`],
        [new RegExp(`semanticsLabel:\\s*'${esc}'`), `semanticsLabel: context.tr('${lit}')`],
      ];

      for (const [re, to] of rules) {
        if (!re.test(line)) continue;
        // Avoid matching inside already-transformed fragments on same line.
        if (line.includes(`context.tr('${lit}')`)) continue;
        const next = line.replace(re, to);
        if (next !== line) {
          line = next;
          fileHits += 1;
          touched = true;
        }
      }
    }
    lines[i] = line;
  }

  if (!touched) continue;

  let text = lines.join('');
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

console.log(
  `DONE files=${changedFiles} replacements=${replacements} phrases=${phrases.length}`,
);
