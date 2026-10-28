import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

class TouchDistributionWidget extends StatelessWidget {
  final List<TouchLog> touchLogs;

  const TouchDistributionWidget({super.key, required this.touchLogs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (touchLogs.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.gameover_distribution_notEnoughTouches),
      );
    }

    // Calculate intervals between touches
    final sorted = [...touchLogs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final intervals = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      intervals.add(sorted[i].timestamp - sorted[i - 1].timestamp);
    }

    final minVal = intervals.reduce(min);
    final maxVal = intervals.reduce(max);
    final range = maxVal - minVal;
    final binCount = 6;
    final binSize = max(range ~/ binCount, 1);

    final List<List<double>> bins = List.generate(binCount, (_) => []);
    for (final t in intervals) {
      final i = ((t - minVal) ~/ binSize).clamp(0, binCount - 1);
      bins[i].add(t.toDouble());
    }

    // Position of points by column
    final scatterSpots = <ScatterSpot>[];
    for (int i = 0; i < bins.length; i++) {
      for (int j = 0; j < bins[i].length; j++) {
        scatterSpots.add(
          ScatterSpot(
            i.toDouble(),
            j.toDouble(),
            dotPainter: FlDotCirclePainter(
              color: Colors.teal,
              radius: 3,
            ),
          ),
        );
      }
    }

    // Smooth line (avg by bucket)
    final lineSpots = List<FlSpot>.generate(
      binCount,
      (i) => FlSpot(i.toDouble(), bins[i].length.toDouble()),
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gameover_distribution_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  ScatterChart(
                    ScatterChartData(
                      scatterSpots: scatterSpots,
                      minX: -0.5,
                      maxX: binCount - 0.5,
                      minY: 0,
                      maxY:
                          bins.map((e) => e.length).reduce(max).toDouble() + 1,
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= 0 && i < binCount) {
                                final start = minVal + (i * binSize);
                                final end = start + binSize;
                                return Text(l10n.gameover_distribution_range(start.toString(), end.toString()),
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
                            getTitlesWidget: (value, _) => Text(
                                '${value.toInt()}',
                                style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                  LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineSpots,
                          isCurved: true,
                          color: Colors.cyanAccent,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                      minX: -0.5,
                      maxX: binCount - 0.5,
                      minY: 0,
                      maxY:
                          bins.map((e) => e.length).reduce(max).toDouble() + 1,
                      titlesData: FlTitlesData(show: false),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
