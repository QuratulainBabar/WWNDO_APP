import fs from 'fs';

const file = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(file, 'utf8');

const rows = [
  [
    'parcelDeliveredBody',
    'Parcel {id} was delivered successfully.',
    'Le colis {id} a été livré avec succès.',
    'El paquete {id} se entregó correctamente.',
    'Il pacco {id} è stato consegnato con successo.',
    'Pakket {id} is succesvol bezorgd.',
    'Paket {id} wurde erfolgreich zugestellt.',
    'تم تسليم الطرد {id} بنجاح.',
    'पार्सल {id} सफलतापूर्वक वितरित किया गया।',
    '包裹 {id} 已成功送达。',
    '{id} paketi başarıyla teslim edildi.',
    'Посылка {id} успешно доставлена.',
  ],
  [
    'parcelInTransitBody',
    'Parcel {id} is now in transit.',
    'Le colis {id} est maintenant en transit.',
    'El paquete {id} está ahora en tránsito.',
    'Il pacco {id} è ora in transito.',
    'Pakket {id} is nu onderweg.',
    'Paket {id} ist jetzt unterwegs.',
    'الطرد {id} قيد النقل الآن.',
    'पार्सल {id} अब ट्रांज़िट में है।',
    '包裹 {id} 正在运输中。',
    '{id} paketi şu an yolda.',
    'Посылка {id} сейчас в пути.',
  ],
  [
    'platformFeeDeductedBody',
    '{amount} platform fee deducted from your card for {id}.',
    'Frais de plateforme de {amount} débités de votre carte pour {id}.',
    'Tarifa de plataforma de {amount} deducida de tu tarjeta por {id}.',
    'Commissione piattaforma di {amount} addebitata sulla carta per {id}.',
    'Platformkosten van {amount} afgeschreven van je kaart voor {id}.',
    'Plattformgebühr von {amount} von deiner Karte für {id} abgebucht.',
    'تم خصم رسوم المنصة {amount} من بطاقتك مقابل {id}.',
    '{id} के लिए आपके कार्ड से {amount} प्लेटफ़ॉर्म शुल्क काटा गया।',
    '已从您的卡扣除 {amount} 平台费（{id}）。',
    '{id} için kartından {amount} platform ücreti tahsil edildi.',
    'С вашей карты списана комиссия платформы {amount} за {id}.',
  ],
  [
    'nfcMatchConfirmedBody',
    'NFC match confirmed for Trip/Delivery {id}. You and the Traveler verified the same delivery — the Traveler is connected',
    'Correspondance NFC confirmée pour le trajet/livraison {id}. Vous et le voyageur avez vérifié la même livraison — le voyageur est connecté',
    'Coincidencia NFC confirmada para viaje/entrega {id}. Tú y el viajero verificaron la misma entrega — el viajero está conectado',
    'Corrispondenza NFC confermata per viaggio/consegna {id}. Tu e il viaggiatore avete verificato la stessa consegna — il viaggiatore è connesso',
    'NFC-match bevestigd voor reis/levering {id}. Jij en de reiziger hebben dezelfde levering geverifieerd — de reiziger is verbonden',
    'NFC-Übereinstimmung für Reise/Lieferung {id} bestätigt. Du und der Reisende habt dieselbe Lieferung verifiziert — der Reisende ist verbunden',
    'تم تأكيد تطابق NFC للرحلة/التوصيل {id}. أنت والمسافر تحققتم من نفس التسليم — المسافر متصل',
    'ट्रिप/डिलीवरी {id} के लिए NFC मिलान पुष्टि। आप और यात्री ने एक ही डिलीवरी सत्यापित की — यात्री कनेक्टेड है',
    '行程/配送 {id} 的 NFC 匹配已确认。您与旅客已验证同一配送 — 旅客已连接',
    'Yolculuk/Teslimat {id} için NFC eşleşmesi onaylandı. Sen ve yolcu aynı teslimatı doğruladınız — yolcu bağlı',
    'NFC-совпадение подтверждено для поездки/доставки {id}. Вы и путешественник подтвердили одну доставку — путешественник подключён',
  ],
  [
    'addParcelPhoto',
    'Add parcel photo',
    'Ajouter une photo du colis',
    'Añadir foto del paquete',
    'Aggiungi foto del pacco',
    'Pakketfoto toevoegen',
    'Pakettfoto hinzufügen',
    'إضافة صورة للطرد',
    'पार्सल फ़ोटो जोड़ें',
    '添加包裹照片',
    'Paket fotoğrafı ekle',
    'Добавить фото посылки',
  ],
  [
    'uploadParcelPhotosShort',
    'Upload 1–3 photos of your parcel.',
    'Téléchargez 1 à 3 photos de votre colis.',
    'Sube 1–3 fotos de tu paquete.',
    'Carica 1–3 foto del tuo pacco.',
    'Upload 1–3 foto’s van je pakket.',
    'Lade 1–3 Fotos deines Pakets hoch.',
    'حمّل من 1 إلى 3 صور لطردك.',
    'अपने पार्सल की 1–3 फ़ोटो अपलोड करें।',
    '上传 1–3 张包裹照片。',
    'Paketinin 1–3 fotoğrafını yükle.',
    'Загрузите 1–3 фото посылки.',
  ],
];

const langs = ['en', 'fr', 'es', 'it', 'nl', 'de', 'ar', 'hi', 'zh', 'tr', 'ru'];

function esc(v) {
  return String(v).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

for (const row of rows) {
  const key = row[0];
  for (let i = 0; i < langs.length; i++) {
    const lang = langs[i];
    const marker = `const Map<String, String> _${lang}Extra = {`;
    const start = s.indexOf(marker);
    if (start < 0) throw new Error('missing ' + lang);
    const end = s.indexOf('\n};', start);
    const block = s.slice(start, end);
    if (block.includes(`'${key}':`)) continue;
    const line = `  '${key}': '${esc(row[i + 1])}',`;
    s = s.slice(0, end) + '\n' + line + s.slice(end);
  }
}

fs.writeFileSync(file, s);
console.log('appended notification body keys');
