const fs = require('fs');
const path = require('path');
const dir = path.join(__dirname, '..', 'lib', 'l10n');
const files = ['string_tables.dart', 'string_tables_extra.dart'];
const keys = new Set();
for (const f of files) {
  const content = fs.readFileSync(path.join(dir, f), 'utf8');
  const re = /'([a-zA-Z0-9_]+)':\s*'/g;
  let m;
  while ((m = re.exec(content))) keys.add(m[1]);
}
const sorted = [...keys].sort();
fs.writeFileSync(path.join(__dirname, '_existing_keys.json'), JSON.stringify(sorted, null, 0));
console.log('total keys:', sorted.length);
