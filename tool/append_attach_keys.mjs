import fs from 'fs';

const path = 'lib/l10n/string_tables_extra.dart';
let s = fs.readFileSync(path, 'utf8');
if (s.includes("'attachFile':")) {
  console.log('attachFile already present');
  process.exit(0);
}

const extras = [
  ['Attach file', 'Share a photo of your parcel or delivery.', 'Take photo'],
  ['Joindre un fichier', 'Partagez une photo de votre colis ou livraison.', 'Prendre une photo'],
  ['Adjuntar archivo', 'Comparte una foto de tu paquete o entrega.', 'Tomar foto'],
  ['Allega file', 'Condividi una foto del pacco o della consegna.', 'Scatta foto'],
  ['Bestand bijvoegen', 'Deel een foto van je pakket of bezorging.', 'Foto maken'],
  ['Datei anhängen', 'Teile ein Foto deines Pakets oder deiner Lieferung.', 'Foto aufnehmen'],
  ['إرفاق ملف', 'شارك صورة لطردك أو توصيلك.', 'التقاط صورة'],
  ['फ़ाइल संलग्न करें', 'अपने पार्सल या डिलीवरी की फ़ोटो साझा करें।', 'फ़ोटो लें'],
  ['添加附件', '分享包裹或配送的照片。', '拍照'],
  ['Dosya ekle', 'Paketinizin veya teslimatınızın bir fotoğrafını paylaşın.', 'Fotoğraf çek'],
  ['Прикрепить файл', 'Поделитесь фото посылки или доставки.', 'Сделать фото'],
];

function esc(str) {
  return str.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

const re = /('photoLibrary': '(?:\\'|[^'])*',)/g;
const matches = [...s.matchAll(re)];
if (matches.length !== 11) {
  console.error('Expected 11 photoLibrary, got', matches.length);
  process.exit(1);
}

let i = 0;
s = s.replace(re, (m) => {
  const [af, sh, tp] = extras[i++];
  return `${m}
  'attachFile': '${esc(af)}',
  'shareParcelPhotoHint': '${esc(sh)}',
  'takePhoto': '${esc(tp)}',`;
});

fs.writeFileSync(path, s);
console.log('inserted attach keys', i);
