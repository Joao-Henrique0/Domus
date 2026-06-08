import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:domus/components/multi_dismissible.dart';
import 'package:domus/models/bill.dart';
import 'package:domus/models/bill_list.dart';

class BillItem extends StatelessWidget {
  final Bill bill;

  const BillItem({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/y');
    final statusColor =
        bill.isPaid
            ? (isDark ? const Color(0xFF1E5A4C) : const Color(0xFFDDF4EC))
            : bill.isOverdue
            ? (isDark ? const Color(0xFF633033) : const Color(0xFFFFE3E2))
            : theme.colorScheme.tertiary;

    return MultiDismissible(
      object: bill,
      card: Card(
        elevation: isDark ? 0 : 3,
        shadowColor: isDark ? Colors.transparent : null,
        surfaceTintColor: Colors.transparent,
        color: statusColor,
        child: ListTile(
          minVerticalPadding: 12,
          leading: IconButton(
            tooltip: bill.isPaid ? 'Marcar em aberto' : 'Marcar como paga',
            onPressed: () {
              Provider.of<BillList>(
                context,
                listen: false,
              ).markPaid(bill, !bill.isPaid);
            },
            icon: Icon(
              bill.isPaid ? Icons.check_circle_outline : Icons.circle_outlined,
              color: textColor,
            ),
          ),
          title: Text(
            bill.title,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  dateFormat.format(bill.dueDate),
                  style: TextStyle(color: textColor.withValues(alpha: 0.75)),
                ),
                Text(
                  bill.effectiveStatusLabel,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (bill.paidDate != null)
                  Text(
                    'Pago em ${dateFormat.format(bill.paidDate!)}',
                    style: TextStyle(color: textColor.withValues(alpha: 0.75)),
                  ),
                if (bill.recurring)
                  Text(
                    'Recorrente',
                    style: TextStyle(color: textColor.withValues(alpha: 0.75)),
                  ),
              ],
            ),
          ),
          trailing: Text(
            moneyFormat.format(bill.value),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
