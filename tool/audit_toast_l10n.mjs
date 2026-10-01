import fs from 'fs';
import path from 'path';

const libRoot = 'lib';
const tables =
  fs.readFileSync('lib/l10n/string_tables.dart', 'utf8') +
  fs.readFileSync('lib/l10n/string_tables_extra.dart', 'utf8');
const localize = fs.readFileSync('lib/l10n/app_localizations.dart', 'utf8');

const toastLiterals = new Set();
const toastInterpolated = new Set();

function walk(dir) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) {
      if (name === 'l10n') continue;
      walk(p);
      continue;
    }
    if (!name.endsWith('.dart')) continue;
    const src = fs.readFileSync(p, 'utf8');
    // AppToast.x(context, 'literal') or AppToast.x(context, "literal")
    const re = /AppToast\.(error|success|info)\(\s*[^,]+,\s*(?:context\.(?:tr|l10n)\.[^,]+\([^)]*\)|context\.tr\(|[^'"]*)?(['"])((?:\\.|(?!\2).)*)\2/gs;
    // Simpler: capture string args after AppToast
    const re2 =
      /AppToast\.(?:error|success|info)\(\s*[\s\S]*?(?:context\.tr\(\s*)?(['"])((?:\\.|(?!\1).)*)\1/g;
    let m;
    while ((m = re2.exec(src))) {
      const s = m[2]
        .replace(/\\'/g, "'")
        .replace(/\\"/g, '"')
        .replace(/\\n/g, '\n');
      if (s.includes('$') || s.includes('${')) toastInterpolated.add(s);
      else toastLiterals.add(s);
    }
  }
}

walk(libRoot);

const missing = [];
for (const s of [...toastLiterals].sort()) {
  // skip very short / non-english-ish
  if (s.length < 3) continue;
  const needle = `'${s.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
  const inTables = tables.includes(needle);
  if (!inTables) missing.push(s);
}

console.log('=== Missing exact toast literals ===');
for (const s of missing) console.log('-', s);
console.log('\nCount missing:', missing.length);
console.log('\n=== Interpolated toast templates (need patterns) ===');
for (const s of [...toastInterpolated].sort()) console.log('-', s);
