import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['byAir', 'By Air', 'Par avion', 'Por aire', 'In aereo', 'Per vliegtuig', 'Mit dem Flugzeug', 'جوًا', 'हवाई मार्ग से', '航空', 'Havayoluyla', 'Воздушным транспортом'],
  ['byLand', 'By Land', 'Par voie terrestre', 'Por tierra', 'Via terra', 'Over land', 'Auf dem Landweg', 'برًا', 'स्थल मार्ग से', '陆路', 'Karayoluyla', 'Наземным транспортом'],
  ['nfcTapRecordedWaitingPeer', 'Your tap is recorded — waiting for the other phone…', 'Votre contact est enregistré — en attente de l’autre téléphone…', 'Tu toque está registrado — esperando el otro teléfono…', 'Il tuo tocco è registrato — in attesa dell’altro telefono…', 'Je tik is geregistreerd — wachten op de andere telefoon…', 'Dein Tippen ist erfasst — warte auf das andere Telefon…', 'تم تسجيل لمستك — في انتظار الهاتف الآخر…', 'आपका टैप रिकॉर्ड हो गया — दूसरे फ़ोन की प्रतीक्षा…', '您的轻触已记录 — 正在等待另一部手机…', 'Dokunuşunuz kaydedildi — diğer telefon bekleniyor…', 'Ваше касание записано — ожидаем другой телефон…'],
  ['holdPhonesTogetherNfc', 'Hold phones together to tap NFC…', 'Rapprochez les téléphones pour le NFC…', 'Acerca los teléfonos para tocar NFC…', 'Avvicina i telefoni per il tocco NFC…', 'Houd telefoons bij elkaar voor NFC…', 'Halte die Telefone zusammen für NFC…', 'قرّب الهاتفين للمس NFC…', 'NFC टैप के लिए फ़ोन पास रखें…', '将手机靠近以进行 NFC…', 'NFC için telefonları birbirine yaklaştırın…', 'Поднесите телефоны друг к другу для NFC…'],
  ['nfcSessionFailedSimulated', 'NFC session failed — using simulated tap', 'Échec de la session NFC — utilisation d’un contact simulé', 'Falló la sesión NFC — usando toque simulado', 'Sessione NFC non riuscita — uso tocco simulato', 'NFC-sessie mislukt — gesimuleerde tik gebruiken', 'NFC-Sitzung fehlgeschlagen — simulierter Tap', 'فشل جلسة NFC — استخدام لمس محاكى', 'NFC सत्र विफल — सिम्युलेटेड टैप', 'NFC 会话失败 — 使用模拟轻触', 'NFC oturumu başarısız — simüle dokunuş kullanılıyor', 'Сбой сессии NFC — используется имитация'],
  ['usingSimulatedTap', 'Using simulated tap', 'Utilisation d’un contact simulé', 'Usando toque simulado', 'Uso tocco simulato', 'Gesimuleerde tik gebruiken', 'Simulierter Tap wird verwendet', 'استخدام لمس محاكى', 'सिम्युलेटेड टैप उपयोग', '使用模拟轻触', 'Simüle dokunuş kullanılıyor', 'Используется имитация касания'],
  ['senderTravelerPair', 'Sender ↔ Traveler', 'Expéditeur ↔ Voyageur', 'Remitente ↔ Viajero', 'Mittente ↔ Viaggiatore', 'Afzender ↔ Reiziger', 'Absender ↔ Reisender', 'مرسل ↔ مسافر', 'सेंडर ↔ यात्री', '寄件人 ↔ 旅客', 'Gönderen ↔ Yolcu', 'Отправитель ↔ Путешественник'],
  ['travelerReceiverPair', 'Traveler ↔ Receiver', 'Voyageur ↔ Destinataire', 'Viajero ↔ Destinatario', 'Viaggiatore ↔ Destinatario', 'Reiziger ↔ Ontvanger', 'Reisender ↔ Empfänger', 'مسافر ↔ مستلم', 'यात्री ↔ प्राप्तकर्ता', '旅客 ↔ 收件人', 'Yolcu ↔ Alıcı', 'Путешественник ↔ Получатель'],
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

if (s.includes("'byAir':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('paymentCompletedLabel': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 paymentCompletedLabel, got', matches.length);
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
