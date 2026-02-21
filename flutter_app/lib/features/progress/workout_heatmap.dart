import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/workout_frequency_provider.dart';

class WorkoutHeatmap extends ConsumerWidget {
  const WorkoutHeatmap({super.key});

  // GitHub-style colors
  static const _colors = [
    Color(0xFFEBEDF0), // level 0 — no activity
    Color(0xFF9BE9A8), // level 1 — light
    Color(0xFF40C463), // level 2 — moderate
    Color(0xFF30A14E), // level 3 — high
    Color(0xFF216E39), // level 4 — intense
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(workoutFrequencyProvider);

    // CRITICAL: Key is on OUTER Column that ALWAYS renders
    return Column(
      key: const Key('workout-heatmap'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dataAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (result) {
            final activities = result.activities;
            final totalWorkouts = result.totalWorkouts;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    direction: Axis.vertical,
                    spacing: 3,
                    runSpacing: 3,
                    children: activities
                        .map((a) => Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _colors[a.level],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalWorkouts workouts in the last year',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
