import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_match_state.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_global_stats_provider.dart';
import 'package:msupperlimbs/features/fnose/application/touch_data_provider.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/data/models/touch_data_param_model.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_match_stats_model.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/gameover_heatmap_painter_widget.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/accuracy_gauge_widget.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

class FNoseGameOverScreen extends ConsumerStatefulWidget {
  const FNoseGameOverScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FNoseGameOverScreen> createState() => _FNoseGameOverScreenState();
}

class _FNoseGameOverScreenState extends ConsumerState<FNoseGameOverScreen> {
  @override
  void initState() {
    super.initState();
    lockToPortrait();
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(fnoseMatchStateProvider);
    final l10n = AppLocalizations.of(context)!;
    
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.fnose_gameover_title)),
        body: Center(child: Text(l10n.fnose_gameover_noMatchData)),
      );
    }

    final touchDataAsync = ref.watch(touchDataProvider(
      TouchDataParams(
        userId: match.userId,
        sessionId: match.sessionId,
        matchId: match.matchId,
      ),
    ));

    final globalStatsAsync = ref.watch(fnoseGlobalStatsProvider);
    final userStatsAsync = ref.watch(fnoseUserStatsProvider(match.userId));
    final userRecentMatchesAsync = ref.watch(fnoseUserRecentMatchesProvider(match.userId));

    final totalTime = match.totalTime;
    final left = match.totalLeftSparks;
    final right = match.totalRightSparks;
    final total = match.totalSparks;
    final avgTime = (total ?? 0) > 0 ? totalTime / (total ?? 1) : 0.0;
    final mode =
        FNoseGameModeX.fromString(match.gameMode) ?? FNoseGameMode.leftHand;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fnose_gameover_title),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  touchDataAsync.when(
                    data: (touchLogs) {
                      final leftTouches =
                          touchLogs.where((t) => t.isLeftHand).toList();
                      final rightTouches =
                          touchLogs.where((t) => !t.isLeftHand).toList();

                      final totalTouches = touchLogs.length;
                      final screenSize = MediaQuery.of(context).size;
                                            

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .cardColor
                                  .withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildStatRow(l10n.fnose_gameover_totalTime, '${totalTime}s'),
                                    if (mode != FNoseGameMode.rightHand)
                                      _buildStatRow(l10n.fnose_gameover_leftTouches, '${leftTouches.length}'),
                                    if (mode != FNoseGameMode.leftHand)
                                      _buildStatRow(l10n.fnose_gameover_rightTouches, '${rightTouches.length}'),
                                    if (mode == FNoseGameMode.bothHands)
                                      _buildStatRow(l10n.fnose_gameover_totalTouches, '$totalTouches'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Match Statistics Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.fnose_gameover_matchStatistics,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    if (match.avgTouchTime != null)
                                      _buildStatRow(l10n.fnose_gameover_avgTouchTime, '${match.avgTouchTime!.toStringAsFixed(2)}s'),
                                    if (match.avgDistance != null)
                                      _buildStatRow(l10n.fnose_gameover_avgDistance, '${match.avgDistance!.toStringAsFixed(3)}'),
                                    if (match.avgAngle != null)
                                      _buildStatRow(l10n.fnose_gameover_avgAngle, '${match.avgAngle!.toStringAsFixed(1)}°'),
                                    if (match.timeCV != null)
                                      _buildStatRow(l10n.fnose_gameover_timeCV, '${match.timeCV!.toStringAsFixed(3)}'),
                                    if (match.distanceCV != null)
                                      _buildStatRow(l10n.fnose_gameover_distanceCV, '${match.distanceCV!.toStringAsFixed(3)}'),
                                    if (match.angleCV != null)
                                      _buildStatRow(l10n.fnose_gameover_angleCV, '${match.angleCV!.toStringAsFixed(3)}'),
                                    if (match.precisionIndex != null)
                                      _buildStatRow(l10n.fnose_gameover_precisionIndex, '${(match.precisionIndex! * 100).toStringAsFixed(1)}%'),
                                    if (match.consistencyIndex != null)
                                      _buildStatRow(l10n.fnose_gameover_consistencyIndex, '${(match.consistencyIndex! * 100).toStringAsFixed(1)}%'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.fnose_gameover_touchHeatmap,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 300,
                                  width: double.infinity,
                                  child: HeatmapPainterWidget(logs: touchLogs),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Performance Trend Chart
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.fnose_gameover_performanceTrend,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                                                 SizedBox(
                                   height: 200,
                                   width: double.infinity,
                                   child: _buildTrendChart(
                                     userRecentMatchesAsync,
                                     l10n,
                                   ),
                                 ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Performance Comparison Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.fnose_gameover_performanceComparison,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                                                 SizedBox(
                                   height: 200,
                                   width: double.infinity,
                                   child: _buildComparisonChart(
                                     globalStatsAsync,
                                     userStatsAsync,
                                     l10n,
                                   ),
                                 ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Accuracy Gauge
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.fnose_gameover_precisionGauge,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (match.precisionIndex != null)
                                  AccuracyGaugeWidget(
                                    precisionIndex: match.precisionIndex!,
                                    height: 120,
                                  )
                                else
                                  Text(
                                    l10n.fnose_gameover_precisionDataNotAvailable,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, _) => Text('${l10n.fnose_gameover_errorLoadingTouchData} $err'),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _ActionButton(
                        icon: Icons.home,
                        label: l10n.fnose_gameover_home,
                        onPressed: () => context.go('/home'),
                      ),
                      _ActionButton(
                        icon: Icons.replay,
                        label: l10n.fnose_gameover_playAgain,
                        onPressed: () => context.go('/fnose-intro'),
                      ),
                      _ActionButton(
                        icon: Icons.exit_to_app,
                        label: l10n.fnose_gameover_exit,
                        onPressed: () => SystemNavigator.pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(
    AsyncValue<List<FNoseMatchStatsModel>> userRecentMatchesAsync,
    AppLocalizations l10n,
  ) {
    return userRecentMatchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Text(
              l10n.fnose_gameover_noPreviousMatches,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Create data points including current match
        var allMatches = [...matches];
        final currentMatch = ref.read(fnoseMatchStateProvider);
        if (currentMatch != null && matches.isNotEmpty) {
          // Add current match data using the actual calculated values
          allMatches.insert(0, FNoseMatchStatsModel(
            matchId: currentMatch.matchId,
            userId: currentMatch.userId,
            timestamp: currentMatch.createdAt,
            avgTouchTime: currentMatch.avgTouchTime ?? 0.0,
            avgDistance: currentMatch.avgDistance ?? 0.0,
            avgAngle: currentMatch.avgAngle ?? 0.0,
            timeCV: currentMatch.timeCV ?? 0.0,
            distanceCV: currentMatch.distanceCV ?? 0.0,
            angleCV: currentMatch.angleCV ?? 0.0,
            precisionIndex: currentMatch.precisionIndex ?? 0.0,
            consistencyIndex: currentMatch.consistencyIndex ?? 0.0,
          ));
        }

        // Reverse to show chronological order (oldest to newest)
        allMatches = allMatches.reversed.toList();

        return Column(
          children: [
            // Touch Time Trend
            _buildTrendLine(
              l10n.fnose_gameover_touchTime,
              allMatches.map((m) => m.avgTouchTime).toList().cast<double>(),
              isLowerBetter: true,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            
            // Accuracy Trend
            _buildTrendLine(
              l10n.fnose_gameover_accuracy,
              allMatches.map((m) => m.precisionIndex * 100).toList().cast<double>(),
              isLowerBetter: false,
              color: Colors.green,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${l10n.fnose_gameover_errorLoadingTouchData} $error')),
    );
  }

  Widget _buildTrendLine(
    String label,
    List<double> values,
    {required bool isLowerBetter, required Color color}
  ) {
    if (values.isEmpty) return const SizedBox.shrink();

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: TrendLinePainter(
                    values: values,
                    minValue: minValue,
                    maxValue: maxValue,
                    color: color,
                    isLowerBetter: isLowerBetter,
                  ),
                  size: const Size(double.infinity, 40),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${values.last.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonChart(
    AsyncValue<dynamic> globalStatsAsync,
    AsyncValue<dynamic> userStatsAsync,
    AppLocalizations l10n,
  ) {
    return globalStatsAsync.when(
      data: (globalStats) {
        if (globalStats == null) {
          return Center(child: Text(l10n.fnose_gameover_noGlobalStats));
        }

        final currentMatch = ref.read(fnoseMatchStateProvider);
        if (currentMatch == null) {
          return Center(child: Text(l10n.fnose_gameover_noCurrentMatchData));
        }

        final currentTouchTime = currentMatch.avgTouchTime ?? 0.0;
        final currentAccuracy = (currentMatch.precisionIndex ?? 0.0) * 100; // Convert to percentage
        final currentDistance = currentMatch.avgDistance ?? 0.0;

        final globalTouchTime = globalStats.avgTouchTime;
        final globalAccuracy = globalStats.avgPrecisionIndex * 100; // Convert to percentage
        final globalDistance = globalStats.avgDistance;

        final userTouchTime = userStatsAsync.value?.avgTouchTime ?? globalTouchTime;
        final userAccuracy = (userStatsAsync.value?.avgPrecisionIndex ?? 0.5) * 100;
        final userDistance = userStatsAsync.value?.avgDistance ?? globalDistance;

        return Column(
          children: [
            // Time comparison
            _buildMetricRow(
              l10n.fnose_gameover_touchTime,
              currentTouchTime,
              userTouchTime,
              globalTouchTime,
              isLowerBetter: true,
              l10n: l10n,
            ),
            const SizedBox(height: 8),
            
            // Accuracy comparison
            _buildMetricRow(
              l10n.fnose_gameover_accuracy,
              currentAccuracy,
              userAccuracy,
              globalAccuracy,
              isLowerBetter: false,
              l10n: l10n,
            ),
            const SizedBox(height: 8),
            
            // Distance comparison
            _buildMetricRow(
              l10n.fnose_gameover_distance,
              currentDistance,
              userDistance,
              globalDistance,
              isLowerBetter: true,
              l10n: l10n,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${l10n.fnose_gameover_errorLoadingTouchData} $error')),
    );
  }

  Widget _buildMetricRow(
    String label,
    double current,
    double userAvg,
    double globalAvg,
    {required bool isLowerBetter, required AppLocalizations l10n}
  ) {
    final maxValue = [current, userAvg, globalAvg].reduce((a, b) => a > b ? a : b);
    final minValue = [current, userAvg, globalAvg].reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 1.0;

    final currentWidth = ((current - minValue) / normalizedRange) * 0.8;
    final userWidth = ((userAvg - minValue) / normalizedRange) * 0.8;
    final globalWidth = ((globalAvg - minValue) / normalizedRange) * 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Current (You)
                  Expanded(
                    flex: (currentWidth * 100).round(),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${l10n.fnose_gameover_you} ${current.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // User Average
                  Expanded(
                    flex: (userWidth * 100).round(),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${l10n.fnose_gameover_avg} ${userAvg.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // Global Average
                  Expanded(
                    flex: (globalWidth * 100).round(),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${l10n.fnose_gameover_global} ${globalAvg.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TrendLinePainter extends CustomPainter {
  final List<double> values;
  final double minValue;
  final double maxValue;
  final Color color;
  final bool isLowerBetter;

  TrendLinePainter({
    required this.values,
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.isLowerBetter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 1.0;

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedValue = (values[i] - minValue) / normalizedRange;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Create smooth curve
        final prevX = ((i - 1) / (values.length - 1)) * size.width;
        final prevY = size.height - (((values[i - 1] - minValue) / normalizedRange) * size.height);
        
        final controlX1 = prevX + (x - prevX) * 0.5;
        final controlY1 = prevY;
        final controlX2 = x - (x - prevX) * 0.5;
        final controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedValue = (values[i] - minValue) / normalizedRange;
      final y = size.height - (normalizedValue * size.height);

      canvas.drawCircle(Offset(x, y), 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
