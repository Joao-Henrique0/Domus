import 'package:flutter/material.dart';
import 'package:domus/components/notification.dart';
import 'package:domus/models/bill.dart';
import 'package:domus/models/transaction.dart';
import 'package:domus/models/transaction_list.dart';
import 'package:domus/utils/db_util.dart';

class BillList with ChangeNotifier {
  BillList(this._transactionList);

  final TransactionList _transactionList;
  List<Bill> _bills = [];

  List<Bill> get bills {
    final sorted = [..._bills];
    sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return sorted;
  }

  int get itemsCount => _bills.length;

  void refreshBills() {
    notifyListeners();
  }

  Future<void> loadBills() async {
    final dataList = await DbUtil.getData('bills');
    _bills =
        dataList
            .map(
              (item) => Bill(
                id: item['id'].toString(),
                title: item['title'].toString(),
                value: (item['value'] as num).toDouble(),
                dueDate: DateTime.parse(item['due_date'].toString()),
                recurring: item['recurring'] == 1,
                status:
                    item['status'] == 'paid'
                        ? BillStatus.paid
                        : BillStatus.open,
                expenseId: item['expense_id']?.toString(),
                recurringSourceId: item['recurring_source_id']?.toString(),
                paidDate:
                    item['paid_date'] == null
                        ? null
                        : DateTime.parse(item['paid_date'].toString()),
              ),
            )
            .toList();
    await _createDueRecurringBills();
    notifyListeners();
  }

  Future<void> saveBill(Map<String, Object?> data) async {
    final hasId = data['id'] != null && (data['id'] as String).isNotEmpty;
    final id =
        hasId
            ? data['id'] as String
            : DateTime.now().millisecondsSinceEpoch.toString();
    final recurring = data['recurring'] as bool;
    final status = data['status'] as BillStatus;
    final bill = Bill(
      id: id,
      title: data['title'] as String,
      value: data['value'] as double,
      dueDate: data['dueDate'] as DateTime,
      recurring: recurring,
      status: status,
      expenseId: data['expenseId'] as String?,
      recurringSourceId:
          recurring ? (data['recurringSourceId'] as String?) ?? id : null,
      paidDate:
          status == BillStatus.paid
              ? (data['paidDate'] as DateTime?) ?? DateTime.now()
              : null,
    );

    if (hasId) {
      await updateBill(bill);
    } else {
      await addBill(bill);
    }
  }

  Future<void> addBill(Bill bill) async {
    final syncedBill = await _syncPaidExpense(bill);
    await DbUtil.insertData(_toDbMap(syncedBill), 'bills');
    _bills.add(syncedBill);
    notifyListeners();
    await _scheduleBillNotification(syncedBill);
    final createdRecurringBills = await _createDueRecurringBills();
    if (createdRecurringBills) {
      notifyListeners();
    }
  }

  Future<void> updateBill(Bill bill) async {
    final index = _bills.indexWhere((item) => item.id == bill.id);
    final syncedBill = await _syncPaidExpense(bill);

    await DbUtil.updateData(_toDbMap(syncedBill), 'bills');
    if (index >= 0) {
      _bills[index] = syncedBill;
    } else {
      _bills.add(syncedBill);
    }
    notifyListeners();
    await _scheduleBillNotification(syncedBill);
    final createdRecurringBills = await _createDueRecurringBills();
    if (createdRecurringBills) {
      notifyListeners();
    }
  }

  Future<void> removeBill(Bill bill) async {
    _bills.removeWhere((item) => item.id == bill.id);
    notifyListeners();

    if (bill.expenseId != null) {
      await _transactionList.removeTransactionById(bill.expenseId!);
    }
    await LocalNotificationService.cancelBillDueNotifications(
      _billNotificationId(bill.id),
    );
    await DbUtil.deleteData(bill.id, 'bills');
  }

  Future<void> markPaid(Bill bill, bool paid) async {
    await updateBill(
      bill.copyWith(
        status: paid ? BillStatus.paid : BillStatus.open,
        paidDate: paid ? DateTime.now() : null,
        clearPaidDate: !paid,
      ),
    );
  }

