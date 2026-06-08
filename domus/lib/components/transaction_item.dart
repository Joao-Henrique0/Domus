import 'package:domus/components/multi_dismissible.dart';
import 'package:domus/utils/num_transform.dart';
import '../models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title =
        transaction.category == 'Contas'
            ? transaction.title
            : transaction.category;

    return MultiDismissible(
        object: transaction,
        card: Card(
          color: Theme.of(context).colorScheme.tertiary,
          elevation: isDark ? 0 : 5,
          shadowColor: isDark ? Colors.transparent : null,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 80,
                      height: 30,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'R\$${NumTranform.formatValue(transaction.value)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                        ),
                      ),
                      if (transaction.category == 'Outros') ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 16),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('d MMM y').format(transaction.date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
