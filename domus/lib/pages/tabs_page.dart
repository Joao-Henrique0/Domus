import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:domus/components/chat_provider.dart';
import 'package:domus/components/main_drawer.dart';
import 'package:domus/models/shopping_list.dart';
import 'package:domus/models/transaction_list.dart';
import 'package:domus/pages/bills_page.dart';
import 'package:domus/pages/chatbot_page.dart';
import 'package:domus/pages/expenses_page.dart';
import 'package:domus/pages/shopping_list_page.dart';
import 'package:domus/pages/tasks_page.dart';
import '../utils/app_routes.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedScreenIndex = 0;
  late final List<Map<String, Object>> _screens;
  @override
  void initState() {
    super.initState();
    _screens = [
      {
        'title': 'Lista de Tarefas',
        'screen': const TasksPage(),
        'actions': [
          IconButton(
            onPressed:
                () => Navigator.of(context).pushNamed(AppRoutes.taskForm),
            icon: const Icon(Icons.add),
          ),
        ],
      },
      {
        'title': 'Despesas',
        'screen': const ExpensesPage(),
        'actions': [
          IconButton(
            onPressed:
                () =>
                    Navigator.of(context).pushNamed(AppRoutes.transactionForm),
            icon: const Icon(Icons.add),
          ),
        ],
      },
      {
        'title': 'Contas a Pagar',
        'screen': const BillsPage(),
        'actions': [
          IconButton(
            onPressed:
                () => Navigator.of(context).pushNamed(AppRoutes.billForm),
            icon: const Icon(Icons.add),
          ),
        ],
      },
      {
        'title': 'Lista de Compras',
        'screen': const ShoppingListPage(),
        'actions': [
          IconButton(
            tooltip: 'Finalizar compra',
            onPressed: () => _finishPurchase(context),
            icon: const Icon(Icons.check_outlined),
          ),
          IconButton(
            tooltip: 'Excluir todos',
            onPressed: () => _confirmClearShoppingList(context),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      },
      {
        'title': 'ChatBot',
        'screen': const ChatbotScreen(),
        'actions': [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              Provider.of<ChatProvider>(
                context,
                listen: false,
              ).clearAllMessages();
            },
          ),
        ],
      },
    ];
  }

  _selectScreen(int index) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  Future<void> _confirmClearShoppingList(BuildContext context) async {
    final shoppingList = Provider.of<ShoppingList>(context, listen: false);
    if (shoppingList.itemsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A lista ja esta vazia.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir todos os itens?'),
            content: const Text('Essa acao remove todos os itens da lista.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm != true) return;
    await shoppingList.removeAllItems();
  }

  Future<void> _finishPurchase(BuildContext context) async {
    final shoppingList = Provider.of<ShoppingList>(context, listen: false);
    final transactionList = Provider.of<TransactionList>(
      context,
      listen: false,
    );

    if (shoppingList.purchasedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marque ao menos um item como comprado.')),
      );
      return;
    }

    final value = await _showPurchaseValueDialog(context);
    if (value == null) return;
    if (!mounted) return;

    await shoppingList.finishPurchase(
      value: value,
      transactionList: transactionList,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compra finalizada e despesa criada.')),
    );
  }

  Future<double?> _showPurchaseValueDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var purchaseValue = '';

    return showDialog<double>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Valor da compra'),
            content: Form(
              key: formKey,
              child: TextFormField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final isValid = RegExp(
                      r'^\d*([,.]\d{0,2})?$',
                    ).hasMatch(newValue.text);
                    return isValid ? newValue : oldValue;
                  }),
                ],
                onChanged: (value) => purchaseValue = value,
                validator: (input) {
                  final normalized = (input ?? '').replaceAll(',', '.');
                  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(normalized)) {
                    return 'Use no maximo 2 casas decimais';
                  }
                  final parsed = double.tryParse(normalized);
                  if (parsed == null || parsed <= 0) {
                    return 'Digite um valor valido';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  Navigator.of(ctx).pop(
                    double.parse(purchaseValue.replaceAll(',', '.')),
                  );
                },
                child: const Text('Finalizar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color =
        Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(_screens[_selectedScreenIndex]['title'] as String),
        actions: _screens[_selectedScreenIndex]['actions'] as List<Widget>,
      ),
      drawer: const MainDrawer(),
      body: _screens[_selectedScreenIndex]['screen'] as Widget,
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 20,
        backgroundColor: color,
        onTap: _selectScreen,
        currentIndex: _selectedScreenIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            backgroundColor: color,
            icon: const Icon(Icons.task),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.payments),
            label: 'Despesas',
            backgroundColor: color,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: 'Contas',
            backgroundColor: color,
          ),
          BottomNavigationBarItem(
            backgroundColor: color,
            icon: const Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: 'ChatBot',
            backgroundColor: color,
          ),
        ],
      ),
    );
  }
}
