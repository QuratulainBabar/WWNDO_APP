import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

// Remove duplicate acceptedOffers lines that sit next to acceptedOffersSubtitle
// (keep acceptedOffersSubtitle; original acceptedOffers near top of each map stays).
const re =
  /\n  'acceptedOffers': '(?:\\'|[^'])*',(?=\n  'acceptedOffersSubtitle':)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 duplicate acceptedOffers, got', matches.length);
  process.exit(1);
}
s = s.replace(re, '');
fs.writeFileSync(path, s);
console.log('removed', matches.length, 'duplicate acceptedOffers entries');
