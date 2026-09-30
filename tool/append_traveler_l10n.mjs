import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['counterOffersSent', 'Counter Offers Sent', 'Contre-offres envoyées', 'Contraofertas enviadas', 'Controfferte inviate', 'Verzonden tegenbiedingen', 'Gesendete Gegenangebote', 'العروض المضادة المرسلة', 'भेजे गए काउंटर ऑफ़र', '已发送的还价', 'Gönderilen karşı teklifler', 'Отправленные встречные предложения'],
  ['counterOffersSentSubtitle', 'These are the counter offers you have sent to senders.', 'Voici les contre-offres que vous avez envoyées aux expéditeurs.', 'Estas son las contraofertas que has enviado a los remitentes.', 'Queste sono le controfferte che hai inviato ai mittenti.', 'Dit zijn de tegenbiedingen die je naar afzenders hebt gestuurd.', 'Das sind die Gegenangebote, die du an Absender gesendet hast.', 'هذه هي العروض المضادة التي أرسلتها إلى المرسلين.', 'ये वे काउंटर ऑफ़र हैं जो आपने सेंडर को भेजे हैं।', '这些是您已发送给寄件人的还价。', 'Göndericilere gönderdiğiniz karşı teklifler bunlardır.', 'Это встречные предложения, которые вы отправили отправителям.'],
  ['noCounterOffersYet', 'No counter offers yet.', 'Aucune contre-offre pour le moment.', 'Aún no hay contraofertas.', 'Nessuna controfferta ancora.', 'Nog geen tegenbiedingen.', 'Noch keine Gegenangebote.', 'لا توجد عروض مضادة بعد.', 'अभी कोई काउंटर ऑफ़र नहीं।', '暂无还价。', 'Henüz karşı teklif yok.', 'Пока нет встречных предложений.'],
  ['acceptedOffers', 'Accepted Offers', 'Offres acceptées', 'Ofertas aceptadas', 'Offerte accettate', 'Geaccepteerde biedingen', 'Angenommene Angebote', 'العروض المقبولة', 'स्वीकृत ऑफ़र', '已接受的报价', 'Kabul edilen teklifler', 'Принятые предложения'],
  ['acceptedOffersSubtitle', "Offers where you accepted the sender's max budget. Once the sender confirms, they move to My Deliveries.", "Offres où vous avez accepté le budget max de l'expéditeur. Une fois confirmées, elles passent dans Mes livraisons.", 'Ofertas en las que aceptaste el presupuesto máximo del remitente. Cuando confirme, pasan a Mis entregas.', 'Offerte in cui hai accettato il budget massimo del mittente. Dopo la conferma, passano a Le mie consegne.', 'Biedingen waarbij je het max. budget van de afzender accepteerde. Na bevestiging gaan ze naar Mijn leveringen.', 'Angebote, bei denen du das Max-Budget des Absenders akzeptiert hast. Nach Bestätigung erscheinen sie unter Meine Lieferungen.', 'العروض التي قبلت فيها الحد الأقصى لميزانية المرسل. بعد تأكيد المرسل تنتقل إلى توصيلاتي.', 'ऑफ़र जहाँ आपने सेंडर का अधिकतम बजट स्वीकार किया। सेंडर पुष्टि के बाद वे मेरी डिलीवरी में जाएँगे।', '您已接受寄件人最高预算的报价。寄件人确认后将移至“我的配送”。', 'Gönderenin maksimum bütçesini kabul ettiğiniz teklifler. Gönderen onaylayınca Teslimatlarım’a geçer.', 'Предложения, где вы приняли макс. бюджет отправителя. После подтверждения они появятся в «Мои доставки».'],
  ['noPendingAcceptedOffers', 'No pending accepted offers.', 'Aucune offre acceptée en attente.', 'No hay ofertas aceptadas pendientes.', 'Nessuna offerta accettata in sospeso.', 'Geen openstaande geaccepteerde biedingen.', 'Keine ausstehenden angenommenen Angebote.', 'لا توجد عروض مقبولة معلّقة.', 'कोई लंबित स्वीकृत ऑफ़र नहीं।', '暂无待处理的已接受报价。', 'Bekleyen kabul edilmiş teklif yok.', 'Нет ожидающих принятых предложений.'],
  ['unableToLoadCounterOffers', 'Unable to load counter offers.', 'Impossible de charger les contre-offres.', 'No se pudieron cargar las contraofertas.', 'Impossibile caricare le controfferte.', 'Kan tegenbiedingen niet laden.', 'Gegenangebote konnten nicht geladen werden.', 'تعذّر تحميل العروض المضادة.', 'काउंटर ऑफ़र लोड नहीं हो सके।', '无法加载还价。', 'Karşı teklifler yüklenemedi.', 'Не удалось загрузить встречные предложения.'],
  ['unableToLoadAcceptedOffers', 'Unable to load accepted offers.', 'Impossible de charger les offres acceptées.', 'No se pudieron cargar las ofertas aceptadas.', 'Impossibile caricare le offerte accettate.', 'Kan geaccepteerde biedingen niet laden.', 'Angenommene Angebote konnten nicht geladen werden.', 'تعذّر تحميل العروض المقبولة.', 'स्वीकृत ऑफ़र लोड नहीं हो सके।', '无法加载已接受的报价。', 'Kabul edilen teklifler yüklenemedi.', 'Не удалось загрузить принятые предложения.'],
  ['noActiveTripsYet', 'No active trips yet.', 'Aucun trajet actif pour le moment.', 'Aún no hay viajes activos.', 'Nessun viaggio attivo.', 'Nog geen actieve reizen.', 'Noch keine aktiven Reisen.', 'لا توجد رحلات نشطة بعد.', 'अभी कोई सक्रिय यात्रा नहीं।', '暂无进行中的行程。', 'Henüz aktif yolculuk yok.', 'Пока нет активных поездок.'],
  ['noCompletedTripsYet', 'No completed trips yet.', 'Aucun trajet terminé pour le moment.', 'Aún no hay viajes completados.', 'Nessun viaggio completato.', 'Nog geen voltooide reizen.', 'Noch keine abgeschlossenen Reisen.', 'لا توجد رحلات مكتملة بعد.', 'अभी कोई पूर्ण यात्रा नहीं।', '暂无已完成行程。', 'Henüz tamamlanan yolculuk yok.', 'Пока нет завершённых поездок.'],
  ['noCancelledTripsYet', 'No cancelled trips yet.', 'Aucun trajet annulé pour le moment.', 'Aún no hay viajes cancelados.', 'Nessun viaggio annullato.', 'Nog geen geannuleerde reizen.', 'Noch keine stornierten Reisen.', 'لا توجد رحلات ملغاة بعد.', 'अभी कोई रद्द यात्रा नहीं।', '暂无已取消行程。', 'Henüz iptal edilen yolculuk yok.', 'Пока нет отменённых поездок.'],
  ['noCompletedDeliveriesYet', 'No completed deliveries yet.', 'Aucune livraison terminée pour le moment.', 'Aún no hay entregas completadas.', 'Nessuna consegna completata.', 'Nog geen voltooide leveringen.', 'Noch keine abgeschlossenen Lieferungen.', 'لا توجد توصيلات مكتملة بعد.', 'अभी कोई पूर्ण डिलीवरी नहीं।', '暂无已完成配送。', 'Henüz tamamlanan teslimat yok.', 'Пока нет завершённых доставок.'],
  ['noCancelledDeliveriesYet', 'No cancelled deliveries yet.', 'Aucune livraison annulée pour le moment.', 'Aún no hay entregas canceladas.', 'Nessuna consegna annullata.', 'Nog geen geannuleerde leveringen.', 'Noch keine stornierten Lieferungen.', 'لا توجد توصيلات ملغاة بعد.', 'अभी कोई रद्द डिलीवरी नहीं।', '暂无已取消配送。', 'Henüz iptal edilen teslimat yok.', 'Пока нет отменённых доставок.'],
  ['routeMap', 'Route map', 'Carte de l’itinéraire', 'Mapa de la ruta', 'Mappa del percorso', 'Routekaart', 'Routenkarte', 'خريطة المسار', 'मार्ग मानचित्र', '路线地图', 'Rota haritası', 'Карта маршрута'],
  ['openMap', 'Open map', 'Ouvrir la carte', 'Abrir mapa', 'Apri mappa', 'Kaart openen', 'Karte öffnen', 'فتح الخريطة', 'मानचित्र खोलें', '打开地图', 'Haritayı aç', 'Открыть карту'],
  ['openInMaps', 'Open in Maps', 'Ouvrir dans Maps', 'Abrir en Maps', 'Apri in Maps', 'Openen in Maps', 'In Maps öffnen', 'فتح في Maps', 'Maps में खोलें', '在地图中打开', 'Maps’te aç', 'Открыть в Maps'],
  ['statusTimeline', 'Status timeline', 'Chronologie du statut', 'Línea de tiempo del estado', 'Cronologia dello stato', 'Statustijdlijn', 'Status-Zeitlinie', 'الجدول الزمني للحالة', 'स्थिति समयरेखा', '状态时间线', 'Durum zaman çizelgesi', 'Шкала статуса'],
  ['parcelType', 'Parcel type', 'Type de colis', 'Tipo de paquete', 'Tipo di pacco', 'Pakkettype', 'Pakettyp', 'نوع الطرد', 'पार्सल प्रकार', '包裹类型', 'Paket türü', 'Тип посылки'],
  ['shipmentEscrow', 'Shipment escrow', 'Séquestre de l’envoi', 'Depósito del envío', 'Deposito della spedizione', 'Zending-escrow', 'Sendungs-Treuhand', 'ضمان الشحنة', 'शिपमेंट एस्क्रो', '货运托管', 'Gönderi emanet hesabı', 'Эскроу отправления'],
  ['releasedToTravelerCp2', 'Released to traveler (Traveler ↔ Receiver)', 'Libéré au voyageur (Voyageur ↔ Destinataire)', 'Liberado al viajero (Viajero ↔ Destinatario)', 'Rilasciato al viaggiatore (Viaggiatore ↔ Destinatario)', 'Vrijgegeven aan reiziger (Reiziger ↔ Ontvanger)', 'An Reisenden freigegeben (Reisender ↔ Empfänger)', 'تم الإفراج للمسافر (مسافر ↔ مستلم)', 'यात्री को जारी (यात्री ↔ प्राप्तकर्ता)', '已发放给旅客（旅客 ↔ 收件人）', 'Yolcuya serbest bırakıldı (Yolcu ↔ Alıcı)', 'Выплачено путешественнику (Путешественник ↔ Получатель)'],
  ['refundedToSender', 'Refunded to sender', 'Remboursé à l’expéditeur', 'Reembolsado al remitente', 'Rimborsato al mittente', 'Terugbetaald aan afzender', 'An Absender erstattet', 'أُعيد إلى المرسل', 'सेंडर को वापस', '已退还给寄件人', 'Gönderene iade edildi', 'Возвращено отправителю'],
  ['escrowFrozenDispute', 'Frozen — dispute under review', 'Gelé — litige en cours d’examen', 'Congelado — disputa en revisión', 'Bloccato — disputa in revisione', 'Bevroren — geschil in behandeling', 'Eingefroren — Streitfall in Prüfung', 'مجمّد — النزاع قيد المراجعة', 'फ़्रीज़ — विवाद समीक्षा में', '已冻结 — 争议审核中', 'Donduruldu — itiraz inceleniyor', 'Заморожено — спор на рассмотрении'],
  ['heldUntilCp2', 'Held until Traveler ↔ Receiver', 'Conservé jusqu’à Voyageur ↔ Destinataire', 'Retenido hasta Viajero ↔ Destinatario', 'Trattenuto fino a Viaggiatore ↔ Destinatario', 'Vastgehouden tot Reiziger ↔ Ontvanger', 'Einbehalten bis Reisender ↔ Empfänger', 'محتجز حتى مسافر ↔ مستلم', 'यात्री ↔ प्राप्तकर्ता तक रोका', '保留至旅客 ↔ 收件人', 'Yolcu ↔ Alıcı’ya kadar tutulur', 'Удерживается до Путешественник ↔ Получатель'],
  ['noActiveEscrow', 'No active escrow', 'Aucun séquestre actif', 'Sin depósito activo', 'Nessun deposito attivo', 'Geen actieve escrow', 'Kein aktives Treuhandkonto', 'لا يوجد ضمان نشط', 'कोई सक्रिय एस्क्रो नहीं', '无有效托管', 'Aktif emanet yok', 'Нет активного эскроу'],
  ['nfcCheckpointTravelerReceiver', 'NFC Checkpoint Traveler & Receiver', 'Point NFC Voyageur & Destinataire', 'Punto NFC Viajero y Destinatario', 'Checkpoint NFC Viaggiatore e Destinatario', 'NFC-controlepunt Reiziger & Ontvanger', 'NFC-Kontrollpunkt Reisender & Empfänger', 'نقطة NFC المسافر والمستلم', 'NFC चेकपॉइंट यात्री और प्राप्तकर्ता', 'NFC 检查点：旅客与收件人', 'NFC Kontrol Noktası Yolcu ve Alıcı', 'NFC-контроль: Путешественник и Получатель'],
  ['nfcCheckpointTravelerSender', 'NFC Checkpoint Traveler & Sender', 'Point NFC Voyageur & Expéditeur', 'Punto NFC Viajero y Remitente', 'Checkpoint NFC Viaggiatore e Mittente', 'NFC-controlepunt Reiziger & Afzender', 'NFC-Kontrollpunkt Reisender & Absender', 'نقطة NFC المسافر والمرسل', 'NFC चेकपॉइंट यात्री और सेंडर', 'NFC 检查点：旅客与寄件人', 'NFC Kontrol Noktası Yolcu ve Gönderen', 'NFC-контроль: Путешественник и Отправитель'],
  ['finalDeliveryConfirmedEscrow', 'Final delivery confirmed with the receiver via NFC. Escrow released to your wallet.', 'Livraison finale confirmée avec le destinataire via NFC. Séquestre libéré vers votre portefeuille.', 'Entrega final confirmada con el destinatario por NFC. Depósito liberado a tu monedero.', 'Consegna finale confermata con il destinatario via NFC. Deposito rilasciato nel tuo portafoglio.', 'Eindlevering bevestigd met de ontvanger via NFC. Escrow vrijgegeven naar je portemonnee.', 'Endgültige Lieferung per NFC mit dem Empfänger bestätigt. Treuhand auf dein Wallet freigegeben.', 'تم تأكيد التسليم النهائي مع المستلم عبر NFC. تم تحرير الضمان إلى محفظتك.', 'प्राप्तकर्ता के साथ NFC से अंतिम डिलीवरी पुष्टि। एस्क्रो आपके वॉलेट में जारी।', '已通过 NFC 与收件人确认最终交付。托管资金已释放至您的钱包。', 'Alıcıyla NFC üzerinden nihai teslimat onaylandı. Emanet cüzdanınıza serbest bırakıldı.', 'Финальная доставка подтверждена с получателем через NFC. Эскроу переведён на ваш кошелёк.'],
  ['nfcTravelerReceiverConfirmed', '✓ NFC Traveler & Receiver confirmed', '✓ NFC Voyageur & Destinataire confirmé', '✓ NFC Viajero y Destinatario confirmado', '✓ NFC Viaggiatore e Destinatario confermato', '✓ NFC Reiziger & Ontvanger bevestigd', '✓ NFC Reisender & Empfänger bestätigt', '✓ تم تأكيد NFC المسافر والمستلم', '✓ NFC यात्री और प्राप्तकर्ता पुष्टि', '✓ 已确认 NFC 旅客与收件人', '✓ NFC Yolcu ve Alıcı onaylandı', '✓ NFC Путешественник и Получатель подтверждены'],
  ['checkSenderTraveler', '✓ Sender ↔ Traveler', '✓ Expéditeur ↔ Voyageur', '✓ Remitente ↔ Viajero', '✓ Mittente ↔ Viaggiatore', '✓ Afzender ↔ Reiziger', '✓ Absender ↔ Reisender', '✓ مرسل ↔ مسافر', '✓ सेंडर ↔ यात्री', '✓ 寄件人 ↔ 旅客', '✓ Gönderen ↔ Yolcu', '✓ Отправитель ↔ Путешественник'],
  ['checkTravelerReceiver', '✓ Traveler ↔ Receiver', '✓ Voyageur ↔ Destinataire', '✓ Viajero ↔ Destinatario', '✓ Viaggiatore ↔ Destinatario', '✓ Reiziger ↔ Ontvanger', '✓ Reisender ↔ Empfänger', '✓ مسافر ↔ مستلم', '✓ यात्री ↔ प्राप्तकर्ता', '✓ 旅客 ↔ 收件人', '✓ Yolcu ↔ Alıcı', '✓ Путешественник ↔ Получатель'],
  ['leaveReviewForReceiver', 'Leave a review for receiver', 'Laisser un avis pour le destinataire', 'Dejar una reseña al destinatario', 'Lascia una recensione al destinatario', 'Laat een beoordeling voor de ontvanger', 'Bewertung für Empfänger hinterlassen', 'اترك تقييمًا للمستلم', 'प्राप्तकर्ता के लिए रिव्यू दें', '为收件人留下评价', 'Alıcı için değerlendirme bırak', 'Оставить отзыв получателю'],
  ['leaveReviewForSender', 'Leave a review for a sender', 'Laisser un avis pour un expéditeur', 'Dejar una reseña a un remitente', 'Lascia una recensione a un mittente', 'Laat een beoordeling voor een afzender', 'Bewertung für einen Absender hinterlassen', 'اترك تقييمًا لمرسل', 'सेंडर के लिए रिव्यू दें', '为寄件人留下评价', 'Bir gönderen için değerlendirme bırak', 'Оставить отзыв отправителю'],
  ['leaveAReview', 'Leave a review', 'Laisser un avis', 'Dejar una reseña', 'Lascia una recensione', 'Laat een beoordeling', 'Bewertung hinterlassen', 'اترك تقييمًا', 'रिव्यू दें', '留下评价', 'Değerlendirme bırak', 'Оставить отзыв'],
  ['dispute', 'Dispute', 'Litige', 'Disputa', 'Disputa', 'Geschil', 'Streitfall', 'نزاع', 'विवाद', '争议', 'İtiraz', 'Спор'],
  ['offerAmount', 'Offer amount', 'Montant de l’offre', 'Importe de la oferta', 'Importo dell’offerta', 'Biedingsbedrag', 'Angebotsbetrag', 'مبلغ العرض', 'ऑफ़र राशि', '报价金额', 'Teklif tutarı', 'Сумма предложения'],
  ['sentOn', 'Sent on', 'Envoyé le', 'Enviado el', 'Inviato il', 'Verzonden op', 'Gesendet am', 'أُرسل في', 'भेजा गया', '发送于', 'Gönderilme', 'Отправлено'],
  ['timelineOpen', 'Open', 'Ouvert', 'Abierto', 'Aperto', 'Open', 'Offen', 'مفتوح', 'खुला', '开放', 'Açık', 'Открыто'],
  ['receiverAccepted', 'Receiver Accepted', 'Destinataire accepté', 'Destinatario aceptado', 'Destinatario accettato', 'Ontvanger geaccepteerd', 'Empfänger akzeptiert', 'تم قبول المستلم', 'प्राप्तकर्ता स्वीकृत', '收件人已接受', 'Alıcı kabul edildi', 'Получатель принял'],
  ['escrowRefunded', 'Escrow refunded', 'Séquestre remboursé', 'Depósito reembolsado', 'Deposito rimborsato', 'Escrow terugbetaald', 'Treuhand erstattet', 'أُعيد الضمان', 'एस्क्रो वापस', '托管已退款', 'Emanet iade edildi', 'Эскроу возвращён'],
  ['escrowFrozen', 'Escrow frozen', 'Séquestre gelé', 'Depósito congelado', 'Deposito bloccato', 'Escrow bevroren', 'Treuhand eingefroren', 'الضمان مجمّد', 'एस्क्रो फ़्रीज़', '托管已冻结', 'Emanet donduruldu', 'Эскроу заморожен'],
  ['disputeOpen', 'Dispute open', 'Litige ouvert', 'Disputa abierta', 'Disputa aperta', 'Geschil open', 'Streitfall offen', 'النزاع مفتوح', 'विवाद खुला', '争议已开启', 'İtiraz açık', 'Спор открыт'],
  ['bidAccepted', 'Bid accepted', 'Offre acceptée', 'Oferta aceptada', 'Offerta accettata', 'Bod geaccepteerd', 'Gebot angenommen', 'تم قبول العرض', 'बोली स्वीकृत', '报价已接受', 'Teklif kabul edildi', 'Ставка принята'],
  ['awaitingReceiver', 'Awaiting receiver', 'En attente du destinataire', 'Esperando al destinatario', 'In attesa del destinatario', 'Wachten op ontvanger', 'Warten auf Empfänger', 'في انتظار المستلم', 'प्राप्तकर्ता की प्रतीक्षा', '等待收件人', 'Alıcı bekleniyor', 'Ожидание получателя'],
  ['inTransitLower', 'In transit', 'En transit', 'En tránsito', 'In transito', 'Onderweg', 'Unterwegs', 'قيد النقل', 'ट्रांज़िट में', '运输中', 'Yolda', 'В пути'],
  ['readyForHandoffLower', 'Ready for handoff', 'Prêt pour la remise', 'Listo para la entrega', 'Pronto per la consegna', 'Klaar voor overdracht', 'Bereit zur Übergabe', 'جاهز للتسليم', 'हैंडऑफ़ के लिए तैयार', '准备交接', 'Teslime hazır', 'Готово к передаче'],
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

const re = /('chooseHowAddPhoto': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 chooseHowAddPhoto, got', matches.length);
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = `${m}\n${block(i)}`;
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted traveler keys for', i, 'languages,', rows.length, 'keys each');
