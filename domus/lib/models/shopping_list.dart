import 'package:flutter/material.dart';
import 'package:domus/models/shopping_item.dart';
import 'package:domus/utils/db_util.dart';

class ShoppingList with ChangeNotifier {
  List<ShoppingItem> _items = [];

  List<ShoppingItem> get items {
    final sorted = [..._items];
    sorted.sort((a, b) {
      if (a.purchased == b.purchased) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return a.purchased ? 1 : -1;
    });
    return sorted;
  }

  int get itemsCount => _items.length;

  Future<void> loadItems() async {
    final dataList = await DbUtil.getData('shopping_items');
    _items =
        dataList
            .map(
              (item) => ShoppingItem(
                id: item['id'].toString(),
                name: item['name'].toString(),
                purchased: item['purchased'] == 1,
              ),
            )
            .toList();
    notifyListeners();
  }

  Future<void> addItem(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final item = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmedName,
      purchased: false,
    );

    await DbUtil.insertData(_toDbMap(item), 'shopping_items');
    _items.add(item);
    notifyListeners();
  }

  Future<void> togglePurchased(ShoppingItem item) async {
    final updatedItem = item.copyWith(purchased: !item.purchased);
    final index = _items.indexWhere((current) => current.id == item.id);
    if (index < 0) return;

    _items[index] = updatedItem;
    notifyListeners();
    await DbUtil.updateData(_toDbMap(updatedItem), 'shopping_items');
  }

  Future<void> removeItem(ShoppingItem item) async {
    _items.removeWhere((current) => current.id == item.id);
    notifyListeners();
    await DbUtil.deleteData(item.id, 'shopping_items');
  }

  Map<String, Object?> _toDbMap(ShoppingItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'purchased': item.purchased,
    };
  }
}
