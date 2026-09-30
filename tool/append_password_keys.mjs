import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

if (s.includes("'strongPasswordHint'")) {
  console.log('already has strongPasswordHint');
  process.exit(0);
}

const translations = [
  // order must match occurrence of escrowHoldFor+escrow pairs in file (en,fr,es,it,nl,de,ar,hi,zh,tr,ru)
  {
    strongPasswordHint: 'Choose a strong password you have not used elsewhere.',
    currentPassword: 'Current password',
    newPassword: 'New password',
    confirmNewPassword: 'Confirm new password',
    passwordUpdatedTitle: 'Password updated',
    passwordChangedSuccessfully: 'Your password has been changed successfully.',
    enterCurrentPassword: 'Enter your current password',
    newPasswordMinLength: 'New password must be at least 8 characters',
    passwordsDoNotMatch: 'Passwords do not match',
    newPasswordMustDiffer: 'New password must be different from current password',
  },
  {
    strongPasswordHint: "Choisissez un mot de passe fort que vous n'avez pas utilisé ailleurs.",
    currentPassword: 'Mot de passe actuel',
    newPassword: 'Nouveau mot de passe',
    confirmNewPassword: 'Confirmer le nouveau mot de passe',
    passwordUpdatedTitle: 'Mot de passe mis à jour',
    passwordChangedSuccessfully: 'Votre mot de passe a été modifié avec succès.',
    enterCurrentPassword: 'Saisissez votre mot de passe actuel',
    newPasswordMinLength: 'Le nouveau mot de passe doit comporter au moins 8 caractères',
    passwordsDoNotMatch: 'Les mots de passe ne correspondent pas',
    newPasswordMustDiffer: "Le nouveau mot de passe doit être différent de l'actuel",
  },
  {
    strongPasswordHint: 'Elige una contraseña segura que no hayas usado en otro sitio.',
    currentPassword: 'Contraseña actual',
    newPassword: 'Nueva contraseña',
    confirmNewPassword: 'Confirmar nueva contraseña',
    passwordUpdatedTitle: 'Contraseña actualizada',
    passwordChangedSuccessfully: 'Tu contraseña se ha cambiado correctamente.',
    enterCurrentPassword: 'Introduce tu contraseña actual',
    newPasswordMinLength: 'La nueva contraseña debe tener al menos 8 caracteres',
    passwordsDoNotMatch: 'Las contraseñas no coinciden',
    newPasswordMustDiffer: 'La nueva contraseña debe ser distinta de la actual',
  },
  {
    strongPasswordHint: 'Scegli una password sicura che non hai usato altrove.',
    currentPassword: 'Password attuale',
    newPassword: 'Nuova password',
    confirmNewPassword: 'Conferma nuova password',
    passwordUpdatedTitle: 'Password aggiornata',
    passwordChangedSuccessfully: 'La tua password è stata modificata con successo.',
    enterCurrentPassword: 'Inserisci la password attuale',
    newPasswordMinLength: 'La nuova password deve avere almeno 8 caratteri',
    passwordsDoNotMatch: 'Le password non corrispondono',
    newPasswordMustDiffer: 'La nuova password deve essere diversa da quella attuale',
  },
  {
    strongPasswordHint: 'Kies een sterk wachtwoord dat je elders niet hebt gebruikt.',
    currentPassword: 'Huidig wachtwoord',
    newPassword: 'Nieuw wachtwoord',
    confirmNewPassword: 'Bevestig nieuw wachtwoord',
    passwordUpdatedTitle: 'Wachtwoord bijgewerkt',
    passwordChangedSuccessfully: 'Je wachtwoord is succesvol gewijzigd.',
    enterCurrentPassword: 'Voer je huidige wachtwoord in',
    newPasswordMinLength: 'Nieuw wachtwoord moet minstens 8 tekens hebben',
    passwordsDoNotMatch: 'Wachtwoorden komen niet overeen',
    newPasswordMustDiffer: 'Nieuw wachtwoord moet anders zijn dan het huidige',
  },
  {
    strongPasswordHint: 'Wähle ein starkes Passwort, das du noch nicht verwendet hast.',
    currentPassword: 'Aktuelles Passwort',
    newPassword: 'Neues Passwort',
    confirmNewPassword: 'Neues Passwort bestätigen',
    passwordUpdatedTitle: 'Passwort aktualisiert',
    passwordChangedSuccessfully: 'Dein Passwort wurde erfolgreich geändert.',
    enterCurrentPassword: 'Gib dein aktuelles Passwort ein',
    newPasswordMinLength: 'Das neue Passwort muss mindestens 8 Zeichen haben',
    passwordsDoNotMatch: 'Passwörter stimmen nicht überein',
    newPasswordMustDiffer: 'Das neue Passwort muss sich vom aktuellen unterscheiden',
  },
  {
    strongPasswordHint: 'اختر كلمة مرور قوية لم تستخدمها في مكان آخر.',
    currentPassword: 'كلمة المرور الحالية',
    newPassword: 'كلمة المرور الجديدة',
    confirmNewPassword: 'تأكيد كلمة المرور الجديدة',
    passwordUpdatedTitle: 'تم تحديث كلمة المرور',
    passwordChangedSuccessfully: 'تم تغيير كلمة المرور بنجاح.',
    enterCurrentPassword: 'أدخل كلمة المرور الحالية',
    newPasswordMinLength: 'يجب أن تتكون كلمة المرور الجديدة من 8 أحرف على الأقل',
    passwordsDoNotMatch: 'كلمتا المرور غير متطابقتين',
    newPasswordMustDiffer: 'يجب أن تختلف كلمة المرور الجديدة عن الحالية',
  },
  {
    strongPasswordHint: 'एक मजबूत पासवर्ड चुनें जिसका आपने कहीं और उपयोग न किया हो।',
    currentPassword: 'वर्तमान पासवर्ड',
    newPassword: 'नया पासवर्ड',
    confirmNewPassword: 'नए पासवर्ड की पुष्टि करें',
    passwordUpdatedTitle: 'पासवर्ड अपडेट किया गया',
    passwordChangedSuccessfully: 'आपका पासवर्ड सफलतापूर्वक बदल दिया गया है।',
    enterCurrentPassword: 'अपना वर्तमान पासवर्ड दर्ज करें',
    newPasswordMinLength: 'नया पासवर्ड कम से कम 8 अक्षरों का होना चाहिए',
    passwordsDoNotMatch: 'पासवर्ड मेल नहीं खाते',
    newPasswordMustDiffer: 'नया पासवर्ड वर्तमान से अलग होना चाहिए',
  },
  {
    strongPasswordHint: '请选择一个未在其他地方使用过的强密码。',
    currentPassword: '当前密码',
    newPassword: '新密码',
    confirmNewPassword: '确认新密码',
    passwordUpdatedTitle: '密码已更新',
    passwordChangedSuccessfully: '您的密码已成功更改。',
    enterCurrentPassword: '请输入当前密码',
    newPasswordMinLength: '新密码至少需要 8 个字符',
    passwordsDoNotMatch: '两次输入的密码不一致',
    newPasswordMustDiffer: '新密码必须与当前密码不同',
  },
  {
    strongPasswordHint: 'Başka yerde kullanmadığınız güçlü bir şifre seçin.',
    currentPassword: 'Mevcut şifre',
    newPassword: 'Yeni şifre',
    confirmNewPassword: 'Yeni şifreyi onayla',
    passwordUpdatedTitle: 'Şifre güncellendi',
    passwordChangedSuccessfully: 'Şifreniz başarıyla değiştirildi.',
    enterCurrentPassword: 'Mevcut şifrenizi girin',
    newPasswordMinLength: 'Yeni şifre en az 8 karakter olmalıdır',
    passwordsDoNotMatch: 'Şifreler eşleşmiyor',
    newPasswordMustDiffer: 'Yeni şifre mevcut şifreden farklı olmalıdır',
  },
  {
    strongPasswordHint: 'Выберите надёжный пароль, который вы ещё не использовали.',
    currentPassword: 'Текущий пароль',
    newPassword: 'Новый пароль',
    confirmNewPassword: 'Подтвердите новый пароль',
    passwordUpdatedTitle: 'Пароль обновлён',
    passwordChangedSuccessfully: 'Ваш пароль успешно изменён.',
    enterCurrentPassword: 'Введите текущий пароль',
    newPasswordMinLength: 'Новый пароль должен содержать не менее 8 символов',
    passwordsDoNotMatch: 'Пароли не совпадают',
    newPasswordMustDiffer: 'Новый пароль должен отличаться от текущего',
  },
];

function escapeDart(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function block(t) {
  return `
  'strongPasswordHint': '${escapeDart(t.strongPasswordHint)}',
  'currentPassword': '${escapeDart(t.currentPassword)}',
  'newPassword': '${escapeDart(t.newPassword)}',
  'confirmNewPassword': '${escapeDart(t.confirmNewPassword)}',
  'passwordUpdatedTitle': '${escapeDart(t.passwordUpdatedTitle)}',
  'passwordChangedSuccessfully': '${escapeDart(t.passwordChangedSuccessfully)}',
  'enterCurrentPassword': '${escapeDart(t.enterCurrentPassword)}',
  'newPasswordMinLength': '${escapeDart(t.newPasswordMinLength)}',
  'passwordsDoNotMatch': '${escapeDart(t.passwordsDoNotMatch)}',
  'newPasswordMustDiffer': '${escapeDart(t.newPasswordMustDiffer)}',`;
}

const re = /('escrowHoldFor': '[^']*',\n  'escrow': '[^']*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 escrow pairs, got', matches.length);
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = m + block(translations[i]);
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted password keys for', i, 'languages');
