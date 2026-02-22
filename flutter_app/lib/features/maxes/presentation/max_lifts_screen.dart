import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/exercise_definitions.dart';
import '../../../domain/models/lift_max_model.dart';
import '../providers.dart';

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

          return ListView.builder(
            itemCount: categories.keys.length,
            addAutomaticKeepAlives: true,
            itemBuilder: (context, index) {
              final category = categories.keys.elementAt(index);
              final exercises = categories[category]!;

              return ExpansionTile(
                title: Text(category, style: Theme.of(context).textTheme.titleLarge),
                children: [
                  for (final exercise in exercises)
                    _ExerciseMaxRow(
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

  Map<String, List<ExerciseDefinition>> _groupExercisesByCategory() {
    final grouped = <String, List<ExerciseDefinition>>{};
    for (final exercise in Exercises.all) {
      if (!grouped.containsKey(exercise.category)) {
        grouped[exercise.category] = [];
      }
      grouped[exercise.category]!.add(exercise);
    }
    return grouped;
  }
}

class _ExerciseMaxRow extends ConsumerWidget {
  const _ExerciseMaxRow({required this.exercise, required this.maxes});

  final ExerciseDefinition exercise;
  final Map<int, LiftMaxModel> maxes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _RepMaxInput(exercise: exercise, repCount: 1, currentMax: maxes[1]),
            _RepMaxInput(exercise: exercise, repCount: 3, currentMax: maxes[3]),
            _RepMaxInput(exercise: exercise, repCount: 5, currentMax: maxes[5]),
            _RepMaxInput(exercise: exercise, repCount: 10, currentMax: maxes[10]),
          ],
        ),
      ),
    );
  }
}

class _RepMaxInput extends ConsumerStatefulWidget {
  const _RepMaxInput({required this.exercise, required this.repCount, this.currentMax});

  final ExerciseDefinition exercise;
  final int repCount;
  final LiftMaxModel? currentMax;

  @override
  ConsumerState<_RepMaxInput> createState() => _RepMaxInputState();
}

class _RepMaxInputState extends ConsumerState<_RepMaxInput> {
  late TextEditingController _weightCtrl;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.currentMax?.weight.toString() ?? '');
    _selectedDate = widget.currentMax?.updatedAt;
  }

  @override
  void didUpdateWidget(_RepMaxInput oldWidget) {
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

  void _save() {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null) return;
    
    final userId = ref.read(maxesUserIdProvider);
    if (userId == null || userId == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your maxes.')),
      );
      return;
    }

    final newMax = LiftMaxModel(
      id: widget.currentMax?.id ?? const Uuid().v4(),
      userId: userId,
      exerciseId: widget.exercise.id,
      repCount: widget.repCount,
      weight: w,
      withStraps: widget.currentMax?.withStraps ?? false,
      updatedAt: _selectedDate ?? DateTime.now(),
    );
    
    ref.read(maxesControllerProvider.notifier).saveMax(newMax);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text('${widget.repCount} RM:'),
          ),
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Weight',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                FocusScope.of(context).unfocus();
                _save();
              },
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _selectedDate != null
                  ? DateFormat.yMd().format(_selectedDate!)
                  : 'Date',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _save();
            },
          )
        ],
      ),
    );
  }
}
