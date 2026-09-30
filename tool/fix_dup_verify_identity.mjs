import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const re =
  /\n  'verifyIdentity': '(?:\\'|[^'])*',(?=\n  'identityVerifiedExclaim':)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11, got', matches.length);
  process.exit(1);
}
s = s.replace(re, '');
fs.writeFileSync(path, s);
console.log('removed', matches.length, 'duplicate verifyIdentity');
