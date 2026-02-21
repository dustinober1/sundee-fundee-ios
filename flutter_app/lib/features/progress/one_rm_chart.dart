import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/providers/one_rm_progress_provider.dart';
import '../../shared/providers/tracked_exercises_provider.dart';

class OneRmChart extends ConsumerStatefulWidget {
  const OneRmChart({super.key});

  @override
  ConsumerState<OneRmChart> createState() => _OneRmChartState();
}

class _OneRmChartState extends ConsumerState<OneRmChart> {
  String? selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final trackedAsync = ref.watch(trackedExercisesProvider);

    // CRITICAL: Key is on OUTER Column that ALWAYS renders
    return Column(
      key: const Key('one-rm-chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        trackedAsync.when(
          loading: () => const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (exercises) {
            if (exercises.isEmpty) {
              return const SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('No workout data yet',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text(
                        'Complete some workouts to see your strength progress.',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            final effectiveId = selectedExerciseId ?? exercises.first.id;
            final dataAsync = ref.watch(oneRmProgressProvider(effectiveId));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: effectiveId,
                  isExpanded: true,
                  items: exercises
                      .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          ))
                      .toList(),
                  onChanged: (id) => setState(() => selectedExerciseId = id),
                ),
                const SizedBox(height: 16),
                dataAsync.when(
                  loading: () => const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Error: $e'),
                  data: (data) {
                    if (data.isEmpty) {
                      return const SizedBox(
                        height: 250,
                        child: Center(
                            child: Text('No data for this exercise yet.')),
                      );
                    }
                    return _buildChart(data);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildChart(List<OneRmPoint> data) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.estimated1RM))
        .toList();

    // Prevent label overlap: show max 5 labels
    final interval =
        (data.length / 5).ceil().toDouble().clamp(1.0, double.infinity);

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Text(data[idx].date,
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()} lbs',
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
