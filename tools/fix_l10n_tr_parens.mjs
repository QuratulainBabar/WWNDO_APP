import fs from 'fs';
import path from 'path';

/** Named args that belong to outer widgets, not context.tr(). */
const OUTER_NAMED = [
  'style',
  'textAlign',
  'overflow',
  'maxLines',
  'softWrap',
  'fallbackRoute',
  'onPressed',
  'onTap',
  'subtitle',
  'icon',
  'trailing',
  'leading',
  'enabled',
  'selected',
  'dense',
  'visualDensity',
  'padding',
  'margin',
  'width',
  'height',
  'color',
  'backgroundColor',
  'badge',
  'variant',
  'child',
  'children',
  'key',
];

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

  for (const arg of OUTER_NAMED) {
    // context.tr('...', style:  → context.tr('...'), style:
    const re = new RegExp(
      String.raw`context\.tr\(('(?:\\'|[^'])*'|"(?:\\"|[^"])*")\s*,\s*(${arg}\s*:)`,
      'g',
    );
    text = text.replace(re, 'context.tr($1), $2');
  }

  if (text !== original) {
    fs.writeFileSync(file, text);
    fixed += 1;
    console.log('fixed', file);
  }
}

console.log('DONE fixed_files=', fixed);
