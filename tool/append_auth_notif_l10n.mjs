import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

const rows = [
  ['identityVerified', 'Identity verified', 'Identité vérifiée', 'Identidad verificada', 'Identità verificata', 'Identiteit geverifieerd', 'Identität verifiziert', 'تم التحقق من الهوية', 'पहचान सत्यापित', '身份已验证', 'Kimlik doğrulandı', 'Личность подтверждена'],
  ['passwordResetCodeSent', 'Password reset code sent', 'Code de réinitialisation envoyé', 'Código de restablecimiento enviado', 'Codice di reset inviato', 'Wachtwoordresetcode verzonden', 'Passwort-Reset-Code gesendet', 'تم إرسال رمز إعادة تعيين كلمة المرور', 'पासवर्ड रीसेट कोड भेजा गया', '密码重置码已发送', 'Şifre sıfırlama kodu gönderildi', 'Код сброса пароля отправлен'],
  ['verificationCodeSentTo', 'A verification code was sent to {contact}.', 'Un code de vérification a été envoyé à {contact}.', 'Se envió un código de verificación a {contact}.', 'È stato inviato un codice di verifica a {contact}.', 'Er is een verificatiecode naar {contact} gestuurd.', 'Ein Bestätigungscode wurde an {contact} gesendet.', 'تم إرسال رمز تحقق إلى {contact}.', '{contact} पर सत्यापन कोड भेजा गया।', '验证码已发送至 {contact}。', '{contact} adresine doğrulama kodu gönderildi.', 'Код подтверждения отправлен на {contact}.'],
  ['kycApprovedBody', 'Your KYC was approved. You can now use all WWNGO features.', 'Votre KYC a été approuvé. Vous pouvez maintenant utiliser toutes les fonctionnalités WWNGO.', 'Tu KYC fue aprobado. Ya puedes usar todas las funciones de WWNGO.', 'Il tuo KYC è stato approvato. Ora puoi usare tutte le funzioni di WWNGO.', 'Je KYC is goedgekeurd. Je kunt nu alle WWNGO-functies gebruiken.', 'Dein KYC wurde genehmigt. Du kannst jetzt alle WWNGO-Funktionen nutzen.', 'تمت الموافقة على KYC الخاص بك. يمكنك الآن استخدام جميع ميزات WWNGO.', 'आपका KYC स्वीकृत हो गया। अब आप सभी WWNGO सुविधाएँ उपयोग कर सकते हैं।', '您的 KYC 已通过。现在可以使用全部 WWNGO 功能。', 'KYC’niz onaylandı. Artık tüm WWNGO özelliklerini kullanabilirsiniz.', 'Ваш KYC одобрен. Теперь вы можете пользоваться всеми функциями WWNGO.'],
  ['kycRejectedResubmitBody', 'Your ID could not be verified. Please resubmit your documents.', 'Votre pièce d’identité n’a pas pu être vérifiée. Veuillez renvoyer vos documents.', 'No se pudo verificar tu ID. Vuelve a enviar tus documentos.', 'Non è stato possibile verificare il tuo documento. Reinvia i documenti.', 'Je ID kon niet worden geverifieerd. Dien je documenten opnieuw in.', 'Dein Ausweis konnte nicht verifiziert werden. Bitte sende deine Dokumente erneut ein.', 'تعذّر التحقق من هويتك. يرجى إعادة إرسال مستنداتك.', 'आपकी पहचान सत्यापित नहीं हो सकी। कृपया दस्तावेज़ फिर से जमा करें।', '无法验证您的身份。请重新提交证件。', 'Kimliğiniz doğrulanamadı. Lütfen belgelerinizi yeniden gönderin.', 'Не удалось подтвердить личность. Отправьте документы повторно.'],
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

if (s.includes("'identityVerified':") && s.includes("'kycApprovedBody':")) {
  console.log('keys already present');
  process.exit(0);
}

const re = /('chipReview': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 chipReview, got', matches.length);
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
