import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme.dart';
import '../../../domain/calculations/cycle_calculations.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/cycle_models.dart';
import '../providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _phaseColor(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return const Color(0xFFE25E29); // warm orange-red
    case CyclePhase.follicular:
      return const Color(0xFF4CAF50); // green
    case CyclePhase.ovulation:
      return const Color(0xFFF2A900); // gold
    case CyclePhase.luteal:
      return const Color(0xFF7E57C2); // lavender-purple
  }
}



String _phaseEmoji(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return '🩸';
    case CyclePhase.follicular:
      return '🌱';
    case CyclePhase.ovulation:
      return '☀️';
    case CyclePhase.luteal:
      return '🌙';
  }
}

String _flowLabel(FlowLevel level) {
  switch (level) {
    case FlowLevel.light:
      return 'Light';
    case FlowLevel.medium:
      return 'Medium';
    case FlowLevel.heavy:
      return 'Heavy';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class CycleTrackingScreen extends ConsumerWidget {
  const CycleTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodLogsAsync = ref.watch(periodLogsProvider);
    final cycleStatus = ref.watch(cycleStatusProvider);
    final recommendation = ref.watch(phaseRecommendationProvider);
    final userId = ref.watch(cycleUserIdProvider);

    return Scaffold(
      body: periodLogsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Fetching cycle data...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (userId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Waiting for authentication...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error loading cycle: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(periodLogsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (periodLogs) {
          final status = cycleStatus;
          final rec = recommendation;
          
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── Phase hero card
              _PhaseHeroCard(
                cycleStatus: status,
                recommendation: rec,
              ),

              const SizedBox(height: 20),

              // ── Quick actions
              _QuickActionsRow(
                hasOpenPeriod: periodLogs.any((l) => l.endDate == null),
                userId: userId,
              ),

              const SizedBox(height: 20),

              // ── Training recommendation
              if (rec != null) ...[
                _TrainingRecommendationCard(recommendation: rec),
                const SizedBox(height: 20),
              ],

              // ── Phase timeline
              if (status != null) ...[
                _PhaseTimelineCard(cycleStatus: status),
                const SizedBox(height: 20),
              ],

              // ── Symptom quick-log
              _SymptomQuickLogCard(userId: userId),

              const SizedBox(height: 20),

              // ── Period log history
              _PeriodHistoryCard(logs: periodLogs, userId: userId),

              const SizedBox(height: 20),

              // ── Cycle Settings
              _CycleSettingsCard(userId: userId),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase Hero Card
// ─────────────────────────────────────────────────────────────────────────────

class _PhaseHeroCard extends StatelessWidget {
  const _PhaseHeroCard({
    required this.cycleStatus,
    required this.recommendation,
  });

  final CycleStatusResult? cycleStatus;
  final PhaseRecommendation? recommendation;

  @override
  Widget build(BuildContext context) {
    if (cycleStatus == null) {
      return _EmptyStateCard(
        icon: Icons.monitor_heart_outlined,
        title: 'Start Tracking',
        body:
            'Log your first period to begin receiving phase-based training recommendations.',
      );
    }

    final phase = cycleStatus!.currentPhase;
    final color = _phaseColor(phase);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _phaseEmoji(phase),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation?.title ?? phase.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day ${cycleStatus!.cycleDay}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _MiniStat(
                label: 'Days until\nnext phase',
                value: '${cycleStatus!.daysUntilNextPhase}',
                color: color,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Predicted\nnext period',
                value: DateFormat('MMM d').format(
                  cycleStatus!.predictedNextPeriod,
                ),
                color: color,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Intensity',
                value: recommendation?.intensityRecommendation.toUpperCase() ??
                    '—',
                color: color,
              ),
            ],
          ),

          if (recommendation != null) ...[
            const SizedBox(height: 16),
            Text(
              recommendation!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow({required this.hasOpenPeriod, required this.userId});

  final bool hasOpenPeriod;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = userId == null || userId == 'guest';

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: hasOpenPeriod
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline,
            label: hasOpenPeriod ? 'End Period' : 'Start Period',
            color: AppColors.brandSecondary,
            onTap: isGuest
                ? () => _showGuestWarning(context)
                : () async {
                    final controller =
                        ref.read(cycleControllerProvider.notifier);
                    if (hasOpenPeriod) {
                      await controller.endPeriod();
                    } else {
                      await controller.startPeriod();
                    }
                  },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.add_chart,
            label: 'Log Symptom',
            color: AppColors.brandPrimary,
            onTap: isGuest
                ? () => _showGuestWarning(context)
                : () => _showSymptomDialog(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.calendar_month,
            label: 'Log Period',
            color: const Color(0xFF7E57C2),
            onTap: isGuest
                ? () => _showGuestWarning(context)
                : () => _showPeriodLogDialog(context, ref),
          ),
        ),
      ],
    );
  }

  void _showGuestWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to track your cycle.')),
    );
  }

  void _showSymptomDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SymptomLogBottomSheet(userId: userId!),
    );
  }

  void _showPeriodLogDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PeriodLogBottomSheet(userId: userId!),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Training Recommendation Card
// ─────────────────────────────────────────────────────────────────────────────

class _TrainingRecommendationCard extends StatelessWidget {
  const _TrainingRecommendationCard({required this.recommendation});

  final PhaseRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor(recommendation.phase);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Training Focus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recommendation.trainingFocus,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            if (recommendation.exercisesToEmphasize.isNotEmpty) ...[
              _ChipGroup(
                label: 'Emphasize',
                items: recommendation.exercisesToEmphasize,
                chipColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 10),
            ],

            if (recommendation.exercisesToAvoid.isNotEmpty) ...[
              _ChipGroup(
                label: 'Limit',
                items: recommendation.exercisesToAvoid,
                chipColor: AppColors.brandSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.items,
    required this.chipColor,
  });

  final String label;
  final List<String> items;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: chipColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase Timeline Card
// ─────────────────────────────────────────────────────────────────────────────

class _PhaseTimelineCard extends ConsumerWidget {
  const _PhaseTimelineCard({required this.cycleStatus});

  final CycleStatusResult cycleStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(cycleUserIdProvider) ?? '';
    final settings =
        ref.watch(cycleSettingsProvider).value ?? defaultCycleSettings(userId);
    final boundaries = CycleCalculations.getPhaseBoundaries(
      settings: settings,
    );
    final totalDays = settings.averageCycleLength;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Phase progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: CyclePhase.values.map((phase) {
                    final bounds = boundaries[phase];
                    if (bounds == null) return const SizedBox.shrink();
                    final length = (bounds.end - bounds.start + 1);
                    final fraction = length / totalDays;
                    final isCurrent = phase == cycleStatus.currentPhase;

                    return Expanded(
                      flex: (fraction * 100).round(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? _phaseColor(phase)
                              : _phaseColor(phase).withValues(alpha: 0.25),
                          border: isCurrent
                              ? Border.all(
                                  color: _phaseColor(phase),
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Phase legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: CyclePhase.values.map((phase) {
                final isCurrent = phase == cycleStatus.currentPhase;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? _phaseColor(phase)
                            : _phaseColor(phase).withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phase.name[0].toUpperCase() + phase.name.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent
                            ? _phaseColor(phase)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symptom Quick-Log Card
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, String>> _commonSymptoms = [
  {'id': 'cramps', 'label': 'Cramps', 'emoji': '🤕'},
  {'id': 'headache', 'label': 'Headache', 'emoji': '🤯'},
  {'id': 'bloating', 'label': 'Bloating', 'emoji': '🫧'},
  {'id': 'fatigue', 'label': 'Fatigue', 'emoji': '😴'},
  {'id': 'mood-swings', 'label': 'Mood Swings', 'emoji': '😤'},
  {'id': 'acne', 'label': 'Acne', 'emoji': '😖'},
  {'id': 'back-pain', 'label': 'Back Pain', 'emoji': '🔥'},
  {'id': 'insomnia', 'label': 'Insomnia', 'emoji': '🌙'},
];

class _SymptomQuickLogCard extends ConsumerWidget {
  const _SymptomQuickLogCard({required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = userId == null || userId == 'guest';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.healing, color: AppColors.brandSecondary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Quick Symptom Log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _commonSymptoms.map((symptom) {
                return _SymptomChip(
                  emoji: symptom['emoji']!,
                  label: symptom['label']!,
                  onTap: isGuest
                      ? null
                      : () {
                          final log = SymptomLogModel(
                            id: const Uuid().v4(),
                            userId: userId!,
                            date: DateTime.now(),
                            symptomId: symptom['id']!,
                            severity: 3,
                            notes: null,
                          );
                          ref
                              .read(cycleControllerProvider.notifier)
                              .saveSymptomLog(log);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${symptom['emoji']} ${symptom['label']} logged',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  const _SymptomChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period History Card
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodHistoryCard extends ConsumerWidget {
  const _PeriodHistoryCard({required this.logs, required this.userId});

  final List<PeriodLogModel> logs;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.brandPrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Period History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No period logs yet.\nTap "Start Period" to begin tracking.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...logs.take(5).map((log) {
                final duration = log.endDate != null
                    ? log.endDate!.difference(log.startDate).inDays + 1
                    : null;
                return _PeriodHistoryRow(
                  log: log,
                  duration: duration,
                  onDelete: userId != null && userId != 'guest'
                      ? () {
                          ref
                              .read(cycleControllerProvider.notifier)
                              .deletePeriodLog(
                                userId: userId!,
                                logId: log.id,
                              );
                        }
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PeriodHistoryRow extends StatelessWidget {
  const _PeriodHistoryRow({
    required this.log,
    required this.duration,
    required this.onDelete,
  });

  final PeriodLogModel log;
  final int? duration;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isOpen = log.endDate == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.brandSecondary.withValues(alpha: 0.06)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: isOpen
              ? Border.all(color: AppColors.brandSecondary.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isOpen ? Icons.circle : Icons.check_circle,
              size: 18,
              color: isOpen
                  ? AppColors.brandSecondary
                  : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOpen
                        ? 'Started ${DateFormat.MMMd().format(log.startDate)}'
                        : '${DateFormat.MMMd().format(log.startDate)} – ${DateFormat.MMMd().format(log.endDate!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (duration != null)
                    Text(
                      '$duration day${duration == 1 ? '' : 's'} · ${_flowLabel(log.flowLevel)} flow',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (isOpen)
                    Text(
                      'In progress · ${_flowLabel(log.flowLevel)} flow',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brandSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.textSecondary,
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cycle Settings Card
// ─────────────────────────────────────────────────────────────────────────────

class _CycleSettingsCard extends ConsumerWidget {
  const _CycleSettingsCard({required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(cycleSettingsProvider);
    final isGuest = userId == null || userId == 'guest';

    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (settings) {
        final s = settings ?? defaultCycleSettings(userId ?? '');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.brandPrimary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Cycle Settings',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSlider(
                  label: 'Cycle Length',
                  value: s.averageCycleLength,
                  unit: 'days',
                  min: 20,
                  max: 45,
                  onChanged: isGuest
                      ? null
                      : (val) {
                          final updated = CycleSettingsModel(
                            id: s.id,
                            userId: userId!,
                            averageCycleLength: val,
                            averagePeriodLength: s.averagePeriodLength,
                            lutealPhaseLength: s.lutealPhaseLength,
                            enabledSymptomIds: s.enabledSymptomIds,
                            notificationsEnabled: s.notificationsEnabled,
                          );
                          ref
                              .read(cycleControllerProvider.notifier)
                              .saveCycleSettings(updated);
                        },
                ),
                const SizedBox(height: 12),
                _SettingsSlider(
                  label: 'Period Length',
                  value: s.averagePeriodLength,
                  unit: 'days',
                  min: 2,
                  max: 10,
                  onChanged: isGuest
                      ? null
                      : (val) {
                          final updated = CycleSettingsModel(
                            id: s.id,
                            userId: userId!,
                            averageCycleLength: s.averageCycleLength,
                            averagePeriodLength: val,
                            lutealPhaseLength: s.lutealPhaseLength,
                            enabledSymptomIds: s.enabledSymptomIds,
                            notificationsEnabled: s.notificationsEnabled,
                          );
                          ref
                              .read(cycleControllerProvider.notifier)
                              .saveCycleSettings(updated);
                        },
                ),
                const SizedBox(height: 12),
                _SettingsSlider(
                  label: 'Luteal Phase Length',
                  value: s.lutealPhaseLength,
                  unit: 'days',
                  min: 10,
                  max: 18,
                  onChanged: isGuest
                      ? null
                      : (val) {
                          final updated = CycleSettingsModel(
                            id: s.id,
                            userId: userId!,
                            averageCycleLength: s.averageCycleLength,
                            averagePeriodLength: s.averagePeriodLength,
                            lutealPhaseLength: val,
                            enabledSymptomIds: s.enabledSymptomIds,
                            notificationsEnabled: s.notificationsEnabled,
                          );
                          ref
                              .read(cycleControllerProvider.notifier)
                              .saveCycleSettings(updated);
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '$value $unit',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: AppColors.brandPrimary,
          onChanged: onChanged != null
              ? (v) => onChanged!(v.round())
              : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.brandPrimary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symptom Log Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SymptomLogBottomSheet extends ConsumerStatefulWidget {
  const _SymptomLogBottomSheet({required this.userId});
  final String userId;

  @override
  ConsumerState<_SymptomLogBottomSheet> createState() =>
      _SymptomLogBottomSheetState();
}

class _SymptomLogBottomSheetState
    extends ConsumerState<_SymptomLogBottomSheet> {
  String? _selectedSymptom;
  int _severity = 3;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Symptom',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _commonSymptoms.map((s) {
              final isSelected = _selectedSymptom == s['id'];
              return ChoiceChip(
                label: Text('${s['emoji']} ${s['label']}'),
                selected: isSelected,
                selectedColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _selectedSymptom = s['id']),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Severity: $_severity / 5'),
          Slider(
            value: _severity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.brandSecondary,
            onChanged: (v) => setState(() => _severity = v.round()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              hintText: 'Notes (optional)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSymptom == null
                  ? null
                  : () {
                      final log = SymptomLogModel(
                        id: const Uuid().v4(),
                        userId: widget.userId,
                        date: DateTime.now(),
                        symptomId: _selectedSymptom!,
                        severity: _severity,
                        notes: _notesCtrl.text.isEmpty
                            ? null
                            : _notesCtrl.text,
                      );
                      ref
                          .read(cycleControllerProvider.notifier)
                          .saveSymptomLog(log);
                      Navigator.pop(context);
                    },
              child: const Text('Save Symptom'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period Log Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodLogBottomSheet extends ConsumerStatefulWidget {
  const _PeriodLogBottomSheet({required this.userId});
  final String userId;

  @override
  ConsumerState<_PeriodLogBottomSheet> createState() =>
      _PeriodLogBottomSheetState();
}

class _PeriodLogBottomSheetState
    extends ConsumerState<_PeriodLogBottomSheet> {
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  FlowLevel _flowLevel = FlowLevel.medium;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Period',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat.MMMd().format(_startDate)),
                  onPressed: () => _pickDate(isStart: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _endDate != null
                        ? DateFormat.MMMd().format(_endDate!)
                        : 'Ongoing',
                  ),
                  onPressed: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Flow Level',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<FlowLevel>(
            segments: FlowLevel.values
                .map(
                  (level) => ButtonSegment(
                    value: level,
                    label: Text(_flowLabel(level)),
                  ),
                )
                .toList(),
            selected: {_flowLevel},
            onSelectionChanged: (selected) {
              setState(() => _flowLevel = selected.first);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(hintText: 'Notes (optional)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final log = PeriodLogModel(
                  id: const Uuid().v4(),
                  userId: widget.userId,
                  startDate: _startDate,
                  endDate: _endDate,
                  flowLevel: _flowLevel,
                  notes:
                      _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
                );
                ref
                    .read(cycleControllerProvider.notifier)
                    .savePeriodLog(log);
                Navigator.pop(context);
              },
              child: const Text('Save Period Log'),
            ),
          ),
        ],
      ),
    );
  }
}
