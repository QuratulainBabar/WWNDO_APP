enum TransactionType { credit, debit }

class WalletTransaction {
  const WalletTransaction({
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
  });

  final double amount;
  final String description;
  final String date;
  final TransactionType type;
}
