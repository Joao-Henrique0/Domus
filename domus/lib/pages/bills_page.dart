import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:domus/components/bill_item.dart';
import 'package:domus/models/bill_list.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  Timer? _timer;
  late Future<void> _loadBillsFuture;

  @override
  void initState() {
    super.initState();
    _loadBillsFuture = Provider.of<BillList>(context, listen: false).loadBills();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        Provider.of<BillList>(context, listen: false).refreshBills();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder(
        future: _loadBillsFuture,
        builder:
            (ctx, snapshot) =>
                snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                      padding: const EdgeInsets.all(8),
                      child: Consumer<BillList>(
                        builder: (ctx, billList, _) {
                          if (billList.itemsCount == 0) {
                            return const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Nenhuma conta cadastrada'),
                                SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: Icon(Icons.receipt_long, size: 78),
                                ),
                              ],
                            );
                          }

                          return ListView.builder(
                            itemCount: billList.itemsCount,
                            itemBuilder:
                                (ctx, i) => BillItem(
                                  bill: billList.bills[i],
                                ),
                          );
                        },
                      ),
                    ),
      ),
    );
  }
}
