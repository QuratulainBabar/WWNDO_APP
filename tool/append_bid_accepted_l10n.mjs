import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['acceptedBidDetails', 'Accepted Bid Details', 'Détails de l’offre acceptée', 'Detalles de la oferta aceptada', 'Dettagli dell’offerta accettata', 'Details geaccepteerd bod', 'Details zum angenommenen Gebot', 'تفاصيل العرض المقبول', 'स्वीकृत बोली विवरण', '已接受出价详情', 'Kabul edilen teklif ayrıntıları', 'Детали принятой ставки'],
  ['escrowFundedSelectionLocked', 'Escrow funded · Selection locked', 'Séquestre financé · Sélection verrouillée', 'Depósito financiado · Selección bloqueada', 'Deposito finanziato · Selezione bloccata', 'Escrow gefinancierd · Selectie vergrendeld', 'Treuhand finanziert · Auswahl gesperrt', 'تم تمويل الضمان · تم قفل الاختيار', 'एस्क्रो फंडेड · चयन लॉक', '托管已注资 · 选择已锁定', 'Emanet fonlandı · Seçim kilitlendi', 'Эскроу пополнен · Выбор зафиксирован'],
  ['bidDetailsHeading', 'Bid details', 'Détails de l’offre', 'Detalles de la oferta', 'Dettagli dell’offerta', 'Boddetails', 'Gebotsdetails', 'تفاصيل العرض', 'बोली विवरण', '出价详情', 'Teklif ayrıntıları', 'Детали ставки'],
  ['waitingTravelerCounterOfferToast', 'Waiting for {name} to send a counter offer. You’ll get a notification when it’s ready to pay.', 'En attente que {name} envoie une contre-offre. Vous recevrez une notification lorsqu’elle sera prête à être payée.', 'Esperando a que {name} envíe una contraoferta. Recibirás una notificación cuando esté lista para pagar.', 'In attesa che {name} invii una controfferta. Riceverai una notifica quando sarà pronta per il pagamento.', 'Wachten tot {name} een tegenbod stuurt. Je krijgt een melding wanneer je kunt betalen.', 'Warte darauf, dass {name} ein Gegenangebot sendet. Du erhältst eine Benachrichtigung, wenn du zahlen kannst.', 'في انتظار أن يرسل {name} عرضًا مضادًا. ستتلقى إشعارًا عندما يصبح جاهزًا للدفع.', '{name} के प्रति-प्रस्ताव भेजने की प्रतीक्षा। भुगतान के लिए तैयार होने पर सूचना मिलेगी।', '正在等待 {name} 发送还价。准备好付款时您会收到通知。', '{name} karşı teklif gönderene kadar bekleniyor. Ödemeye hazır olduğunda bildirim alırsınız.', 'Ожидание встречного предложения от {name}. Вы получите уведомление, когда можно будет оплатить.'],
];

function esc(str) {
  return str
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$');
}

function block(langIndex) {
  return rows
    .map((r) => `  '${r[0]}': '${esc(r[langIndex + 1])}',`)
    .join('\n');
}

if (s.includes("'acceptedBidDetails':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('byAir': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 byAir, got', matches.length);
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = `${m}\n${block(i)}`;
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted', rows.length, 'keys x', i);
