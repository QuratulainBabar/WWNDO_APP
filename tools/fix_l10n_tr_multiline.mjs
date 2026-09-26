import fs from 'fs';
import path from 'path';

function walk(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) walk(p, out);
    else if (name.endsWith('.dart')) out.push(p);
  }
  return out;
}

const files = [...walk('lib/features'), ...walk('lib/core')];
let fixed = 0;

for (const file of files) {
  let text = fs.readFileSync(file, 'utf8');
  const original = text;
  // context.tr('...',\n  nextNamed:  → context.tr('...'),\n  nextNamed:
  text = text.replace(
    /context\.tr\(('(?:\\'|[^'])*')\s*,\s*\r?\n(\s*)([a-zA-Z_][\w]*)\s*:/g,
    'context.tr($1),\n$2$3:',
  );
  if (text !== original) {
    fs.writeFileSync(file, text);
    fixed += 1;
    console.log('fixed', file);
  }
}
console.log('DONE', fixed);
