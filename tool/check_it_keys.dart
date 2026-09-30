import 'lib/l10n/string_tables.dart';

void main() {
  final it = kStringTables['it']!;
  for (final k in [
    'verificationApproved',
    'verificationApprovedMessage',
    'statusLabel',
    'verifiedDetails',
    'nameColon',
    'backToSettings',
    'statusApprovedLabel',
    'ledgerTypeEscrowRelease',
    'escrowReleasedFor',
    'escrow',
    'ledgerDescTopUpStripe',
  ]) {
    print('$k => ${it[k]}');
  }
  print('Current password key => ${kEnglishToKey['Current password']}');
  print('Choose a strong... => ${kEnglishToKey['Choose a strong password you have not used elsewhere.']}');
}
