import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['openCircleSenderTraveler', '○ Sender ↔ Traveler', '○ Expéditeur ↔ Voyageur', '○ Remitente ↔ Viajero', '○ Mittente ↔ Viaggiatore', '○ Afzender ↔ Reiziger', '○ Absender ↔ Reisender', '○ مرسل ↔ مسافر', '○ सेंडर ↔ यात्री', '○ 寄件人 ↔ 旅客', '○ Gönderen ↔ Yolcu', '○ Отправитель ↔ Путешественник'],
  ['openCircleTravelerReceiver', '○ Traveler ↔ Receiver', '○ Voyageur ↔ Destinataire', '○ Viajero ↔ Destinatario', '○ Viaggiatore ↔ Destinatario', '○ Reiziger ↔ Ontvanger', '○ Reisender ↔ Empfänger', '○ مسافر ↔ مستلم', '○ यात्री ↔ प्राप्तकर्ता', '○ 旅客 ↔ 收件人', '○ Yolcu ↔ Alıcı', '○ Путешественник ↔ Получатель'],
  ['pending', 'Pending', 'En attente', 'Pendiente', 'In attesa', 'In afwachting', 'Ausstehend', 'قيد الانتظار', 'लंबित', '待处理', 'Beklemede', 'Ожидание'],
  ['updated', 'Updated', 'Mis à jour', 'Actualizado', 'Aggiornato', 'Bijgewerkt', 'Aktualisiert', 'محدّث', 'अपडेटेड', '已更新', 'Güncellendi', 'Обновлено'],
  ['accepted', 'Accepted', 'Accepté', 'Aceptado', 'Accettato', 'Geaccepteerd', 'Akzeptiert', 'مقبول', 'स्वीकृत', '已接受', 'Kabul edildi', 'Принято'],
  ['rejected', 'Rejected', 'Refusé', 'Rechazado', 'Rifiutato', 'Afgewezen', 'Abgelehnt', 'مرفوض', 'अस्वीकृत', '已拒绝', 'Reddedildi', 'Отклонено'],
];

function esc(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function block(langIndex) {
  return rows
    .map((r) => `  '${r[0]}': '${esc(r[langIndex + 1])}',`)
    .join('\n');
}

const re = /('disputeOpen': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 disputeOpen, got', matches.length);
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
