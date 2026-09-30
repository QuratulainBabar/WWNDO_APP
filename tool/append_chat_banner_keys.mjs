import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');
if (s.includes("'chatOpenCoordinate':")) {
  console.log('already');
  process.exit(0);
}

const rows = [
  ['Chat is open — coordinate meetup details with your traveler.', 'Chat unlocks after you accept a traveler and payment is complete.', 'Sender ↔ Traveler chat', 'All messages end-to-end secured · {id}'],
  ['La discussion est ouverte — coordonnez le rendez-vous avec votre voyageur.', 'La discussion se débloque après acceptation d\'un voyageur et paiement.', 'Discussion Expéditeur ↔ Voyageur', 'Tous les messages sont sécurisés de bout en bout · {id}'],
  ['El chat está abierto: coordina el punto de encuentro con tu viajero.', 'El chat se desbloquea tras aceptar un viajero y completar el pago.', 'Chat Remitente ↔ Viajero', 'Todos los mensajes están cifrados de extremo a extremo · {id}'],
  ['La chat è aperta — coordina i dettagli dell\'incontro con il tuo viaggiatore.', 'La chat si sblocca dopo aver accettato un viaggiatore e completato il pagamento.', 'Chat Mittente ↔ Viaggiatore', 'Tutti i messaggi sono protetti end-to-end · {id}'],
  ['Chat is open — stem de ontmoeting af met je reiziger.', 'Chat wordt ontgrendeld nadat je een reiziger accepteert en de betaling is voltooid.', 'Afzender ↔ Reiziger-chat', 'Alle berichten zijn end-to-end beveiligd · {id}'],
  ['Chat ist offen — stimme Treffpunktdetails mit deinem Reisenden ab.', 'Chat wird freigeschaltet, nachdem du einen Reisenden akzeptierst und die Zahlung abgeschlossen ist.', 'Absender ↔ Reisender-Chat', 'Alle Nachrichten sind Ende-zu-Ende gesichert · {id}'],
  ['المحادثة مفتوحة — نسّق تفاصيل اللقاء مع المسافر.', 'تُفتح المحادثة بعد قبول مسافر وإتمام الدفع.', 'محادثة المرسل ↔ المسافر', 'جميع الرسائل مؤمَّنة من طرف إلى طرف · {id}'],
  ['चैट खुली है — अपने यात्री के साथ मिलने का स्थान तय करें।', 'यात्री स्वीकार करने और भुगतान पूरा होने के बाद चैट अनलॉक होती है।', 'प्रेषक ↔ यात्री चैट', 'सभी संदेश एंड-टू-एंड सुरक्षित हैं · {id}'],
  ['聊天已开启 — 请与旅行者协调会面细节。', '接受旅行者并完成付款后即可解锁聊天。', '寄件人 ↔ 旅行者聊天', '所有消息均端到端加密 · {id}'],
  ['Sohbet açık — seyahat edenle buluşma detaylarını ayarlayın.', 'Bir seyahat edeni kabul edip ödemeyi tamamladıktan sonra sohbet açılır.', 'Gönderen ↔ Seyahat eden sohbeti', 'Tüm mesajlar uçtan uca güvence altında · {id}'],
  ['Чат открыт — согласуйте детали встречи с путешественником.', 'Чат откроется после принятия путешественника и завершения оплаты.', 'Чат отправителя ↔ путешественника', 'Все сообщения защищены сквозным шифрованием · {id}'],
];

function esc(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

const re = /('takePhoto': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('got', matches.length);
  process.exit(1);
}
let i = 0;
s = s.replace(re, (m) => {
  const [a, b, c, d] = rows[i++];
  return `${m}
  'chatOpenCoordinate': '${esc(a)}',
  'chatUnlocksAfterPayment': '${esc(b)}',
  'senderTravelerChat': '${esc(c)}',
  'messagesEndToEndSecured': '${esc(d)}',`;
});
fs.writeFileSync(path, s);
console.log('ok', i);
