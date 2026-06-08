class Transaction {
  final String id;
  final String title;
  final String category;
  final double value;
  final DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.value,
    required this.date,
  });

  bool get isBillGenerated => id.startsWith('bill_');
}
