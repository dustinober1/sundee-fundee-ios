import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../domain/calculations/plate_calculation.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/exercise_definitions.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/providers.dart';
import '../../programs/data/program_repository.dart';
import '../../programs/providers/adapted_program_provider.dart';
import 'plate_calculator_dialog.dart';
import 'rest_timer_provider.dart';
import 'workout_execution_providers.dart';

class WorkoutExecutionScreen extends ConsumerStatefulWidget {
  const WorkoutExecutionScreen({super.key});

  @override
  ConsumerState<WorkoutExecutionScreen> createState() =>
      _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState
    extends ConsumerState<WorkoutExecutionScreen> {
  bool _initialized = false;
  int _initAttempts = 0;
  bool _updatePromptVisible = false;
  bool _hasDeferredUpdate = false;
  final Set<String> _handledUpdateSignatures = <String>{};
  String _sessionSignature = '';
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
    final program = ref.read(adaptedActiveProgramProvider).asData?.value;

    if (enrollment == null || program == null) {
      _initAttempts += 1;
      if (_initAttempts > 30) {
        _initialized = true;
        Future.microtask(() {
          if (mounted) {
            Navigator.of(context).maybePop();
          }
        });
      } else {
        Future<void>.delayed(const Duration(milliseconds: 16), () {
          if (mounted && !_initialized) {
            _initSession();
          }
        });
      }
      return;
    }

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
    _sessionSignature = _buildSessionSignature(_session);

    // Defer state modification
    Future.microtask(() {
      if (mounted) {
        ref
            .read(workoutExecutionNotifierProvider.notifier)
            .initialize(_session);
      }
    });
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeEnrollmentProvider);
    ref.listen<AsyncValue<ProgramV2?>>(
      adaptedActiveProgramProvider,
      (
        AsyncValue<ProgramV2?>? previous,
        AsyncValue<ProgramV2?> next,
      ) {
        _handleAdaptedProgramUpdate(next);
      },
    );

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final state = ref.watch(workoutExecutionNotifierProvider);
    if (state == null) {
      // If it hasn't initialized yet but we got a session, wait for next frame
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_session.sessionName} (W$_week:D$_day)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
          tooltip: 'Exit workout',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const PlateCalculatorDialog(),
            ),
            tooltip: 'Open plate calculator',
          ),
        ],
      ),
      body: state.isSaving
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView.builder(
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
                const Positioned(
                  bottom: 16,
                  left: 16,
                  child: _RestTimerDisplay(),
                ),
                if (_hasDeferredUpdate)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        'Cycle update deferred. Changes will apply next session.',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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

  void _handleAdaptedProgramUpdate(AsyncValue<ProgramV2?> next) {
    if (!_initialized || !mounted) {
      return;
    }

    final WorkoutExecutionState? workoutState = ref.read(
      workoutExecutionNotifierProvider,
    );
    if (workoutState == null) {
      return;
    }

    final ProgramV2? updatedProgram = next.asData?.value;
    if (updatedProgram == null) {
      return;
    }

    final ProgramSession latestSession =
        _resolveSessionFromProgram(updatedProgram);
    final String latestSignature = _buildSessionSignature(latestSession);
    if (latestSignature == _sessionSignature) {
      return;
    }
    if (_handledUpdateSignatures.contains(latestSignature)) {
      return;
    }
    if (!_hasMeaningfulPrescriptionChange(_session, latestSession)) {
      return;
    }

    final ProgramAdaptationContext adaptationContext = ref.read(
      programAdaptationContextProvider,
    );
    if (adaptationContext.autoApplyDuringWorkout) {
      _handledUpdateSignatures.add(latestSignature);
      _applySessionUpdate(latestSession, latestSignature);
      return;
    }

    _promptForPhaseUpdate(
      latestSession: latestSession,
      latestSignature: latestSignature,
    );
  }

  ProgramSession _resolveSessionFromProgram(ProgramV2 program) {
    final ProgramWeek week = program.weeks.firstWhere(
      (ProgramWeek item) => item.week == _week,
      orElse: () => program.weeks.last,
    );
    final int sessionIndex = _day - 1;
    return sessionIndex < week.sessions.length
        ? week.sessions[sessionIndex]
        : week.sessions.last;
  }

  String _buildSessionSignature(ProgramSession session) {
    final StringBuffer buffer = StringBuffer(session.sessionId);
    for (final ProgramExercise exercise in session.exercises) {
      buffer
        ..write('|')
        ..write(exercise.exercise)
        ..write(':')
        ..write(exercise.sets.displayString)
        ..write(':')
        ..write(exercise.reps.displayString)
        ..write(':')
        ..write((exercise.percent1Rm ?? 0).toStringAsFixed(3));
    }
    return buffer.toString();
  }

  bool _hasMeaningfulPrescriptionChange(
    ProgramSession previous,
    ProgramSession next,
  ) {
    if (previous.exercises.length != next.exercises.length) {
      return true;
    }

    for (int index = 0; index < previous.exercises.length; index += 1) {
      final ProgramExercise before = previous.exercises[index];
      final ProgramExercise after = next.exercises[index];
      if (before.exercise != after.exercise) {
        return true;
      }
      if (before.sets.displayString != after.sets.displayString) {
        return true;
      }
      if (before.reps.displayString != after.reps.displayString) {
        return true;
      }

      final double beforeLoad = before.percent1Rm ?? 0;
      final double afterLoad = after.percent1Rm ?? 0;
      if ((beforeLoad - afterLoad).abs() >= 0.01) {
        return true;
      }
    }

    return false;
  }

  Future<void> _promptForPhaseUpdate({
    required ProgramSession latestSession,
    required String latestSignature,
  }) async {
    if (_updatePromptVisible || !mounted) {
      return;
    }
    _updatePromptVisible = true;

    final bool applyNow = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Cycle Update Available'),
            content: const Text(
              'Your cycle phase changed during this workout. Apply updated '
              'prescriptions to remaining sets now, or defer to your next '
              'session.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('DEFER'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('APPLY'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) {
      return;
    }

    _handledUpdateSignatures.add(latestSignature);
    _updatePromptVisible = false;

    if (applyNow) {
      await _applySessionUpdate(latestSession, latestSignature);
      return;
    }

    setState(() {
      _hasDeferredUpdate = true;
    });
  }

  Future<void> _applySessionUpdate(
    ProgramSession latestSession,
    String latestSignature,
  ) async {
    await ref
        .read(workoutExecutionNotifierProvider.notifier)
        .applySessionPrescription(latestSession);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = latestSession;
      _sessionSignature = latestSignature;
      _hasDeferredUpdate = false;
    });
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text(
            'Are you sure you want to cancel this workout? Progress will not be saved.'),
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
    final displayName = Exercises.nameById(exercise.exercise);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary),
            ),
            if (exercise.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  exercise.notes!,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            const Row(
              children: [
                SizedBox(
                    width: 32,
                    child: Text('Set',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Center(
                        child: Text('LBS',
                            style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(
                    child: Center(
                        child: Text('Reps',
                            style: TextStyle(fontWeight: FontWeight.bold)))),
                SizedBox(
                    width: 40,
                    child: Center(
                        child: Text('RPE',
                            style: TextStyle(fontWeight: FontWeight.bold)))),
                SizedBox(width: 48), // Checkbox area
              ],
            ),
            const Divider(),
            ...List.generate(setsState.length, (index) {
              return _SetRow(
                exerciseId: exercise.exercise,
                setIndex: index,
                state: setsState[index],
                restSeconds: (exercise.restMinutes != null)
                    ? (exercise.restMinutes! * 60).round()
                    : null,
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
    this.restSeconds,
  });

  final String exerciseId;
  final int setIndex;
  final SetExecutionState state;
  final int? restSeconds;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _rpeController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.state.actualWeight > 0
          ? widget.state.actualWeight
              .toStringAsFixed(1)
              .replaceAll(RegExp(r'\.0$'), '')
          : '',
    );
    _repsController = TextEditingController(
      text:
          widget.state.actualReps > 0 ? widget.state.actualReps.toString() : '',
    );
    _rpeController = TextEditingController(
      text: widget.state.rpe != null ? widget.state.rpe.toString() : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final w = double.tryParse(_weightController.text) ?? 0.0;
    final r = int.tryParse(_repsController.text) ?? 0;
    final rpe = double.tryParse(_rpeController.text);
    ref.read(workoutExecutionNotifierProvider.notifier).updateSet(
          widget.exerciseId,
          widget.setIndex,
          weight: w,
          reps: r,
          rpe: rpe,
        );
  }

  void _onToggleComplete(bool? val) {
    if (val == null) return;
    ref.read(workoutExecutionNotifierProvider.notifier).updateSet(
          widget.exerciseId,
          widget.setIndex,
          isCompleted: val,
          restSeconds: widget.restSeconds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileStreamProvider).asData?.value;
    final double barbellWeight =
        (userProfile?.gender == Gender.male) ? 45.0 : 35.0;

    final isCompleted = widget.state.isCompleted;
    final rowColor =
        isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.transparent;

    final double currentWeight = double.tryParse(_weightController.text) ??
        widget.state.prescribedWeight;
    final Map<double, int> plateBreakdown = PlateCalculation.calculatePlates(
      totalWeight: currentWeight,
      barbellWeight: barbellWeight,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.state.prescribedWeight > 0
                          ? widget.state.prescribedWeight
                              .toStringAsFixed(1)
                              .replaceAll(RegExp(r'\.0$'), '')
                          : '-',
                      filled: true,
                      fillColor: isCompleted
                          ? Colors.transparent
                          : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (_) {
                      _onChanged();
                      setState(() {}); // Update plate breakdown
                    },
                    enabled: !isCompleted,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TextField(
                    controller: _rpeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '-',
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      fillColor: isCompleted
                          ? Colors.transparent
                          : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
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
                      hintText: widget.state.prescribedReps > 0
                          ? widget.state.prescribedReps.toString()
                          : '-',
                      filled: true,
                      fillColor: isCompleted
                          ? Colors.transparent
                          : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
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
                    isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _onToggleComplete(!isCompleted),
                  tooltip:
                      isCompleted ? 'Mark set incomplete' : 'Mark set complete',
                ),
              ),
            ],
          ),
        ),
        if (plateBreakdown.isNotEmpty && !isCompleted)
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 8),
            child: Wrap(
              spacing: 4,
              children: plateBreakdown.entries.map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${e.value}x${e.key.toString().replaceAll(RegExp(r'\.0$'), '')}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _RestTimerDisplay extends ConsumerWidget {
  const _RestTimerDisplay();

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isRunning) return const SizedBox.shrink();

    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              _formatTime(timerState.remainingSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(restTimerProvider.notifier).stopTimer();
              },
              tooltip: 'Stop rest timer',
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white70, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(restTimerProvider.notifier).addTime(30);
              },
              tooltip: 'Add 30 seconds',
            ),
          ],
        ),
      ),
    );
  }
}
