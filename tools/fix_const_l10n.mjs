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

function findMatching(text, openIdx, openCh, closeCh) {
  let depth = 0;
  let inStr = null;
  let escape = false;
  for (let i = openIdx; i < text.length; i++) {
    const ch = text[i];
    if (inStr) {
      if (escape) {
        escape = false;
        continue;
      }
      if (ch === '\\') {
        escape = true;
        continue;
      }
      if (ch === inStr) inStr = null;
      continue;
    }
    if (ch === "'" || ch === '"') {
      inStr = ch;
      continue;
    }
    if (ch === openCh) depth += 1;
    else if (ch === closeCh) {
      depth -= 1;
      if (depth === 0) return i;
    }
  }
  return -1;
}

function stripConstBeforeTr(text) {
  let removals = 0;

  // Constructors / widgets: const Foo(... context.tr ...)
  for (let guard = 0; guard < 8000; guard++) {
    const re = /\bconst\s+(?=[A-Za-z_])/g;
    let removed = false;
    let m;
    while ((m = re.exec(text)) !== null) {
      const constStart = m.index;
      const afterConst = constStart + m[0].length;
      let i = afterConst;
      while (i < text.length && /[A-Za-z0-9_.<>, \n\r\t]/.test(text[i])) i += 1;
      if (text[i] !== '(') continue;
      const close = findMatching(text, i, '(', ')');
      if (close < 0) continue;
      const expr = text.slice(afterConst, close + 1);
      if (!expr.includes('context.tr(')) continue;
      text = text.slice(0, constStart) + text.slice(afterConst);
      removals += 1;
      removed = true;
      break;
    }
    if (!removed) break;
  }

  // List literals: const [ ... context.tr ... ]
  for (let guard = 0; guard < 4000; guard++) {
    const re = /\bconst\s*\[/g;
    let removed = false;
    let m;
    while ((m = re.exec(text)) !== null) {
      const constStart = m.index;
      const open = text.indexOf('[', constStart);
      const close = findMatching(text, open, '[', ']');
      if (close < 0) continue;
      const body = text.slice(open, close + 1);
      if (!body.includes('context.tr(')) continue;
      text = text.slice(0, constStart) + text.slice(constStart + 5); // drop "const"
      removals += 1;
      removed = true;
      break;
    }
    if (!removed) break;
  }

  return { text, removals };
}

const files = [
  ...walk('lib/features'),
  ...walk('lib/core/widgets'),
  ...walk('lib/core/auth'),
];

let changed = 0;
let totalRemovals = 0;

for (const file of files) {
  const original = fs.readFileSync(file, 'utf8');
  if (!original.includes('context.tr(')) continue;
  const { text, removals } = stripConstBeforeTr(original);
  if (text !== original) {
    fs.writeFileSync(file, text);
    changed += 1;
    totalRemovals += removals;
    console.log(`fixed ${path.relative(process.cwd(), file)} removals=${removals}`);
  }
}

console.log(`DONE files=${changed} removals=${totalRemovals}`);
