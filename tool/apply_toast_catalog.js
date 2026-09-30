// One-off codegen script: appends toast localization keys to string_tables_extra.dart
// for all 11 languages. Run with: node tool/apply_toast_catalog.js
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const FILE = path.join(ROOT, 'lib', 'l10n', 'string_tables_extra.dart');

const staticEntries = require('./toast_static.json');
const templateEntries = require('./toast_templates.json');

const LANGS = ['en', 'fr', 'es', 'it', 'nl', 'de', 'ar', 'hi', 'zh', 'tr', 'ru'];

function escapeDart(str) {
  return str
    .replace(/\\/g, '\\\\')
    .replace(/\$/g, '\\$')
    .replace(/'/g, "\\'");
}

function buildLinesForLang(lang) {
  const lines = [];
  for (const [key, byLang] of Object.entries(staticEntries)) {
    const value = byLang[lang];
    if (value === undefined) throw new Error(`Missing lang ${lang} for static key ${key}`);
    lines.push(`  '${key}': '${escapeDart(value)}',`);
  }
  for (const [key, byLang] of Object.entries(templateEntries)) {
    const value = byLang[lang];
    if (value === undefined) throw new Error(`Missing lang ${lang} for template key ${key}`);
    lines.push(`  '${key}': '${escapeDart(value)}',`);
  }
  return lines;
}

let content = fs.readFileSync(FILE, 'utf8');
const lines = content.split('\n');

// Find each language block's opening and closing line indices.
const blockRe = /^const Map<String, String> _(\w+)Extra = \{$/;
const blocks = []; // { lang, openIdx, closeIdx }
for (let i = 0; i < lines.length; i++) {
  const m = blockRe.exec(lines[i]);
  if (m) {
    const langKeyMap = {
      en: 'en', fr: 'fr', es: 'es', it: 'it', nl: 'nl', de: 'de',
      ar: 'ar', hi: 'hi', zh: 'zh', tr: 'tr', ru: 'ru',
    };
    const lang = langKeyMap[m[1]];
    if (!lang) throw new Error(`Unknown block ${m[1]}`);
    // find closing '};' line
    let closeIdx = -1;
    for (let j = i + 1; j < lines.length; j++) {
      if (lines[j] === '};') { closeIdx = j; break; }
    }
    if (closeIdx === -1) throw new Error(`No closing brace found for block ${m[1]}`);
    blocks.push({ lang, openIdx: i, closeIdx });
  }
}

if (blocks.length !== LANGS.length) {
  throw new Error(`Expected ${LANGS.length} blocks, found ${blocks.length}`);
}

// Insert from the bottom up so earlier indices stay valid.
blocks.sort((a, b) => b.closeIdx - a.closeIdx);
for (const block of blocks) {
  const newLines = buildLinesForLang(block.lang);
  lines.splice(block.closeIdx, 0, ...newLines);
}

fs.writeFileSync(FILE, lines.join('\n'), 'utf8');
console.log('Inserted', Object.keys(staticEntries).length, 'static +', Object.keys(templateEntries).length, 'template keys into', LANGS.length, 'language blocks.');
