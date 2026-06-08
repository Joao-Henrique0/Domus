import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:domus/components/monthly_chart.dart';
import 'package:domus/components/monthly_pie_chart.dart';
import 'package:domus/components/transaction_item.dart';
import 'package:domus/models/transaction_list.dart';
import 'package:domus/utils/num_transform.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<void> _loadTransactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadTransactionsFuture = Provider.of<TransactionList>(
      context,
      listen: false,
    ).loadTransactions();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadTransactionsFuture,
      builder:
          (ctx, snapshot) =>
              snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : Consumer<TransactionList>(
                    builder: (ctx, transactionList, _) {
                      final monthlyTransactions = transactionList
                          .transactionsForMonth(_selectedMonth);
                      final monthTotal = transactionList.monthTotalValue(
                        _selectedMonth,
                      );

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => _changeMonth(-1),
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      DateFormat(
                                        'MMMM y',
                                      ).format(_selectedMonth),
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _changeMonth(1),
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              children: [
                                SizedBox(
                                  height: 320,
                                  child: PageView(
                                    children: [
                                      MonthlyPieChart(
                                        categoryTotals: transactionList
                                            .categoryTotalsForMonth(
                                              _selectedMonth,
                                            ),
                                      ),
                                      MonthlyChart(
                                        monthlyTransactions:
                                            monthlyTransactions,
                                        month: _selectedMonth,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Total do mes R\$${NumTranform.formatValue(monthTotal)}',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                if (monthlyTransactions.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: Text(
                                        'Nenhuma despesa cadastrada neste mes',
                                      ),
                                    ),
                                  )
                                else
                                  ...monthlyTransactions.map(
                                    (transaction) => TransactionItem(
                                      transaction: transaction,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
    );
  }
}
