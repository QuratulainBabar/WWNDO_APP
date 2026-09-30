import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');

if (s.includes("'searchChats':")) {
  console.log('searchChats already present');
  process.exit(0);
}

const translations = [
  {
    searchChats: 'Search chats',
    noChatsYet: 'No chats yet',
    noMatchingChats: 'No matching chats',
    conversationsAppearHere: 'Your conversations will appear here.',
    tryDifferentSearch: 'Try a different search term.',
    unableToLoadChats: 'Unable to load chats.',
    tapToStartChatting: 'Tap to start chatting',
    noMessagesYet: 'No messages yet',
    sayHelloToStart: 'Say hello to get the conversation started.',
    messageEllipsis: 'Message...',
    messageUser: 'Message {name}…',
    today: 'Today',
    yesterday: 'Yesterday',
    photo: 'Photo',
    photoLibrary: 'Photo library',
  },
  {
    searchChats: 'Rechercher des discussions',
    noChatsYet: 'Aucune discussion pour le moment',
    noMatchingChats: 'Aucune discussion correspondante',
    conversationsAppearHere: 'Vos conversations apparaîtront ici.',
    tryDifferentSearch: 'Essayez un autre terme de recherche.',
    unableToLoadChats: 'Impossible de charger les discussions.',
    tapToStartChatting: 'Appuyez pour démarrer la discussion',
    noMessagesYet: 'Aucun message pour le moment',
    sayHelloToStart: 'Dites bonjour pour démarrer la conversation.',
    messageEllipsis: 'Message...',
    messageUser: 'Message à {name}…',
    today: "Aujourd'hui",
    yesterday: 'Hier',
    photo: 'Photo',
    photoLibrary: 'Photothèque',
  },
  {
    searchChats: 'Buscar chats',
    noChatsYet: 'Aún no hay chats',
    noMatchingChats: 'No hay chats coincidentes',
    conversationsAppearHere: 'Tus conversaciones aparecerán aquí.',
    tryDifferentSearch: 'Prueba con otro término de búsqueda.',
    unableToLoadChats: 'No se pudieron cargar los chats.',
    tapToStartChatting: 'Toca para empezar a chatear',
    noMessagesYet: 'Aún no hay mensajes',
    sayHelloToStart: 'Saluda para iniciar la conversación.',
    messageEllipsis: 'Mensaje...',
    messageUser: 'Mensaje a {name}…',
    today: 'Hoy',
    yesterday: 'Ayer',
    photo: 'Foto',
    photoLibrary: 'Biblioteca de fotos',
  },
  {
    searchChats: 'Cerca nelle chat',
    noChatsYet: 'Nessuna chat ancora',
    noMatchingChats: 'Nessuna chat corrispondente',
    conversationsAppearHere: 'Le tue conversazioni appariranno qui.',
    tryDifferentSearch: 'Prova un altro termine di ricerca.',
    unableToLoadChats: 'Impossibile caricare le chat.',
    tapToStartChatting: 'Tocca per iniziare a chattare',
    noMessagesYet: 'Nessun messaggio ancora',
    sayHelloToStart: 'Di’ ciao per avviare la conversazione.',
    messageEllipsis: 'Messaggio...',
    messageUser: 'Messaggio a {name}…',
    today: 'Oggi',
    yesterday: 'Ieri',
    photo: 'Foto',
    photoLibrary: 'Libreria foto',
  },
  {
    searchChats: 'Chats zoeken',
    noChatsYet: 'Nog geen chats',
    noMatchingChats: 'Geen overeenkomende chats',
    conversationsAppearHere: 'Je gesprekken verschijnen hier.',
    tryDifferentSearch: 'Probeer een andere zoekterm.',
    unableToLoadChats: 'Chats laden mislukt.',
    tapToStartChatting: 'Tik om te beginnen met chatten',
    noMessagesYet: 'Nog geen berichten',
    sayHelloToStart: 'Zeg hallo om het gesprek te starten.',
    messageEllipsis: 'Bericht...',
    messageUser: 'Bericht aan {name}…',
    today: 'Vandaag',
    yesterday: 'Gisteren',
    photo: 'Foto',
    photoLibrary: 'Fotobibliotheek',
  },
  {
    searchChats: 'Chats suchen',
    noChatsYet: 'Noch keine Chats',
    noMatchingChats: 'Keine passenden Chats',
    conversationsAppearHere: 'Deine Unterhaltungen erscheinen hier.',
    tryDifferentSearch: 'Versuch einen anderen Suchbegriff.',
    unableToLoadChats: 'Chats konnten nicht geladen werden.',
    tapToStartChatting: 'Tippen, um den Chat zu starten',
    noMessagesYet: 'Noch keine Nachrichten',
    sayHelloToStart: 'Sag Hallo, um die Unterhaltung zu starten.',
    messageEllipsis: 'Nachricht...',
    messageUser: 'Nachricht an {name}…',
    today: 'Heute',
    yesterday: 'Gestern',
    photo: 'Foto',
    photoLibrary: 'Fotobibliothek',
  },
  {
    searchChats: 'البحث في المحادثات',
    noChatsYet: 'لا توجد محادثات بعد',
    noMatchingChats: 'لا توجد محادثات مطابقة',
    conversationsAppearHere: 'ستظهر محادثاتك هنا.',
    tryDifferentSearch: 'جرّب مصطلح بحث مختلفًا.',
    unableToLoadChats: 'تعذر تحميل المحادثات.',
    tapToStartChatting: 'انقر لبدء المحادثة',
    noMessagesYet: 'لا توجد رسائل بعد',
    sayHelloToStart: 'قل مرحبًا لبدء المحادثة.',
    messageEllipsis: 'رسالة...',
    messageUser: 'رسالة إلى {name}…',
    today: 'اليوم',
    yesterday: 'أمس',
    photo: 'صورة',
    photoLibrary: 'مكتبة الصور',
  },
  {
    searchChats: 'चैट खोजें',
    noChatsYet: 'अभी कोई चैट नहीं',
    noMatchingChats: 'कोई मिलान वाली चैट नहीं',
    conversationsAppearHere: 'आपकी बातचीत यहाँ दिखेगी।',
    tryDifferentSearch: 'कोई दूसरा खोज शब्द आज़माएँ।',
    unableToLoadChats: 'चैट लोड नहीं हो सकीं।',
    tapToStartChatting: 'चैट शुरू करने के लिए टैप करें',
    noMessagesYet: 'अभी कोई संदेश नहीं',
    sayHelloToStart: 'बातचीत शुरू करने के लिए नमस्ते कहें।',
    messageEllipsis: 'संदेश...',
    messageUser: '{name} को संदेश…',
    today: 'आज',
    yesterday: 'कल',
    photo: 'फ़ोटो',
    photoLibrary: 'फ़ोटो लाइब्रेरी',
  },
  {
    searchChats: '搜索聊天',
    noChatsYet: '暂无聊天',
    noMatchingChats: '没有匹配的聊天',
    conversationsAppearHere: '您的会话将显示在这里。',
    tryDifferentSearch: '请尝试其他搜索词。',
    unableToLoadChats: '无法加载聊天。',
    tapToStartChatting: '点按开始聊天',
    noMessagesYet: '暂无消息',
    sayHelloToStart: '打个招呼开始对话吧。',
    messageEllipsis: '消息...',
    messageUser: '给 {name} 发消息…',
    today: '今天',
    yesterday: '昨天',
    photo: '照片',
    photoLibrary: '照片图库',
  },
  {
    searchChats: 'Sohbetlerde ara',
    noChatsYet: 'Henüz sohbet yok',
    noMatchingChats: 'Eşleşen sohbet yok',
    conversationsAppearHere: 'Konuşmalarınız burada görünecek.',
    tryDifferentSearch: 'Farklı bir arama terimi deneyin.',
    unableToLoadChats: 'Sohbetler yüklenemedi.',
    tapToStartChatting: 'Sohbete başlamak için dokunun',
    noMessagesYet: 'Henüz mesaj yok',
    sayHelloToStart: 'Konuşmayı başlatmak için merhaba deyin.',
    messageEllipsis: 'Mesaj...',
    messageUser: '{name} kişisine mesaj…',
    today: 'Bugün',
    yesterday: 'Dün',
    photo: 'Fotoğraf',
    photoLibrary: 'Fotoğraf kitaplığı',
  },
  {
    searchChats: 'Искать в чатах',
    noChatsYet: 'Пока нет чатов',
    noMatchingChats: 'Нет подходящих чатов',
    conversationsAppearHere: 'Ваши переписки появятся здесь.',
    tryDifferentSearch: 'Попробуйте другой поисковый запрос.',
    unableToLoadChats: 'Не удалось загрузить чаты.',
    tapToStartChatting: 'Нажмите, чтобы начать чат',
    noMessagesYet: 'Пока нет сообщений',
    sayHelloToStart: 'Поздоровайтесь, чтобы начать разговор.',
    messageEllipsis: 'Сообщение...',
    messageUser: 'Сообщение для {name}…',
    today: 'Сегодня',
    yesterday: 'Вчера',
    photo: 'Фото',
    photoLibrary: 'Галерея',
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

const re = /('newPasswordMustDiffer': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 newPasswordMustDiffer, got', matches.length);
  for (const m of matches) console.log(m[0].slice(0, 80));
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const out = `${m}\n${block(translations[i])}`;
  i++;
  return out;
});

fs.writeFileSync(path, s);
console.log('inserted chat keys for', i, 'languages');
