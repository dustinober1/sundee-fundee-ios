import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/providers/weekly_volume_provider.dart';

class WeeklyVolumeChart extends ConsumerWidget {
  const WeeklyVolumeChart({super.key});

  String _formatVolume(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(weeklyVolumeProvider);

    // CRITICAL: Key is on OUTER SizedBox that ALWAYS renders
    return SizedBox(
      key: const Key('weekly-volume-chart'),
      height: 250,
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No volume data yet',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Text(
                    'Complete some workouts to see your weekly volume here.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final barGroups = data
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.volume,
                        color: Theme.of(context).colorScheme.secondary,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ))
              .toList();

          // Label interval — show max 5 labels
          final interval =
              (data.length / 5).ceil().toDouble().clamp(1.0, double.infinity);

          return BarChart(
            BarChartData(
              gridData:
                  const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox();
                      }
                      return Text(data[idx].week,
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) => Text(
                        _formatVolume(value),
                        style: const TextStyle(fontSize: 10)),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              barGroups: barGroups,
            ),
          );
        },
      ),
    );
  }
}
