import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

/** key + en,fr,es,it,nl,de,ar,hi,zh,tr,ru */
const rows = [
  ['waitingForTraveler', 'Waiting for traveler', 'En attente du voyageur', 'Esperando al viajero', 'In attesa del viaggiatore', 'Wachten op reiziger', 'Warten auf Reisenden', 'بانتظار المسافر', 'यात्री की प्रतीक्षा', '等待旅客', 'Yolcu bekleniyor', 'Ожидание путешественника'],
  ['viewCompleted', 'View completed', 'Voir les terminés', 'Ver completados', 'Vedi completati', 'Bekijk voltooid', 'Abgeschlossene ansehen', 'عرض المكتملة', 'पूर्ण देखें', '查看已完成', 'Tamamlananları gör', 'Смотреть завершённые'],
  ['nfcBulletTravelerHandingOverToYou', 'The Traveler is handing over the parcel to you (the correct Receiver)', 'Le voyageur vous remet le colis (au bon destinataire)', 'El viajero te está entregando el paquete (al destinatario correcto)', 'Il viaggiatore ti sta consegnando il pacco (al destinatario corretto)', 'De reiziger overhandigt het pakket aan jou (de juiste ontvanger)', 'Der Reisende übergibt dir das Paket (dem richtigen Empfänger)', 'المسافر يسلّمك الطرد (المستلم الصحيح)', 'यात्री आपको (सही प्राप्तकर्ता को) पार्सल सौंप रहा है', '旅客正在将包裹交给您（正确的收件人）', 'Yolcu paketi size (doğru alıcıya) teslim ediyor', 'Путешественник передаёт посылку вам (правильному получателю)'],
  ['nfcBulletEscrowReleasedToTraveler', 'Escrow has been released to the traveler', 'Le séquestre a été libéré au voyageur', 'El depósito se ha liberado al viajero', 'Il deposito è stato rilasciato al viaggiatore', 'Escrow is vrijgegeven aan de reiziger', 'Die Treuhand wurde an den Reisenden freigegeben', 'تم تحرير الضمان للمسافر', 'एस्क्रो यात्री को जारी कर दिया गया है', '托管资金已释放给旅客', 'Emanet yolcuya serbest bırakıldı', 'Эскроу переведён путешественнику'],
  ['youCanLeaveAReview', 'You can leave a review', 'Vous pouvez laisser un avis', 'Puedes dejar una reseña', 'Puoi lasciare una recensione', 'Je kunt een beoordeling achterlaten', 'Du kannst eine Bewertung hinterlassen', 'يمكنك ترك تقييم', 'आप रिव्यू छोड़ सकते हैं', '您可以留下评价', 'Değerlendirme bırakabilirsiniz', 'Вы можете оставить отзыв'],
  ['nfcWaitingForTravelerBody', 'Your NFC tap for {id} is recorded. Ask the traveler to complete their NFC Checkpoint Traveler & Receiver tap to confirm delivery and release escrow.', 'Votre contact NFC pour {id} est enregistré. Demandez au voyageur de terminer son contact au point NFC Voyageur & Destinataire pour confirmer la livraison et libérer le séquestre.', 'Se registró tu toque NFC para {id}. Pide al viajero que complete su toque en el punto NFC Viajero y Destinatario para confirmar la entrega y liberar el depósito.', 'Il tuo tocco NFC per {id} è stato registrato. Chiedi al viaggiatore di completare il proprio tocco al Checkpoint NFC Viaggiatore e Destinatario per confermare la consegna e rilasciare il deposito.', 'Je NFC-tik voor {id} is geregistreerd. Vraag de reiziger om zijn tik bij NFC-controlepunt Reiziger & Ontvanger te voltooien om de levering te bevestigen en de escrow vrij te geven.', 'Dein NFC-Tipp für {id} wurde erfasst. Bitte den Reisenden, seinen Tipp am NFC-Kontrollpunkt Reisender & Empfänger abzuschließen, um die Lieferung zu bestätigen und die Treuhand freizugeben.', 'تم تسجيل لمسة NFC الخاصة بك لـ {id}. اطلب من المسافر إكمال لمسة نقطة NFC المسافر والمستلم لتأكيد التسليم وتحرير الضمان.', '{id} के लिए आपका NFC टैप दर्ज हो गया है। डिलीवरी की पुष्टि और एस्क्रो जारी करने के लिए यात्री से NFC चेकपॉइंट यात्री और प्राप्तकर्ता टैप पूरा करने को कहें।', '您对 {id} 的 NFC 轻触已记录。请让旅客完成 NFC 检查点：旅客与收件人 的轻触，以确认送达并释放托管资金。', '{id} için NFC dokunuşunuz kaydedildi. Teslimatı onaylamak ve emaneti serbest bırakmak için yolcudan NFC Kontrol Noktası Yolcu ve Alıcı dokunuşunu tamamlamasını isteyin.', 'Ваше касание NFC для {id} зафиксировано. Попросите путешественника завершить касание на NFC-контроле Путешественник и Получатель, чтобы подтвердить доставку и освободить эскроу.'],
  ['reviewUnavailable', 'Review unavailable.', 'Avis indisponible.', 'Reseña no disponible.', 'Recensione non disponibile.', 'Beoordeling niet beschikbaar.', 'Bewertung nicht verfügbar.', 'التقييم غير متاح.', 'रिव्यू उपलब्ध नहीं।', '评价不可用。', 'Değerlendirme kullanılamıyor.', 'Отзыв недоступен.'],
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

if (s.includes("'waitingForTraveler':") && s.includes("'nfcWaitingForTravelerBody':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('backToSenderRequests': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 backToSenderRequests, got', matches.length);
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