  Future<void> rescheduleOpenBillNotifications() async {
    if (_bills.isEmpty) {
      await loadBills();
    }

    for (final bill in _bills.where((item) => !item.isPaid)) {
      await _scheduleBillNotification(bill);
    }
  }

  Future<bool> _createDueRecurringBills() async {
    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month);
    final existingKeys = _bills.map(_recurringMonthKey).toSet();
    final newBills = <Bill>[];

    for (final bill in [..._bills]) {
      if (!bill.recurring || !bill.isPaid) continue;

      final sourceId = bill.recurringSourceId ?? bill.id;
      var nextDueDate = _nextMonthDueDate(bill.dueDate);

      if (_isAfterMonth(
        DateTime(nextDueDate.year, nextDueDate.month),
        currentMonth,
      )) {
        continue;
      }

      final key = _recurringMonthKeyFor(sourceId, nextDueDate);
      if (existingKeys.contains(key)) continue;

      final nextBill = Bill(
        id: 'rec_${sourceId}_${nextDueDate.year}_${nextDueDate.month}',
        title: bill.title,
        value: bill.value,
        dueDate: nextDueDate,
        recurring: true,
        status: BillStatus.open,
        recurringSourceId: sourceId,
        paidDate: null,
      );

      await DbUtil.insertData(_toDbMap(nextBill), 'bills');
      await _scheduleBillNotification(nextBill);
      newBills.add(nextBill);
      existingKeys.add(key);
    }

    if (newBills.isEmpty) return false;

    _bills.addAll(newBills);
    return true;
  }

  Future<Bill> _syncPaidExpense(Bill bill) async {
    if (!bill.isPaid) {
      if (bill.expenseId != null) {
        await _transactionList.removeTransactionById(bill.expenseId!);
      }
      return bill.copyWith(clearExpenseId: true, clearPaidDate: true);
    }

    final expenseId = bill.expenseId ?? _expenseIdForBill(bill.id);
    final paidDate = bill.paidDate ?? DateTime.now();
    final transaction = Transaction(
      id: expenseId,
      title: bill.title,
      category: 'Contas',
      value: bill.value,
      date: paidDate,
    );
    await _transactionList.upsertTransaction(transaction);
    return bill.copyWith(expenseId: expenseId, paidDate: paidDate);
  }

  Future<void> _scheduleBillNotification(Bill bill) async {
    await LocalNotificationService.cancelBillDueNotifications(
      _billNotificationId(bill.id),
    );
    if (bill.isPaid) return;
    await LocalNotificationService.showBillDueNotification(
      id: _billNotificationId(bill.id),
      title: bill.title,
      value: bill.value,
      dueDate: bill.dueDate,
    );
  }

  Map<String, Object?> _toDbMap(Bill bill) {
    return {
      'id': bill.id,
      'title': bill.title,
      'value': bill.value,
      'due_date': bill.dueDate.toIso8601String(),
      'recurring': bill.recurring,
      'status': bill.status == BillStatus.paid ? 'paid' : 'open',
      'expense_id': bill.expenseId,
      'recurring_source_id': bill.recurringSourceId,
      'paid_date': bill.paidDate?.toIso8601String(),
    };
  }

  String _expenseIdForBill(String billId) => 'bill_$billId';

  int _billNotificationId(String billId) => 'bill_$billId'.hashCode;

  String _recurringMonthKey(Bill bill) {
    return _recurringMonthKeyFor(
      bill.recurringSourceId ?? bill.id,
      bill.dueDate,
    );
  }

  String _recurringMonthKeyFor(String sourceId, DateTime dueDate) {
    return '$sourceId-${dueDate.year}-${dueDate.month}';
  }

  bool _isAfterMonth(DateTime month, DateTime other) {
    return month.year > other.year ||
        (month.year == other.year && month.month > other.month);
  }

  DateTime _nextMonthDueDate(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(
      nextMonth.year,
      nextMonth.month,
      day,
      date.hour,
      date.minute,
    );
  }
}
