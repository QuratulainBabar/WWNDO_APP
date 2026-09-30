import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

// Remove duplicate myPostedDeliveries inserted after receiverHasNotAccepted.
const re =
  /('receiverHasNotAccepted': '(?:\\'|[^'])*',)\n  'myPostedDeliveries': '(?:\\'|[^'])*',/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 duplicates, got', matches.length);
  process.exit(1);
}
s = s.replace(re, '$1');
fs.writeFileSync(path, s);
console.log('removed', matches.length, 'duplicate myPostedDeliveries');
