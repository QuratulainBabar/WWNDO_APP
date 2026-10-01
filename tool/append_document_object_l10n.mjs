import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['documentSingular', 'Document', 'Document', 'Documento', 'Documento', 'Document', 'Dokument', 'مستند', 'दस्तावेज़', '文件', 'Belge', 'Документ'],
  ['objectSingular', 'Object', 'Objet', 'Objeto', 'Oggetto', 'Object', 'Objekt', 'شيء', 'वस्तु', '物品', 'Nesne', 'Объект'],
];

function esc(str) {
  return str
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$');
}

function block(langIndex) {
  return rows
    .map((r) => `  '${r[0]}': '${esc(r[langIndex + 1])}',`)
    .join('\n');
}

if (s.includes("'documentSingular':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('photoIndexLabel': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 photoIndexLabel, got', matches.length);
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = `${m}\n${block(i)}`;
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted', rows.length, 'keys x', i);
