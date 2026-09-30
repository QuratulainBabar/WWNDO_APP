import fs from 'fs';

const p = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(p, 'utf8');
let n = 0;
// Escape any $ that is not already escaped with \
s = s.replace(/(?<!\\)\$/g, () => {
  n++;
  return '\\$';
});
fs.writeFileSync(p, s);
console.log('Escaped', n, 'dollar signs');
