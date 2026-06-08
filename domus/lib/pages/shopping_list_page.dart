import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/models/shopping_item.dart';
import 'package:domus/models/shopping_list.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final _itemController = TextEditingController();
  late Future<void> _loadItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItemsFuture =
        Provider.of<ShoppingList>(context, listen: false).loadItems();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _itemController.text.trim();
    if (name.isEmpty) return;

    await Provider.of<ShoppingList>(context, listen: false).addItem(name);
    _itemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder(
        future: _loadItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        decoration: const InputDecoration(
                          labelText: 'Novo item',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<ShoppingList>(
                    builder: (context, shoppingList, _) {
                      if (shoppingList.itemsCount == 0) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 72),
                              SizedBox(height: 12),
                              Text('Nenhum item na lista'),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: shoppingList.items.length,
                        itemBuilder: (context, index) {
                          return _ShoppingItemTile(
                            item: shoppingList.items[index],
                            textColor: theme.colorScheme.onSurface,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final Color textColor;

  const _ShoppingItemTile({
    required this.item,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: isDark ? Colors.transparent : null,
      surfaceTintColor: Colors.transparent,
      child: CheckboxListTile(
        value: item.purchased,
        onChanged: (_) {
          Provider.of<ShoppingList>(
            context,
            listen: false,
          ).togglePurchased(item);
        },
        title: Text(
          item.name,
          style: TextStyle(
            color: textColor,
            decoration: item.purchased ? TextDecoration.lineThrough : null,
            fontWeight: item.purchased ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
        subtitle: Text(item.purchased ? 'Comprado' : 'Pendente'),
        secondary: IconButton(
          tooltip: 'Excluir',
          onPressed: () {
            Provider.of<ShoppingList>(
              context,
              listen: false,
            ).removeItem(item);
          },
          icon: const Icon(Icons.delete_outline),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
