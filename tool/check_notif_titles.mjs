import fs from 'fs';

const tables = fs.readFileSync('lib/l10n/string_tables_extra.dart', 'utf8')
  + fs.readFileSync('lib/l10n/string_tables.dart', 'utf8');

const titles = [
  'Incoming Parcel Request',
  'Parcel collected',
  'Counter offer declined',
  'Counter offer accepted',
  'New counter offer',
  'Counter offer updated',
  'Offer accepted',
  'New Sender Request',
  'Matching traveler available',
  'New Traveler Trip Available',
  'New traveler trip on your routes',
  'Receiver accepted',
  'Receiver paid fee share',
  'Platform fee paid',
  'NFC verification successful',
  'Delivery complete',
  'Parcel in transit',
  'Delivery cancelled',
  'Delivery auto-cancelled',
  'Traveler did not respond in time',
  'Sender request expired',
  'New review received',
  'Just now',
  'Yesterday',
  'A sender wants to send a parcel through you. Please review the request and accept or decline it.',
  'Identity verified',
  'Verification failed',
  'Password reset code sent',
];

for (const t of titles) {
  const needle = `'${t.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
  console.log(tables.includes(needle) ? 'OK ' : 'MISSING ', t);
}
