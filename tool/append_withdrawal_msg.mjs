import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const translations = [
  ["Go to home", "{amount} is being transferred via Stripe Connect to your linked bank account. Arrives in 2–5 business days."],
  ["Aller à l\\'accueil", "{amount} est en cours de transfert via Stripe Connect vers votre compte bancaire lié. Arrivée sous 2 à 5 jours ouvrés."],
  ["Ir al inicio", "{amount} se está transfiriendo vía Stripe Connect a tu cuenta bancaria vinculada. Llega en 2–5 días hábiles."],
  ["Vai alla home", "{amount} è in trasferimento tramite Stripe Connect sul tuo conto bancario collegato. Arriva in 2–5 giorni lavorativi."],
  ["Naar home", "{amount} wordt via Stripe Connect overgeboekt naar je gekoppelde bankrekening. Komt aan in 2–5 werkdagen."],
  ["Zur Startseite", "{amount} wird über Stripe Connect auf dein verknüpftes Bankkonto überwiesen. Ankunft in 2–5 Werktagen."],
  ["الانتقال إلى الرئيسية", "يتم تحويل {amount} عبر Stripe Connect إلى حسابك البنكي المرتبط. يصل خلال من 2 إلى 5 أيام عمل."],
  ["होम पर जाएं", "{amount} आपके लिंक किए गए बैंक खाते में Stripe Connect के माध्यम से स्थानांतरित किया जा रहा है। 2–5 कार्य दिवसों में पहुँचेगा।"],
  ["前往首页", "{amount} 正在通过 Stripe Connect 转入您关联的银行账户。预计 2–5 个工作日到账。"],
  ["Ana sayfaya git", "{amount}, bağlı banka hesabınıza Stripe Connect ile aktarılıyor. 2–5 iş günü içinde ulaşır."],
  ["На главную", "{amount} переводится через Stripe Connect на ваш привязанный банковский счёт. Поступит через 2–5 рабочих дней."],
];

let count = 0;
for (const [goHomeVal, msg] of translations) {
  const needle = `'goToHome': '${goHomeVal}',`;
  const insert = `${needle}\n  'withdrawalTransferredMessage': '${msg}',`;
  const idx = s.indexOf(needle);
  if (idx === -1) {
    console.log('MISSING:', goHomeVal);
    continue;
  }
  const after = s.slice(idx, idx + 220);
  if (after.includes('withdrawalTransferredMessage')) {
    console.log('already:', goHomeVal);
    continue;
  }
  s = s.replace(needle, insert);
  count++;
}

fs.writeFileSync(path, s);
console.log('inserted', count);
console.log('total', (s.match(/withdrawalTransferredMessage/g) || []).length);
