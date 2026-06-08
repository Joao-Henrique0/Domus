import 'dart:math';

import 'package:flutter/material.dart';
import 'package:domus/utils/db_util.dart';

import 'transaction.dart';

class TransactionList with ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions {
    return [..._transactions.reversed];
  }

  int get itensCount {
    return _transactions.length;
  }

  Future<void> loadTransactions() async {
    final dataList = await DbUtil.getData('transactions');
    _transactions =
        dataList
            .map(
              (item) => Transaction(
                id: item['id'].toString(),
                title: item['title'].toString(),
                category: (item['category'] ?? 'Outros').toString(),
                value: (item['value'] as num).toDouble(),
                date: DateTime.parse(item['date'].toString()),
              ),
            )
            .toList();

    notifyListeners();
  }

  Transaction itemByIndex(int index) {
    return _transactions[index];
  }

  Future<void> saveTransaction(Map<String, Object> data) async {
    final hasId = data['id'] != null && (data['id'] as String).isNotEmpty;
    final transaction = Transaction(
      id: hasId ? data['id'] as String : Random().nextDouble().toString(),
      title: data['title'] as String,
      category: data['category'] as String,
      value: data['value'] as double,
      date: data['date'] as DateTime,
    );

    if (hasId) {
      await updateTransaction(transaction);
    } else {
      await addTransaction(transaction);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      _transactions[index] = transaction;
      notifyListeners();
      await DbUtil.updateData({
        'id': transaction.id,
        'title': transaction.title,
        'category': transaction.category,
        'value': transaction.value,
        'date': transaction.date.toIso8601String(),
      }, 'transactions');
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await DbUtil.insertData({
      'id': transaction.id,
      'title': transaction.title,
      'category': transaction.category,
      'value': transaction.value,
      'date': transaction.date.toIso8601String(),
    }, 'transactions');
    _transactions.add(transaction);
    notifyListeners();
  }

  Future<void> upsertTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      _transactions[index] = transaction;
      await DbUtil.updateData({
        'id': transaction.id,
        'title': transaction.title,
        'category': transaction.category,
        'value': transaction.value,
        'date': transaction.date.toIso8601String(),
      }, 'transactions');
    } else {
      _transactions.add(transaction);
      await DbUtil.insertData({
        'id': transaction.id,
        'title': transaction.title,
        'category': transaction.category,
        'value': transaction.value,
        'date': transaction.date.toIso8601String(),
      }, 'transactions');
    }
    notifyListeners();
  }

  Future<void> removeTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index >= 0) {
      _transactions.removeAt(index);
      notifyListeners();
      await DbUtil.deleteData(transaction.id, 'transactions');
    }
  }

  Future<void> removeTransactionById(String id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
    await DbUtil.deleteData(id, 'transactions');
    notifyListeners();
  }

  List<Transaction> recentsTransactions(int days) {
    return _transactions.where((tr) {
      return tr.date.isAfter(DateTime.now().subtract(Duration(days: days)));
    }).toList();
  }

  List<Transaction> transactionsForMonth(DateTime month) {
    final items =
        _transactions.where((tr) {
          return tr.date.year == month.year && tr.date.month == month.month;
        }).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Map<String, double> categoryTotalsForMonth(DateTime month) {
    final totals = <String, double>{};
    for (final transaction in transactionsForMonth(month)) {
      totals.update(
        transaction.category,
        (value) => value + transaction.value,
        ifAbsent: () => transaction.value,
      );
    }
    return totals;
  }

  double monthTotalValue(DateTime month) {
    return transactionsForMonth(month).fold(0.0, (sum, tr) => sum + tr.value);
  }

  double weekTotalValue(int days) {
    return recentsTransactions(days).fold(0.0, (sum, tr) => sum + tr.value);
  }
}
