import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

/** key + en,fr,es,it,nl,de,ar,hi,zh,tr,ru */
const rows = [
  ['selectBothFromToEndpoints', 'Select both From {endpoint} and To {endpoint}.', 'Sélectionnez À partir de {endpoint} et Vers {endpoint}.', 'Selecciona Origen {endpoint} y Destino {endpoint}.', 'Seleziona Da {endpoint} e A {endpoint}.', 'Selecteer zowel Van {endpoint} als Naar {endpoint}.', 'Wähle sowohl Von {endpoint} als auch Nach {endpoint}.', 'حدد من {endpoint} وإلى {endpoint}.', 'From {endpoint} और To {endpoint} दोनों चुनें।', '请同时选择出发{endpoint}和到达{endpoint}。', 'Hem From {endpoint} hem To {endpoint} seçin.', 'Выберите и «Откуда {endpoint}», и «Куда {endpoint}».'],
  ['requestCancelledFeesRefunded', 'Request cancelled. Escrow and platform fees refunded.', 'Demande annulée. Séquestre et frais de plateforme remboursés.', 'Solicitud cancelada. Depósito y tarifas de plataforma reembolsados.', 'Richiesta annullata. Deposito e commissioni di piattaforma rimborsati.', 'Verzoek geannuleerd. Escrow en platformkosten teruggestort.', 'Anfrage storniert. Treuhand und Plattformgebühren erstattet.', 'تم إلغاء الطلب. تم استرداد الضمان ورسوم المنصة.', 'अनुरोध रद्द। एस्क्रो और प्लेटफ़ॉर्म शुल्क वापस।', '请求已取消。托管资金和平台费已退还。', 'Talep iptal edildi. Emanet ve platform ücretleri iade edildi.', 'Запрос отменён. Эскроу и комиссия платформы возвращены.'],
  ['requestCancelledFeesKept', 'Request cancelled. Escrow refunded to sender; platform fees kept.', 'Demande annulée. Séquestre remboursé à l’expéditeur ; frais de plateforme conservés.', 'Solicitud cancelada. Depósito reembolsado al remitente; tarifas de plataforma retenidas.', 'Richiesta annullata. Deposito rimborsato al mittente; commissioni di piattaforma trattenute.', 'Verzoek geannuleerd. Escrow teruggestort naar afzender; platformkosten behouden.', 'Anfrage storniert. Treuhand an Absender erstattet; Plattformgebühren behalten.', 'تم إلغاء الطلب. أُعيد الضمان إلى المرسل؛ واحتفظ برسوم المنصة.', 'अनुरोध रद्द। एस्क्रो प्रेषक को वापस; प्लेटफ़ॉर्म शुल्क रखे गए।', '请求已取消。托管资金已退还给寄件人；平台费已保留。', 'Talep iptal edildi. Emanet gönderene iade edildi; platform ücretleri tutuldu.', 'Запрос отменён. Эскроу возвращён отправителю; комиссия платформы удержана.'],
  ['verificationRejectedValidDoc', 'Verification was rejected. Please try again with a valid document.', 'La vérification a été refusée. Veuillez réessayer avec un document valide.', 'La verificación fue rechazada. Inténtalo de nuevo con un documento válido.', 'La verifica è stata rifiutata. Riprova con un documento valido.', 'Verificatie is afgewezen. Probeer het opnieuw met een geldig document.', 'Die Verifizierung wurde abgelehnt. Bitte versuche es erneut mit einem gültigen Dokument.', 'تم رفض التحقق. يرجى المحاولة مجددًا بمستند صالح.', 'सत्यापन अस्वीकृत। कृपया मान्य दस्तावेज़ के साथ पुनः प्रयास करें।', '验证被拒绝。请使用有效证件重试。', 'Doğrulama reddedildi. Lütfen geçerli bir belgeyle yeniden deneyin.', 'Проверка отклонена. Повторите с действительным документом.'],
  ['verificationWasCanceled', 'Verification was canceled.', 'La vérification a été annulée.', 'La verificación se canceló.', 'La verifica è stata annullata.', 'Verificatie is geannuleerd.', 'Die Verifizierung wurde abgebrochen.', 'تم إلغاء التحقق.', 'सत्यापन रद्द किया गया।', '验证已取消。', 'Doğrulama iptal edildi.', 'Проверка отменена.'],
  ['verificationIncompleteFinishSteps', 'Verification is incomplete. Please finish all steps.', 'La vérification est incomplète. Veuillez terminer toutes les étapes.', 'La verificación está incompleta. Completa todos los pasos.', 'La verifica è incompleta. Completa tutti i passaggi.', 'Verificatie is onvolledig. Rond alle stappen af.', 'Die Verifizierung ist unvollständig. Bitte schließe alle Schritte ab.', 'التحقق غير مكتمل. يرجى إنهاء جميع الخطوات.', 'सत्यापन अधूरा है। कृपया सभी चरण पूरे करें।', '验证未完成。请完成所有步骤。', 'Doğrulama eksik. Lütfen tüm adımları tamamlayın.', 'Проверка не завершена. Завершите все шаги.'],
  ['verificationUnknownStatus', 'Verification finished with an unknown status.', 'La vérification s’est terminée avec un statut inconnu.', 'La verificación finalizó con un estado desconocido.', 'La verifica è terminata con uno stato sconosciuto.', 'Verificatie is beëindigd met een onbekende status.', 'Die Verifizierung endete mit einem unbekannten Status.', 'انتهى التحقق بحالة غير معروفة.', 'सत्यापन अज्ञात स्थिति के साथ समाप्त हुआ।', '验证以未知状态结束。', 'Doğrulama bilinmeyen bir durumla tamamlandı.', 'Проверка завершилась с неизвестным статусом.'],
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

if (s.includes("'selectBothFromToEndpoints':") && s.includes("'requestCancelledFeesRefunded':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('identityVerified': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 identityVerified, got', matches.length);
  // fallback anchor
  const re2 = /('kycApprovedBody': '(?:\\'|[^'])*',)/g;
  const m2 = [...s.matchAll(re2)];
  if (m2.length !== 11) {
    console.error('Expected 11 kycApprovedBody, got', m2.length);
    process.exit(1);
  }
  let i = 0;
  s = s.replace(re2, (m) => {
    const out = `${m}\n${block(i)}`;
    i++;
    return out;
  });
  fs.writeFileSync(path, s);
  console.log('inserted', rows.length, 'keys x', i, '(via kycApprovedBody)');
  process.exit(0);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = `${m}\n${block(i)}`;
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted', rows.length, 'keys x', i);
