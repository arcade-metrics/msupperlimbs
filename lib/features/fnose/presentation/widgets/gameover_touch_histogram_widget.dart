import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

class TouchHistogramWidget extends StatelessWidget {
  final List<TouchLog> touchLogs;

  const TouchHistogramWidget({Key? key, required this.touchLogs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (touchLogs.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.gameover_histogram_notEnoughTouches),
      );
    }

    final sorted = [...touchLogs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final intervals = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      intervals.add(sorted[i].timestamp - sorted[i - 1].timestamp);
    }

    final minVal = intervals.reduce(min);
    final maxVal = intervals.reduce(max);
    final range = maxVal - minVal;

    final binCount = 5;
    final binSize = max(range ~/ binCount, 1);
    final buckets = List.filled(binCount, 0);

    for (final t in intervals) {
      final i = ((t - minVal) ~/ binSize).clamp(0, binCount - 1);
      buckets[i]++;
    }

    final labels = List.generate(binCount, (i) {
      final start = minVal + i * binSize;
      final end = start + binSize;
      return l10n.gameover_distribution_range_ms(start.toString(), end.toString());
    });

    final barGroups = List.generate(binCount, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: buckets[i].toDouble(),
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.lightBlueAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    });

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gameover_histogram_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Text(labels[index],
                                style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) => Text('${value.toInt()}',
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
