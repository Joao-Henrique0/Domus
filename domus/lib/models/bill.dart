enum BillStatus { open, paid }

class Bill {
  final String id;
  final String title;
  final double value;
  final DateTime dueDate;
  final bool recurring;
  final BillStatus status;
  final String? expenseId;
  final String? recurringSourceId;
  final DateTime? paidDate;

  const Bill({
    required this.id,
    required this.title,
    required this.value,
    required this.dueDate,
    required this.recurring,
    required this.status,
    this.expenseId,
    this.recurringSourceId,
    this.paidDate,
  });

  bool get isPaid => status == BillStatus.paid;

  bool get isOverdue {
    final today = DateTime.now();
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final currentDay = DateTime(today.year, today.month, today.day);
    return !isPaid && dueDay.isBefore(currentDay);
  }

  String get effectiveStatusLabel {
    if (isPaid) return 'Paga';
    if (isOverdue) return 'Atrasada';
    return 'Em aberto';
  }

  Bill copyWith({
    String? id,
    String? title,
    double? value,
    DateTime? dueDate,
    bool? recurring,
    BillStatus? status,
    String? expenseId,
    String? recurringSourceId,
    DateTime? paidDate,
    bool clearExpenseId = false,
    bool clearRecurringSourceId = false,
    bool clearPaidDate = false,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      dueDate: dueDate ?? this.dueDate,
      recurring: recurring ?? this.recurring,
      status: status ?? this.status,
      expenseId: clearExpenseId ? null : expenseId ?? this.expenseId,
      recurringSourceId:
          clearRecurringSourceId
              ? null
              : recurringSourceId ?? this.recurringSourceId,
      paidDate: clearPaidDate ? null : paidDate ?? this.paidDate,
    );
  }
}
