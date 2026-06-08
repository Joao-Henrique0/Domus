import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:domus/utils/num_transform.dart';

class MonthlyPieChart extends StatelessWidget {
  const MonthlyPieChart({super.key, required this.categoryTotals});

  final Map<String, double> categoryTotals;

  static const _colors = [
    Color(0xFF009EE3),
    Color(0xFF00A650),
    Color(0xFFFFC043),
    Color(0xFFFF6B35),
    Color(0xFF7C4DFF),
    Color(0xFF00BFA6),
    Color(0xFFE53935),
  ];

  double get total {
    return categoryTotals.values.fold(0.0, (sum, value) => sum + value);
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        categoryTotals.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gastos do mes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(150),
                        painter: _PiePainter(entries: entries, colors: _colors),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'R\$${NumTranform.formatValue(total)}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontSize: 15),
                          ),
                          Text(
                            'total',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child:
                      entries.isEmpty
                          ? const Text('Sem gastos neste mes')
                          : SizedBox(
                            height: 230,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    entries.asMap().entries.map((item) {
                                      final index = item.key;
                                      final entry = item.value;
                                      final percent =
                                          total == 0
                                              ? 0
                                              : entry.value / total * 100;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color:
                                                    _colors[index %
                                                        _colors.length],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                entry.key,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '${percent.toStringAsFixed(0)}% - R\$${NumTranform.formatValue(entry.value)}',
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.entries, required this.colors});

  final List<MapEntry<String, double>> entries;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold(0.0, (sum, entry) => sum + entry.value);
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.18;
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    if (total == 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawArc(rect.deflate(strokeWidth / 2), 0, math.pi * 2, false, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (var i = 0; i < entries.length; i++) {
      final sweepAngle = entries[i].value / total * math.pi * 2;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}
