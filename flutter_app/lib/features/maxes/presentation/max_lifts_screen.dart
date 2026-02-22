import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/exercise_definitions.dart';
import '../../../domain/models/lift_max_model.dart';
import '../providers.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MaxLiftsScreen extends ConsumerWidget {
  const MaxLiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxesAsync = ref.watch(liftMaxesProvider);

    return Scaffold(
      body: maxesAsync.when(
        data: (maxes) {
          final mappedMaxes = _groupMaxes(maxes);
          final categories = _groupExercisesByCategory();

          // Build a flat list of sliver delegates: one header + N rows per category.
          final slivers = <Widget>[];
          for (final category in categories.keys) {
            final exercises = categories[category]!;
            slivers.add(
              _CategoryHeader(label: category),
            );
            slivers.add(
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exercise = exercises[index];
                    return _ExerciseLiftRow(
                      exercise: exercise,
                      maxes: mappedMaxes[exercise.id] ?? {},
                    );
                  },
                  childCount: exercises.length,
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: slivers,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Map<String, Map<int, LiftMaxModel>> _groupMaxes(List<LiftMaxModel> maxes) {
    final grouped = <String, Map<int, LiftMaxModel>>{};
    for (final m in maxes) {
      grouped.putIfAbsent(m.exerciseId, () => {});
      final existing = grouped[m.exerciseId]![m.repCount];
      if (existing == null || m.updatedAt.isAfter(existing.updatedAt)) {
        grouped[m.exerciseId]![m.repCount] = m;
      }
    }
    return grouped;
  }

  Map<String, List<ExerciseDefinition>> _groupExercisesByCategory() {
    final grouped = <String, List<ExerciseDefinition>>{};
    for (final exercise in Exercises.all) {
      grouped.putIfAbsent(exercise.category, () => []);
      grouped[exercise.category]!.add(exercise);
    }
    return grouped;
  }
}

// ---------------------------------------------------------------------------
// Sticky category header sliver
// ---------------------------------------------------------------------------

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        label: label,
        backgroundColor: colorScheme.surface,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate({
    required this.label,
    required this.backgroundColor,
  });

  final String label;
  final Color backgroundColor;

  static const double _height = 40.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: _height,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.label != label || oldDelegate.backgroundColor != backgroundColor;
}

// ---------------------------------------------------------------------------
// Compact lift row — tapping opens the bottom sheet
// ---------------------------------------------------------------------------

class _ExerciseLiftRow extends StatelessWidget {
  const _ExerciseLiftRow({required this.exercise, required this.maxes});

  final ExerciseDefinition exercise;
  final Map<int, LiftMaxModel> maxes;

  @override
  Widget build(BuildContext context) {
    final oneRm = maxes[1];
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(exercise.name, style: Theme.of(context).textTheme.bodyLarge),
      trailing: oneRm != null
          ? _MaxBadge(weight: oneRm.weight, label: '1RM')
          : Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 20),
      onTap: () => _openEditSheet(context),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LiftMaxEditSheet(exercise: exercise, maxes: maxes),
    );
  }
}

class _MaxBadge extends StatelessWidget {
  const _MaxBadge({required this.weight, required this.label});

  final double weight;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '${weight % 1 == 0 ? weight.toInt() : weight} lbs  $label',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet — all rep-max inputs for one lift
// ---------------------------------------------------------------------------

class _LiftMaxEditSheet extends ConsumerStatefulWidget {
  const _LiftMaxEditSheet({required this.exercise, required this.maxes});

  final ExerciseDefinition exercise;
  final Map<int, LiftMaxModel> maxes;

  @override
  ConsumerState<_LiftMaxEditSheet> createState() => _LiftMaxEditSheetState();
}

class _LiftMaxEditSheetState extends ConsumerState<_LiftMaxEditSheet> {
  static const _repCounts = [1, 3, 5, 10];

  late final Map<int, TextEditingController> _controllers;
  late final Map<int, DateTime?> _dates;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final r in _repCounts)
        r: TextEditingController(
          text: widget.maxes[r]?.weight.toString() ?? '',
        ),
    };
    _dates = {
      for (final r in _repCounts) r: widget.maxes[r]?.updatedAt,
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(int repCount) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dates[repCount] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dates[repCount] = picked);
    }
  }

  void _saveAll() {
    final userId = ref.read(maxesUserIdProvider);
    if (userId == null || userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your maxes.')),
      );
      return;
    }

    for (final repCount in _repCounts) {
      final w = double.tryParse(_controllers[repCount]!.text);
      if (w == null) continue;
      final existing = widget.maxes[repCount];
      final newMax = LiftMaxModel(
        id: existing?.id ?? const Uuid().v4(),
        userId: userId,
        exerciseId: widget.exercise.id,
        repCount: repCount,
        weight: w,
        withStraps: existing?.withStraps ?? false,
        updatedAt: _dates[repCount] ?? DateTime.now(),
      );
      ref.read(maxesControllerProvider.notifier).saveMax(newMax);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            widget.exercise.name,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          for (final repCount in _repCounts) ...[
            _RepMaxField(
              repCount: repCount,
              controller: _controllers[repCount]!,
              selectedDate: _dates[repCount],
              onPickDate: () => _pickDate(repCount),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saveAll,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual rep-max field inside the sheet
// ---------------------------------------------------------------------------

class _RepMaxField extends StatelessWidget {
  const _RepMaxField({
    required this.repCount,
    required this.controller,
    required this.selectedDate,
    required this.onPickDate,
  });

  final int repCount;
  final TextEditingController controller;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Rep label
        SizedBox(
          width: 52,
          child: Text(
            '${repCount}RM',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
          ),
        ),
        // Weight input
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Weight (lbs)',
              suffixText: 'lbs',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Date chip
        GestureDetector(
          onTap: onPickDate,
          child: Chip(
            avatar: Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
            label: Text(
              selectedDate != null
                  ? DateFormat.MMMd().format(selectedDate!)
                  : 'Date',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
