import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['unableToLoadMatchingTravelers', 'Unable to load matching travelers.', 'Impossible de charger les voyageurs correspondants.', 'No se pudieron cargar los viajeros coincidentes.', 'Impossibile caricare i viaggiatori corrispondenti.', 'Kan passende reizigers niet laden.', 'Passende Reisende konnten nicht geladen werden.', 'تعذّر تحميل المسافرين المطابقين.', 'मिलान यात्रियों को लोड नहीं किया जा सका।', '无法加载匹配的旅客。', 'Eşleşen yolcular yüklenemedi.', 'Не удалось загрузить подходящих путешественников.'],
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

if (s.includes("'unableToLoadMatchingTravelers':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('demoModeBrowseTravelers': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 demoModeBrowseTravelers, got', matches.length);
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
