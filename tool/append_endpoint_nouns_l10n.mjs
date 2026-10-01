import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['airportEndpoint', 'airport', 'aéroport', 'aeropuerto', 'aeroporto', 'luchthaven', 'Flughafen', 'مطار', 'हवाई अड्डा', '机场', 'havaalanı', 'аэропорт'],
  ['cityEndpoint', 'city', 'ville', 'ciudad', 'città', 'stad', 'Stadt', 'مدينة', 'शहर', '城市', 'şehir', 'город'],
  ['locationEndpoint', 'location', 'lieu', 'ubicación', 'luogo', 'locatie', 'Ort', 'موقع', 'स्थान', '地点', 'konum', 'место'],
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

if (s.includes("'airportEndpoint':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('selectBothFromToEndpoints': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 selectBothFromToEndpoints, got', matches.length);
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
