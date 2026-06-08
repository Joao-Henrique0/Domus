import '../components/chart_bar.dart';
import '../models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Chart extends StatelessWidget {
  const Chart({super.key, required this.recentsTransactions});
  final List<Transaction> recentsTransactions;
  List<Map<String, Object>> get groupedTransactions {
    return List.generate(7, (index) {
      final weekDay = DateTime.now().subtract(Duration(days: index));

      double totalSum = 0.0;

      for (var i = 0; i < recentsTransactions.length; i++) {
        if (recentsTransactions[i].date.day == weekDay.day &&
            recentsTransactions[i].date.month == weekDay.month &&
            recentsTransactions[i].date.year == weekDay.year) {
          totalSum += recentsTransactions[i].value;
        }
      }

      return {
        'day': DateFormat.E().format(weekDay)[0].toUpperCase(),
        'value': totalSum
      };
    }).reversed.toList();
  }

  double get _weekTotalValue {
    return groupedTransactions.fold(0.0, (sum, tr) {
      return sum + (tr['value'] as double);
    });
  }

  weekTotalValue() {
    return _weekTotalValue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiary,
      elevation: 6,
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: groupedTransactions.map((tr) {
            return Flexible(
              fit: FlexFit.tight,
              child: ChartBar(
                  label: tr['day'].toString(),
                  value: (tr['value'] as double),
                  percent: _weekTotalValue == 0
                      ? 0
                      : (tr['value'] as double) / _weekTotalValue),
            );
          }).toList(),
        ),
      ),
    );
  }
}
