import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/models/bill.dart';
import 'package:domus/models/bill_list.dart';
import 'package:domus/models/task.dart';
import 'package:domus/models/task_list.dart';
import 'package:domus/models/transaction.dart';
import 'package:domus/models/transaction_list.dart';
import 'package:domus/utils/app_routes.dart';

class MultiDismissible extends StatelessWidget {
  final dynamic object;
  final Card card;
  const MultiDismissible({super.key, required this.object, required this.card});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(object.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeActionBackground(
        color: const Color.fromARGB(255, 33, 243, 61),
        alignment: Alignment.centerLeft,
        icon: Icons.edit,
        padding: const EdgeInsets.only(left: 20),
      ),
      secondaryBackground: _buildSwipeActionBackground(
        color: Colors.red,
        alignment: Alignment.centerRight,
        icon: Icons.delete,
        padding: const EdgeInsets.only(right: 20),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Navigator.of(context)
              .pushNamed(_getEditRoute(object), arguments: object);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await _showConfirmDialog(context);
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _removeItem(context, object);
        }
      },
      child: card,
    );
  }

  Widget _buildSwipeActionBackground({
    required Color color,
    required Alignment alignment,
    required IconData icon,
    required EdgeInsets padding,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: alignment,
      padding: padding,
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }

  String _getEditRoute(dynamic object) {
    if (object is Transaction) {
      return AppRoutes.transactionForm;
    }
    if (object is Task) {
      return AppRoutes.taskForm;
    }
    if (object is Bill) {
      return AppRoutes.billForm;
    }
    return AppRoutes.home;
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tem Certeza?'),
        content: const Text('Quer remover o item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  void _removeItem(BuildContext context, dynamic object) {
    if (object is Transaction) {
      Provider.of<TransactionList>(
        context,
        listen: false,
      ).removeTransaction(object);
      return;
    }

    if (object is Task) {
      Provider.of<TaskList>(context, listen: false).removeTask(object);
      return;
    }

    if (object is Bill) {
      Provider.of<BillList>(context, listen: false).removeBill(object);
    }
  }
}
