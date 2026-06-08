import 'package:flutter/material.dart';
import 'package:domus/utils/db_util.dart';

import 'expense_type.dart';

class ExpenseTypeList with ChangeNotifier {
  List<ExpenseType> _types = [];

  List<ExpenseType> get types {
    final sorted = [..._types];
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  Future<void> loadTypes() async {
    final data = await DbUtil.getData('expense_types');
    _types =
        data
            .map(
              (item) => ExpenseType(
                id: item['id'].toString(),
                name: item['name'].toString(),
              ),
            )
            .toList();
    notifyListeners();
  }

  Future<void> addType(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    if (normalized.toLowerCase() == 'outros') return;

    final id = normalized.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    await DbUtil.insertData({'id': id, 'name': normalized}, 'expense_types');
    await loadTypes();
  }

  Future<void> removeType(ExpenseType type) async {
    await DbUtil.deleteData(type.id, 'expense_types');
    _types.removeWhere((item) => item.id == type.id);
    notifyListeners();
  }
}
