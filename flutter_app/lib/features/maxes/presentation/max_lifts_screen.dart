import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme.dart';
import '../../../domain/models/exercise_definitions.dart';
import '../../../domain/models/lift_max_model.dart';
import '../providers.dart';

class MaxLiftsScreen extends ConsumerStatefulWidget {
  const MaxLiftsScreen({super.key});

  @override
  ConsumerState<MaxLiftsScreen> createState() => _MaxLiftsScreenState();
}

class _MaxLiftsScreenState extends ConsumerState<MaxLiftsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxesAsync = ref.watch(liftMaxesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Bests'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ),
      body: maxesAsync.when(
        data: (maxes) {
          final mappedMaxes = _groupMaxes(maxes);
          final categories = _groupExercisesByCategory(_searchQuery);

          if (categories.isEmpty) {
            return const Center(child: Text('No exercises found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: categories.keys.length,
            itemBuilder: (context, index) {
              final category = categories.keys.elementAt(index);
              final exercises = categories[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, top: 24, bottom: 8),
                    child: Text(
                      category.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.brandSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  for (final exercise in exercises)
                    _ExerciseMaxCard(
                      exercise: exercise,
                      maxes: mappedMaxes[exercise.id] ?? {},
                    )
                ],
              );
            },
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

  Map<String, List<ExerciseDefinition>> _groupExercisesByCategory(
      String query) {
    final grouped = <String, List<ExerciseDefinition>>{};
    final filtered = Exercises.all.where((e) =>
        e.name.toLowerCase().contains(query.toLowerCase()) ||
        e.category.toLowerCase().contains(query.toLowerCase()));

    for (final exercise in filtered) {
      if (!grouped.containsKey(exercise.category)) {
        grouped[exercise.category] = [];
      }
      grouped[exercise.category]!.add(exercise);
    }
    return grouped;
  }
}

class _ExerciseMaxCard extends StatefulWidget {
  const _ExerciseMaxCard({required this.exercise, required this.maxes});

  final ExerciseDefinition exercise;
  final Map<int, LiftMaxModel> maxes;

  @override
  State<_ExerciseMaxCard> createState() => _ExerciseMaxCardState();
}

class _ExerciseMaxCardState extends State<_ExerciseMaxCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasAnyMax = widget.maxes.isNotEmpty;
    final isJump = widget.exercise.category == 'Plyometrics';
    final bestMax = widget.maxes[1] ?? widget.maxes[3] ?? widget.maxes[5];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForCategory(widget.exercise.category),
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exercise.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (hasAnyMax && bestMax != null)
                            Text(
                              isJump
                                  ? 'Best: ${bestMax.weight} in'
                                  : 'Best: ${bestMax.weight} lbs (${bestMax.repCount}RM)',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            Text(
                              'No data logged',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    if (isJump)
                      _RepMaxInputRow(
                        exercise: widget.exercise,
                        repCount: 1,
                        currentMax: widget.maxes[1],
                        isJump: true,
                      )
                    else ...[
                      _RepMaxInputRow(
                          exercise: widget.exercise,
                          repCount: 1,
                          currentMax: widget.maxes[1]),
                      _RepMaxInputRow(
                          exercise: widget.exercise,
                          repCount: 3,
                          currentMax: widget.maxes[3]),
                      _RepMaxInputRow(
                          exercise: widget.exercise,
                          repCount: 5,
                          currentMax: widget.maxes[5]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    if (category.contains('Squat')) return Icons.fitness_center;
    if (category.contains('Bench')) return Icons.horizontal_rule;
    if (category.contains('Deadlift') || category.contains('Hinge')) {
      return Icons.vertical_align_bottom;
    }
    if (category.contains('Olympic')) return Icons.flash_on;
    if (category.contains('Overhead')) return Icons.upload;
    if (category.contains('Plyometrics')) return Icons.rocket_launch;
    return Icons.accessibility_new;
  }
}

class _RepMaxInputRow extends ConsumerStatefulWidget {
  const _RepMaxInputRow({
    required this.exercise,
    required this.repCount,
    this.currentMax,
    this.isJump = false,
  });

  final ExerciseDefinition exercise;
  final int repCount;
  final LiftMaxModel? currentMax;
  final bool isJump;

  @override
  ConsumerState<_RepMaxInputRow> createState() => _RepMaxInputRowState();
}

class _RepMaxInputRowState extends ConsumerState<_RepMaxInputRow> {
  late TextEditingController _weightCtrl;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl =
        TextEditingController(text: widget.currentMax?.weight.toString() ?? '');
    _selectedDate = widget.currentMax?.updatedAt;
  }

  @override
  void didUpdateWidget(_RepMaxInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMax?.weight != oldWidget.currentMax?.weight) {
      _weightCtrl.text = widget.currentMax?.weight.toString() ?? '';
    }
    if (widget.currentMax?.updatedAt != oldWidget.currentMax?.updatedAt) {
      _selectedDate = widget.currentMax?.updatedAt;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _save();
    }
  }

  void _save() async {
    final wString = _weightCtrl.text.trim();
    if (wString.isEmpty) return;

    final w = double.tryParse(wString);
    if (w == null) return;

    final userId = ref.read(maxesUserIdProvider);
    if (userId == null || userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your maxes.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newMax = LiftMaxModel(
      id: widget.currentMax?.id ?? const Uuid().v4(),
      userId: userId,
      exerciseId: widget.exercise.id,
      repCount: widget.repCount,
      weight: w,
      withStraps: widget.currentMax?.withStraps ?? false,
      updatedAt: _selectedDate ?? DateTime.now(),
    );

    try {
      await ref.read(maxesControllerProvider.notifier).saveMax(newMax);
      if (mounted) {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.isJump ? 'BEST' : '${widget.repCount} RM',
              style: TextStyle(
                color: AppColors.brandSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.isJump ? 'Distance' : 'Weight',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixText: widget.isJump ? 'in' : 'lbs',
                fillColor: AppColors.surfaceLight,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              onSubmitted: (_) {
                _save();
              },
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.brandPrimary),
                  Text(
                    _selectedDate != null
                        ? DateFormat('MM/dd').format(_selectedDate!)
                        : 'Date',
                    style: TextStyle(
                      fontSize: 10,
                      color: _selectedDate != null
                          ? AppColors.brandPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            const SizedBox(
              width: 32,
              height: 32,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: AppColors.brandPrimary),
              onPressed: _save,
              tooltip: 'Save',
            ),
        ],
      ),
    );
  }
}
