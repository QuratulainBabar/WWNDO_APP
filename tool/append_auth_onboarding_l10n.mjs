import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

/** key -> [en, fr, es, it, nl, de, ar, hi, zh, tr, ru] */
const rows = [
  [
    'shipTaglineWelcome',
    'Ship it with\nsomeone\nalready going.',
    'Expédiez avec\nquelqu’un\nqui voyage déjà.',
    'Envíalo con\nalguien\nque ya viaja.',
    'Spedisci con\nchi sta già\nviaggiando.',
    'Verstuur mee met\niemand die\nal reist.',
    'Versenden mit\njemandem,\nder schon unterwegs ist.',
    'اشحن مع\nشخص يسافر\nبالفعل.',
    'किसी ऐसे व्यक्ति के साथ भेजें\nजो पहले से\nजा रहा हो।',
    '托付给\n已经在路上的人。',
    'Zaten yolda olan\nbiriyle\ngönderin.',
    'Отправьте с тем,\nкто уже\nедет.',
  ],
  [
    'welcomeSubtext',
    'Peer-to-peer delivery by real travelers.\nFaster. Cheaper. Verified.',
    'Livraison entre particuliers par de vrais voyageurs.\nPlus rapide. Moins cher. Vérifié.',
    'Entrega entre particulares por viajeros reales.\nMás rápido. Más barato. Verificado.',
    'Consegna peer-to-peer da viaggiatori reali.\nPiù veloce. Più conveniente. Verificato.',
    'Peer-to-peer bezorging door echte reizigers.\nSneller. Goedkoper. Geverifieerd.',
    'Peer-to-Peer-Zustellung durch echte Reisende.\nSchneller. Günstiger. Verifiziert.',
    'توصيل بين الأفراد عبر مسافرين حقيقيين.\nأسرع. أرخص. موثّق.',
    'वास्तविक यात्रियों द्वारा पीयर-टू-पीयर डिलीवरी।\nतेज़। सस्ता। सत्यापित।',
    '由真实旅客提供的点对点配送。\n更快。更省。已验证。',
    'Gerçek yolcularla eşler arası teslimat.\nDaha hızlı. Daha ucuz. Doğrulanmış.',
    'Доставка от человека к человеку реальными путешественниками.\nБыстрее. Дешевле. Проверено.',
  ],
  [
    'joinWwngoSubtitle',
    'Join WWNGO to send, carry, or receive parcels',
    'Rejoignez WWNGO pour envoyer, transporter ou recevoir des colis',
    'Únete a WWNGO para enviar, transportar o recibir paquetes',
    'Unisciti a WWNGO per inviare, trasportare o ricevere pacchi',
    'Word lid van WWNGO om pakketten te versturen, meenemen of ontvangen',
    'Tritt WWNGO bei, um Pakete zu senden, mitzunehmen oder zu empfangen',
    'انضم إلى WWNGO لإرسال الطرود أو حملها أو استلامها',
    'पार्सल भेजने, ले जाने या प्राप्त करने के लिए WWNGO से जुड़ें',
    '加入 WWNGO，寄送、携带或接收包裹',
    'Paket göndermek, taşımak veya almak için WWNGO’ya katılın',
    'Присоединяйтесь к WWNGO, чтобы отправлять, перевозить или получать посылки',
  ],
  [
    'addProfilePhoto',
    'Add profile photo',
    'Ajouter une photo de profil',
    'Añadir foto de perfil',
    'Aggiungi foto profilo',
    'Profielfoto toevoegen',
    'Profilfoto hinzufügen',
    'إضافة صورة الملف الشخصي',
    'प्रोफ़ाइल फ़ोटो जोड़ें',
    '添加头像',
    'Profil fotoğrafı ekle',
    'Добавить фото профиля',
  ],
  [
    'creatingAccountEllipsis',
    'Creating account…',
    'Création du compte…',
    'Creando cuenta…',
    'Creazione account…',
    'Account aanmaken…',
    'Konto wird erstellt…',
    'جارٍ إنشاء الحساب…',
    'खाता बनाया जा रहा है…',
    '正在创建账户…',
    'Hesap oluşturuluyor…',
    'Создание аккаунта…',
  ],
  [
    'createAccountArrow',
    'Create account →',
    'Créer un compte →',
    'Crear cuenta →',
    'Crea account →',
    'Account aanmaken →',
    'Konto erstellen →',
    'إنشاء حساب ←',
    'खाता बनाएँ →',
    '创建账户 →',
    'Hesap oluştur →',
    'Создать аккаунт →',
  ],
  [
    'emailPlaceholder',
    'you@email.com',
    'vous@email.com',
    'tu@email.com',
    'tu@email.com',
    'jij@email.com',
    'du@email.com',
    'you@email.com',
    'you@email.com',
    'you@email.com',
    'you@email.com',
    'you@email.com',
  ],
  [
    'atLeast8Characters',
    'At least 8 characters',
    'Au moins 8 caractères',
    'Al menos 8 caracteres',
    'Almeno 8 caratteri',
    'Minimaal 8 tekens',
    'Mindestens 8 Zeichen',
    '8 أحرف على الأقل',
    'कम से कम 8 वर्ण',
    '至少 8 个字符',
    'En az 8 karakter',
    'Не менее 8 символов',
  ],
  [
    'iAgreeToThe',
    'I agree to the ',
    'J’accepte les ',
    'Acepto los ',
    'Accetto i ',
    'Ik ga akkoord met de ',
    'Ich stimme den ',
    'أوافق على ',
    'मैं सहमत हूँ ',
    '我同意',
    'Şunları kabul ediyorum: ',
    'Я соглашаюсь с ',
  ],
  [
    'termsShort',
    'Terms',
    'Conditions',
    'Términos',
    'Termini',
    'Voorwaarden',
    'Bedingungen',
    'الشروط',
    'शर्तें',
    '条款',
    'Şartlar',
    'Условия',
  ],
  [
    'andConjunction',
    ' and ',
    ' et la ',
    ' y la ',
    ' e la ',
    ' en het ',
    ' und der ',
    ' و ',
    ' और ',
    '和',
    ' ve ',
    ' и ',
  ],
  [
    'termsAndConditions',
    'Terms & Conditions',
    'Conditions générales',
    'Términos y condiciones',
    'Termini e condizioni',
    'Algemene voorwaarden',
    'Allgemeine Geschäftsbedingungen',
    'الشروط والأحكام',
    'नियम और शर्तें',
    '条款与条件',
    'Şartlar ve Koşullar',
    'Условия использования',
  ],
  [
    'loginToWwngoAccount',
    'Log in to your WWNGO account',
    'Connectez-vous à votre compte WWNGO',
    'Inicia sesión en tu cuenta WWNGO',
    'Accedi al tuo account WWNGO',
    'Log in op je WWNGO-account',
    'Melde dich bei deinem WWNGO-Konto an',
    'سجّل الدخول إلى حساب WWNGO',
    'अपने WWNGO खाते में लॉग इन करें',
    '登录您的 WWNGO 账户',
    'WWNGO hesabınıza giriş yapın',
    'Войдите в свой аккаунт WWNGO',
  ],
  [
    'loggingInEllipsis',
    'Logging in…',
    'Connexion…',
    'Iniciando sesión…',
    'Accesso in corso…',
    'Bezig met inloggen…',
    'Anmeldung…',
    'جارٍ تسجيل الدخول…',
    'लॉग इन हो रहा है…',
    '正在登录…',
    'Giriş yapılıyor…',
    'Вход…',
  ],
  [
    'dontHaveAccount',
    "Don't have an account? ",
    'Pas encore de compte ? ',
    '¿No tienes una cuenta? ',
    'Non hai un account? ',
    'Nog geen account? ',
    'Noch kein Konto? ',
    'ليس لديك حساب؟ ',
    'खाता नहीं है? ',
    '还没有账户？',
    'Hesabınız yok mu? ',
    'Нет аккаунта? ',
  ],
  [
    'lastUpdatedPrefix',
    'Last updated {date}',
    'Dernière mise à jour {date}',
    'Última actualización {date}',
    'Ultimo aggiornamento {date}',
    'Laatst bijgewerkt {date}',
    'Zuletzt aktualisiert {date}',
    'آخر تحديث {date}',
    'अंतिम अपडेट {date}',
    '最后更新 {date}',
    'Son güncelleme {date}',
    'Последнее обновление {date}',
  ],
  [
    'readFullOnline',
    'Read full {title} online',
    'Lire {title} en ligne',
    'Leer {title} completo en línea',
    'Leggi {title} completo online',
    'Lees {title} volledig online',
    '{title} online vollständig lesen',
    'اقرأ {title} بالكامل عبر الإنترنت',
    '{title} पूरा ऑनलाइन पढ़ें',
    '在线阅读完整{title}',
    'Tam {title} çevrimiçi oku',
    'Читать полный текст: {title}',
  ],
  [
    'chooseHowAddPhoto',
    'Choose how you want to add your photo',
    'Choisissez comment ajouter votre photo',
    'Elige cómo quieres añadir tu foto',
    'Scegli come aggiungere la tua foto',
    'Kies hoe je je foto wilt toevoegen',
    'Wähle, wie du dein Foto hinzufügen möchtest',
    'اختر كيف تريد إضافة صورتك',
    'अपनी फ़ोटो कैसे जोड़ना चाहते हैं चुनें',
    '选择如何添加照片',
    'Fotoğrafınızı nasıl eklemek istediğinizi seçin',
    'Выберите, как добавить фото',
  ],
];

function esc(str) {
  return str
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$')
    .replace(/\n/g, '\\n');
}

function blockForLang(langIndex) {
  return rows
    .map((r) => `  '${r[0]}': '${esc(r[langIndex + 1])}',`)
    .join('\n');
}

// Anchor: last key we know exists at end of each language block before legal keys.
// Insert after 'myPostedDeliveries' near completed block OR after receiverHasNotAccepted
const re = /('receiverHasNotAccepted': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 receiverHasNotAccepted, got', matches.length);
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = `${m}\n${blockForLang(i)}`;
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted auth/onboarding keys for', i, 'languages');
