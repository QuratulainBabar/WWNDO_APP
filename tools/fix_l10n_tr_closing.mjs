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

let n = 0;
for (const file of [...walk('lib/features'), ...walk('lib/core')]) {
  let text = fs.readFileSync(file, 'utf8');
  const original = text;
  // context.tr('X',\n  )  → context.tr('X')\n  )
  text = text.replace(
    /context\.tr\(('(?:\\'|[^'])*')\s*,\s*\r?\n(\s*)\)/g,
    'context.tr($1)\n$2)',
  );
  // Also same-line: context.tr('X',) → context.tr('X')
  text = text.replace(/context\.tr\(('(?:\\'|[^'])*')\s*,\s*\)/g, 'context.tr($1)');
  if (text !== original) {
    fs.writeFileSync(file, text);
    n += 1;
    console.log(file);
  }
}
console.log('DONE', n);
