import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const translations = [
  {
    completed: 'Completed',
    weightColon: 'Weight: {weight}',
    receiverHasNotAccepted:
      'Receiver has not accepted the parcel request yet.',
    myPostedDeliveries: 'My Posted Deliveries',
  },
  {
    completed: 'Terminé',
    weightColon: 'Poids : {weight}',
    receiverHasNotAccepted:
      "Le destinataire n'a pas encore accepté la demande de colis.",
    myPostedDeliveries: 'Mes livraisons publiées',
  },
  {
    completed: 'Completado',
    weightColon: 'Peso: {weight}',
    receiverHasNotAccepted:
      'El destinatario aún no ha aceptado la solicitud del paquete.',
    myPostedDeliveries: 'Mis entregas publicadas',
  },
  {
    completed: 'Completato',
    weightColon: 'Peso: {weight}',
    receiverHasNotAccepted:
      'Il destinatario non ha ancora accettato la richiesta del pacco.',
    myPostedDeliveries: 'Le mie consegne pubblicate',
  },
  {
    completed: 'Voltooid',
    weightColon: 'Gewicht: {weight}',
    receiverHasNotAccepted:
      'De ontvanger heeft het pakketverzoek nog niet geaccepteerd.',
    myPostedDeliveries: 'Mijn geplaatste leveringen',
  },
  {
    completed: 'Abgeschlossen',
    weightColon: 'Gewicht: {weight}',
    receiverHasNotAccepted:
      'Der Empfänger hat die Paketanfrage noch nicht akzeptiert.',
    myPostedDeliveries: 'Meine veröffentlichten Lieferungen',
  },
  {
    completed: 'مكتمل',
    weightColon: 'الوزن: {weight}',
    receiverHasNotAccepted: 'لم يقبل المستلم طلب الطرد بعد.',
    myPostedDeliveries: 'توصيلاتي المنشورة',
  },
  {
    completed: 'पूर्ण',
    weightColon: 'वज़न: {weight}',
    receiverHasNotAccepted:
      'प्राप्तकर्ता ने अभी तक पार्सल अनुरोध स्वीकार नहीं किया है।',
    myPostedDeliveries: 'मेरी पोस्ट की गई डिलीवरी',
  },
  {
    completed: '已完成',
    weightColon: '重量：{weight}',
    receiverHasNotAccepted: '收件人尚未接受包裹请求。',
    myPostedDeliveries: '我发布的配送',
  },
  {
    completed: 'Tamamlandı',
    weightColon: 'Ağırlık: {weight}',
    receiverHasNotAccepted: 'Alıcı paket talebini henüz kabul etmedi.',
    myPostedDeliveries: 'Yayınladığım teslimatlar',
  },
  {
    completed: 'Завершено',
    weightColon: 'Вес: {weight}',
    receiverHasNotAccepted:
      'Получатель ещё не принял запрос на посылку.',
    myPostedDeliveries: 'Мои опубликованные доставки',
  },
];

function esc(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function block(t) {
  return Object.entries(t)
    .map(([k, v]) => `  '${k}': '${esc(v)}',`)
    .join('\n');
}

const re =
  /('messagesEndToEndSecured': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 messagesEndToEndSecured, got', matches.length);
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = `${m}\n${block(translations[i])}`;
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted shipments keys for', i, 'languages');
