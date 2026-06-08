import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:domus/utils/num_transform.dart';
import '../models/transaction.dart';

class MonthlyChart extends StatelessWidget {
  final List<Transaction> monthlyTransactions;
  final DateTime month;

  const MonthlyChart({
    super.key,
    required this.monthlyTransactions,
    required this.month,
  });

  List<_CalendarDay?> get calendarDays {
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final leadingBlanks = firstDay.weekday % 7;
    final days = <_CalendarDay?>[
      ...List<_CalendarDay?>.filled(leadingBlanks, null),
    ];

    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final value = monthlyTransactions
          .where(
            (transaction) =>
                transaction.date.year == date.year &&
                transaction.date.month == date.month &&
                transaction.date.day == date.day,
          )
          .fold(0.0, (sum, transaction) => sum + transaction.value);
      days.add(_CalendarDay(day: day, value: value));
    }

    return days;
  }

  double get monthMaxValue {
    return calendarDays.fold(0.0, (max, day) {
      if (day == null) return max;
      return max > day.value ? max : day.value;
    });
  }

  Color getDayColor(double value, double maxValue, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (value == 0 || maxValue == 0) {
      return isDark ? const Color(0xFF243033) : Colors.grey.shade200;
    }

    final colorIntensity = value / maxValue;
    return Color.lerp(
      isDark ? const Color(0xFF243033) : Colors.grey.shade200,
      Theme.of(context).colorScheme.secondary,
      colorIntensity,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final days = calendarDays;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM y').format(month),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                    .map((label) => Expanded(child: Center(child: Text(label))))
                    .toList(),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rows = (days.length / 7).ceil();
                final cellHeight = constraints.maxHeight / rows;

                return Column(
                  children: List.generate(rows, (row) {
                    return SizedBox(
                      height: cellHeight,
                      child: Row(
                        children: List.generate(7, (column) {
                          final index = row * 7 + column;
                          final day = index < days.length ? days[index] : null;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child:
                                  day == null
                                      ? const SizedBox.shrink()
                                      : DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: getDayColor(
                                            day.value,
                                            monthMaxValue,
                                            context,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              day.day.toString(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (day.value > 0)
                                              Text(
                                                'R\$${NumTranform.formatValue(day.value)}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDay {
  final int day;
  final double value;

  const _CalendarDay({required this.day, required this.value});
}
