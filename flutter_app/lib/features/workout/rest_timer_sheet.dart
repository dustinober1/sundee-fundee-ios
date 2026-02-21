import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/rest_timer_provider.dart';

/// Modal bottom sheet for rest timer during workouts.
class RestTimerSheet extends ConsumerWidget {
  const RestTimerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RestTimerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final theme = Theme.of(context);

    // Auto-dismiss when complete (after 1-second grace period)
    ref.listen(restTimerProvider, (previous, next) {
      if (previous?.status != 'complete' && next.status == 'complete') {
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });

    return Container(
      key: const Key('rest-timer-sheet'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              if (timerState.exerciseName != null) ...[
                Text(
                  'Rest after ${timerState.exerciseName}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
              ],

              // Circular progress + countdown
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        key: const Key('rest-timer-progress'),
                        value: timerState.progress,
                        strokeWidth: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          timerState.isComplete
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timerState.isComplete ? 'Done!' : timerState.displayTime,
                          key: const Key('rest-timer-display'),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: timerState.isComplete
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        if (timerState.isPaused)
                          Text(
                            'PAUSED',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Time adjustment buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const Key('rest-timer-subtract-button'),
                    onPressed: timerState.isIdle || timerState.isComplete
                        ? null
                        : () =>
                            ref.read(restTimerProvider.notifier).subtractTime(),
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                    tooltip: '-15 seconds',
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    key: const Key('rest-timer-add-button'),
                    onPressed: timerState.isIdle || timerState.isComplete
                        ? null
                        : () => ref.read(restTimerProvider.notifier).addTime(),
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                    tooltip: '+15 seconds',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    key: const Key('rest-timer-cancel-button'),
                    onPressed: () {
                      ref.read(restTimerProvider.notifier).cancel();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                  if (!timerState.isComplete)
                    ElevatedButton.icon(
                      key: const Key('rest-timer-pause-resume-button'),
                      onPressed: () {
                        if (timerState.isRunning) {
                          ref.read(restTimerProvider.notifier).pause();
                        } else if (timerState.isPaused) {
                          ref.read(restTimerProvider.notifier).resume();
                        }
                      },
                      icon: Icon(
                        timerState.isRunning ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(timerState.isRunning ? 'Pause' : 'Resume'),
                    ),
                  TextButton.icon(
                    key: const Key('rest-timer-skip-button'),
                    onPressed: timerState.isComplete
                        ? () => Navigator.of(context).pop()
                        : () => ref.read(restTimerProvider.notifier).skip(),
                    icon: Icon(
                      timerState.isComplete ? Icons.check : Icons.skip_next,
                    ),
                    label: Text(timerState.isComplete ? 'Done' : 'Skip'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
