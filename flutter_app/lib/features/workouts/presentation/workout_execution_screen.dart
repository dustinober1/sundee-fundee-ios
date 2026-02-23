import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../domain/models/program_models.dart';
import '../../programs/data/program_repository.dart';
import 'workout_execution_providers.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  const WorkoutExecutionScreen({super.key});

  @override
  ConsumerState<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends ConsumerState<WorkoutExecutionScreen> {
  bool _initialized = false;
  late ProgramSession _session;
  late int _week;
  late int _day;
  late String _programId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initSession();
    }
  }

  void _initSession() {
    final enrollment = ref.read(activeEnrollmentProvider).asData?.value;
    final program = ref.read(activeProgramProvider).asData?.value;

    if (enrollment != null && program != null) {
      _programId = program.id;
      _week = enrollment.currentWeek;
      _day = enrollment.currentDay;

      final week = program.weeks.firstWhere(
        (w) => w.week == _week,
        orElse: () => program.weeks.last,
      );
      final sessionIndex = _day - 1;
      _session = sessionIndex < week.sessions.length
          ? week.sessions[sessionIndex]
          : week.sessions.last;

      // Defer state modification
      Future.microtask(() {
        ref.read(workoutExecutionNotifierProvider.notifier).initialize(_session);
      });
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final state = ref.watch(workoutExecutionNotifierProvider);
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_session.sessionName} (W$_week:D$_day)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
      ),
      body: state.isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _session.exercises.length,
              itemBuilder: (context, index) {
                final exercise = _session.exercises[index];
                return _ExerciseCard(
                  exercise: exercise,
                  setsState: state.exerciseSets[exercise.exercise] ?? [],
                );
              },
            ),
      floatingActionButton: state.isSaving
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _finishWorkout(context),
              label: const Text('Finish Workout'),
              icon: const Icon(Icons.check),
              backgroundColor: AppColors.brandPrimary,
            ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text('Are you sure you want to cancel this workout? Progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('RESUME'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      context.pop();
    }
  }

  Future<void> _finishWorkout(BuildContext context) async {
    try {
      await ref.read(workoutExecutionNotifierProvider.notifier).finishWorkout(
        _session,
        _week,
        _day,
        _programId,
      );
      if (context.mounted) {
        context.pop(); // Go back to dashboard
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save workout: $e')),
        );
      }
    }
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.setsState,
  });

  final ProgramExercise exercise;
  final List<SetExecutionState> setsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exercise,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
            ),
            if (exercise.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  exercise.notes!,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            const Row(
              children: [
                SizedBox(width: 32, child: Text('Set', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Center(child: Text('LBS', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Reps', style: TextStyle(fontWeight: FontWeight.bold)))),
                SizedBox(width: 48), // Checkbox area
              ],
            ),
            const Divider(),
            ...List.generate(setsState.length, (index) {
              return _SetRow(
                exerciseId: exercise.exercise,
                setIndex: index,
                state: setsState[index],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  const _SetRow({
    required this.exerciseId,
    required this.setIndex,
    required this.state,
  });

  final String exerciseId;
  final int setIndex;
  final SetExecutionState state;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.state.actualWeight > 0 ? widget.state.actualWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '',
    );
    _repsController = TextEditingController(
      text: widget.state.actualReps > 0 ? widget.state.actualReps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.actualWeight != widget.state.actualWeight && !widget.state.isCompleted) {
      _weightController.text = widget.state.actualWeight > 0 ? widget.state.actualWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '';
    }
    if (oldWidget.state.actualReps != widget.state.actualReps && !widget.state.isCompleted) {
      _repsController.text = widget.state.actualReps > 0 ? widget.state.actualReps.toString() : '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final w = double.tryParse(_weightController.text) ?? 0.0;
    final r = int.tryParse(_repsController.text) ?? 0;
    ref.read(workoutExecutionNotifierProvider.notifier).updateSet(
          widget.exerciseId,
          widget.setIndex,
          weight: w,
          reps: r,
        );
  }

  void _onToggleComplete(bool? val) {
    if (val == null) return;
    ref.read(workoutExecutionNotifierProvider.notifier).updateSet(
          widget.exerciseId,
          widget.setIndex,
          isCompleted: val,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.state.isCompleted;
    final rowColor = isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.transparent;

    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${widget.setIndex + 1}'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.state.prescribedWeight > 0 ? widget.state.prescribedWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '-',
                  filled: true,
                  fillColor: isCompleted ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (_) => _onChanged(),
                enabled: !isCompleted,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.state.prescribedReps > 0 ? widget.state.prescribedReps.toString() : '-',
                  filled: true,
                  fillColor: isCompleted ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: (_) => _onChanged(),
                enabled: !isCompleted,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onToggleComplete(!isCompleted),
            ),
          ),
        ],
      ),
    );
  }
}
