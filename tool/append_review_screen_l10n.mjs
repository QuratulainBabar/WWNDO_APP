import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

/** key + en,fr,es,it,nl,de,ar,hi,zh,tr,ru */
const rows = [
  ['deliveryConfirmedExclaim', 'Delivery confirmed!', 'Livraison confirmée !', '¡Entrega confirmada!', 'Consegna confermata!', 'Levering bevestigd!', 'Lieferung bestätigt!', 'تم تأكيد التسليم!', 'डिलीवरी पुष्टि!', '配送已确认！', 'Teslimat onaylandı!', 'Доставка подтверждена!'],
  ['payoutReleasedToWalletFor', '{amount} has been released to {name}\'s wallet for {id}.', '{amount} a été versé sur le portefeuille de {name} pour {id}.', '{amount} se ha liberado a la billetera de {name} para {id}.', '{amount} è stato rilasciato nel portafoglio di {name} per {id}.', '{amount} is vrijgegeven naar de portemonnee van {name} voor {id}.', '{amount} wurde auf das Wallet von {name} für {id} freigegeben.', 'تم تحرير {amount} إلى محفظة {name} مقابل {id}.', '{amount} को {name} के वॉलेट में {id} के लिए जारी किया गया।', '{amount} 已释放至 {name} 的钱包（{id}）。', '{amount}, {id} için {name} adlı kişinin cüzdanına serbest bırakıldı.', '{amount} переведено на кошелёк {name} за {id}.'],
  ['deliveryCompleteExperienceWith', 'Delivery {id} complete. How was your experience with {name}?', 'Livraison {id} terminée. Comment s’est passée votre expérience avec {name} ?', 'Entrega {id} completada. ¿Cómo fue tu experiencia con {name}?', 'Consegna {id} completata. Com’è stata la tua esperienza con {name}?', 'Levering {id} voltooid. Hoe was je ervaring met {name}?', 'Lieferung {id} abgeschlossen. Wie war deine Erfahrung mit {name}?', 'اكتملت التوصيلة {id}. كيف كانت تجربتك مع {name}؟', 'डिलीवरी {id} पूर्ण। {name} के साथ आपका अनुभव कैसा रहा?', '配送 {id} 已完成。您与 {name} 的体验如何？', '{id} teslimatı tamamlandı. {name} ile deneyiminiz nasıldı?', 'Доставка {id} завершена. Как прошёл опыт с {name}?'],
  ['deliveryCompleteHandoffWith', 'Delivery {id} complete. How was the handoff with {name}?', 'Livraison {id} terminée. Comment s’est passé le transfert avec {name} ?', 'Entrega {id} completada. ¿Cómo fue la entrega con {name}?', 'Consegna {id} completata. Com’è stato il passaggio con {name}?', 'Levering {id} voltooid. Hoe was de overdracht met {name}?', 'Lieferung {id} abgeschlossen. Wie war die Übergabe mit {name}?', 'اكتملت التوصيلة {id}. كيف كان التسليم مع {name}؟', 'डिलीवरी {id} पूर्ण। {name} के साथ हैंडऑफ़ कैसा रहा?', '配送 {id} 已完成。与 {name} 的交接如何？', '{id} teslimatı tamamlandı. {name} ile teslimat nasıldı?', 'Доставка {id} завершена. Как прошла передача с {name}?'],
  ['deliveryConfirmedExperienceWith', 'Delivery {id} confirmed. How was your experience with {name}?', 'Livraison {id} confirmée. Comment s’est passée votre expérience avec {name} ?', 'Entrega {id} confirmada. ¿Cómo fue tu experiencia con {name}?', 'Consegna {id} confermata. Com’è stata la tua esperienza con {name}?', 'Levering {id} bevestigd. Hoe was je ervaring met {name}?', 'Lieferung {id} bestätigt. Wie war deine Erfahrung mit {name}?', 'تم تأكيد التوصيلة {id}. كيف كانت تجربتك مع {name}؟', 'डिलीवरी {id} पुष्टि। {name} के साथ आपका अनुभव कैसा रहा?', '配送 {id} 已确认。您与 {name} 的体验如何？', '{id} teslimatı onaylandı. {name} ile deneyiminiz nasıldı?', 'Доставка {id} подтверждена. Как прошёл опыт с {name}?'],
  ['howWasExperienceWith', 'How was your experience with {name}?', 'Comment s’est passée votre expérience avec {name} ?', '¿Cómo fue tu experiencia con {name}?', 'Com’è stata la tua esperienza con {name}?', 'Hoe was je ervaring met {name}?', 'Wie war deine Erfahrung mit {name}?', 'كيف كانت تجربتك مع {name}؟', '{name} के साथ आपका अनुभव कैसा रहा?', '您与 {name} 的体验如何？', '{name} ile deneyiminiz nasıldı?', 'Как прошёл опыт с {name}?'],
  ['shareHowDeliveryWentHint', 'Share how the delivery went…', 'Partagez comment s’est déroulée la livraison…', 'Cuenta cómo fue la entrega…', 'Racconta com’è andata la consegna…', 'Vertel hoe de levering verlief…', 'Teile mit, wie die Lieferung verlief…', 'شاركنا كيف سارت عملية التسليم…', 'बताएँ डिलीवरी कैसी रही…', '分享此次配送情况…', 'Teslimatın nasıl geçtiğini paylaşın…', 'Расскажите, как прошла доставка…'],
  ['submitReview', 'Submit review', 'Envoyer l’avis', 'Enviar reseña', 'Invia recensione', 'Beoordeling verzenden', 'Bewertung absenden', 'إرسال التقييم', 'रिव्यू सबमिट करें', '提交评价', 'Değerlendirmeyi gönder', 'Отправить отзыв'],
  ['submittingEllipsis', 'Submitting…', 'Envoi…', 'Enviando…', 'Invio…', 'Verzenden…', 'Wird gesendet…', 'جارٍ الإرسال…', 'सबमिट हो रहा है…', '提交中…', 'Gönderiliyor…', 'Отправка…'],
  ['skipForNow', 'Skip for now', 'Passer pour l’instant', 'Omitir por ahora', 'Salta per ora', 'Nu overslaan', 'Jetzt überspringen', 'تخطَّ الآن', 'अभी छोड़ें', '暂时跳过', 'Şimdilik atla', 'Пропустить пока'],
  ['reviewSubmittedExclaim', 'Review submitted!', 'Avis envoyé !', '¡Reseña enviada!', 'Recensione inviata!', 'Beoordeling verzonden!', 'Bewertung gesendet!', 'تم إرسال التقييم!', 'रिव्यू सबमिट!', '评价已提交！', 'Değerlendirme gönderildi!', 'Отзыв отправлен!'],
  ['thanksForFeedbackReview', 'Thanks for sharing your feedback on {id}. Your {rating}-star review helps keep WWNGO safe and reliable.', 'Merci d’avoir partagé votre avis sur {id}. Votre avis {rating} étoiles aide à garder WWNGO sûr et fiable.', 'Gracias por compartir tu opinión sobre {id}. Tu reseña de {rating} estrellas ayuda a mantener WWNGO seguro y fiable.', 'Grazie per il feedback su {id}. La tua recensione a {rating} stelle aiuta a mantenere WWNGO sicuro e affidabile.', 'Bedankt voor je feedback over {id}. Je {rating}-sterrenbeoordeling helpt WWNGO veilig en betrouwbaar te houden.', 'Danke für dein Feedback zu {id}. Deine {rating}-Sterne-Bewertung hilft, WWNGO sicher und zuverlässig zu halten.', 'شكرًا لمشاركة ملاحظاتك حول {id}. تقييمك بـ {rating} نجوم يساعد في إبقاء WWNGO آمنًا وموثوقًا.', '{id} पर अपनी प्रतिक्रिया साझा करने के लिए धन्यवाद। आपका {rating}-स्टार रिव्यू WWNGO को सुरक्षित और विश्वसनीय रखने में मदद करता है।', '感谢您对 {id} 的反馈。您的 {rating} 星评价有助于保持 WWNGO 安全可靠。', '{id} hakkındaki geri bildiriminiz için teşekkürler. {rating} yıldızlı değerlendirmeniz WWNGO’yu güvenli ve güvenilir tutmaya yardımcı olur.', 'Спасибо за отзыв о {id}. Ваша оценка в {rating} звезд помогает делать WWNGO безопасным и надёжным.'],
  ['viewMyShipments', 'View my shipments', 'Voir mes envois', 'Ver mis envíos', 'Vedi le mie spedizioni', 'Mijn zendingen bekijken', 'Meine Sendungen ansehen', 'عرض شحناتي', 'मेरी शिपमेंट देखें', '查看我的货运', 'Gönderilerimi gör', 'Мои отправления'],
  ['missingShipmentIdForReview', 'Missing shipment ID. Open review from a completed delivery.', 'ID d’envoi manquant. Ouvrez l’avis depuis une livraison terminée.', 'Falta el ID del envío. Abre la reseña desde una entrega completada.', 'ID spedizione mancante. Apri la recensione da una consegna completata.', 'Zending-ID ontbreekt. Open de beoordeling vanuit een voltooide levering.', 'Sendungs-ID fehlt. Öffne die Bewertung aus einer abgeschlossenen Lieferung.', 'معرّف الشحنة مفقود. افتح التقييم من توصيلة مكتملة.', 'शिपमेंट आईडी गायब है। पूर्ण डिलीवरी से रिव्यू खोलें।', '缺少货运编号。请从已完成的配送打开评价。', 'Gönderi kimliği eksik. Değerlendirmeyi tamamlanmış bir teslimattan açın.', 'Отсутствует ID отправления. Откройте отзыв из завершённой доставки.'],
  ['unableToDetermineReviewee', 'Unable to determine who to review for this delivery. Try again from shipment details.', 'Impossible de déterminer qui évaluer pour cette livraison. Réessayez depuis les détails de l’envoi.', 'No se pudo determinar a quién reseñar en esta entrega. Inténtalo de nuevo desde los detalles del envío.', 'Impossibile determinare chi recensire per questa consegna. Riprova dai dettagli della spedizione.', 'Kan niet bepalen wie te beoordelen voor deze levering. Probeer opnieuw via de zendingdetails.', 'Konnte nicht bestimmen, wen du für diese Lieferung bewerten sollst. Versuche es erneut über die Sendungsdetails.', 'تعذّر تحديد من يجب تقييمه لهذه التوصيلة. حاول مجددًا من تفاصيل الشحنة.', 'इस डिलीवरी के लिए किसे रिव्यू करें निर्धारित नहीं हो सका। शिपमेंट विवरण से पुनः प्रयास करें।', '无法确定要评价此配送中的哪一方。请从货运详情重试。', 'Bu teslimat için kimi değerlendireceğiniz belirlenemedi. Gönderi ayrıntılarından yeniden deneyin.', 'Не удалось определить, кого оценить для этой доставки. Попробуйте снова из деталей отправления.'],
  ['yourTravelerFallback', 'your traveler', 'votre voyageur', 'tu viajero', 'il tuo viaggiatore', 'jouw reiziger', 'dein Reisender', 'مسافرك', 'आपका यात्री', '您的旅客', 'yolcunuz', 'ваш путешественник'],
  ['theSenderFallback', 'the sender', 'l’expéditeur', 'el remitente', 'il mittente', 'de afzender', 'den Absender', 'المرسل', 'प्रेषक', '寄件人', 'gönderici', 'отправителя'],
  ['theReceiverFallback', 'the receiver', 'le destinataire', 'el destinatario', 'il destinatario', 'de ontvanger', 'den Empfänger', 'المستلم', 'प्राप्तकर्ता', '收件人', 'alıcı', 'получателя'],
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

if (s.includes("'deliveryConfirmedExclaim':") && s.includes("'shareHowDeliveryWentHint':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('incomingParcelRequest': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 incomingParcelRequest, got', matches.length);
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
