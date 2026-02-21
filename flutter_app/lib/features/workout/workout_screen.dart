import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/program_v2.dart';
import '../../shared/providers/cycle_provider.dart';
import '../../shared/providers/program_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/rest_timer_provider.dart';
import '../../shared/providers/workout_session_provider.dart';
import 'exercise_accordion.dart';
import 'rest_timer_sheet.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String programId;

  const WorkoutScreen({super.key, required this.programId});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Session? _session;
  int _week = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final activeCycle = await ref.read(activeCycleProvider.future);
    final programs = await ref.read(programsProvider.future);

    ProgramV2? program;
    try {
      program = programs.firstWhere((p) => p.id == widget.programId);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final week = activeCycle?.currentWeek ?? 1;
    final sessionId = activeCycle?.currentSessionId;

    WeekV2? weekData;
    try {
      weekData = program.weeks.firstWhere((w) => w.week == week);
    } catch (_) {
      weekData = program.weeks.isNotEmpty ? program.weeks.first : null;
    }

    if (weekData == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    Session? session;
    if (sessionId != null) {
      try {
        session =
            weekData.sessions.firstWhere((s) => s.sessionId == sessionId);
      } catch (_) {
        session =
            weekData.sessions.isNotEmpty ? weekData.sessions.first : null;
      }
    } else {
      session =
          weekData.sessions.isNotEmpty ? weekData.sessions.first : null;
    }

    if (session == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    ref.read(workoutSessionProvider.notifier).startSession(
          programId: widget.programId,
          week: week,
          sessionId: session.sessionId,
          sessionName: session.sessionName,
        );

    if (mounted) {
      setState(() {
        _session = session;
        _week = week;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCompleteWorkout() async {
    final user = await ref.read(userProvider.future);
    final activeCycle = await ref.read(activeCycleProvider.future);

    if (user == null || activeCycle == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cannot complete: no active user or cycle')),
        );
      }
      return;
    }

    final workoutId = await ref
        .read(workoutSessionProvider.notifier)
        .completeWorkout(
          userId: user.id,
          activeCycleId: activeCycle.id,
        );

    if (workoutId != null && mounted) {
      context.go('/dashboard');
    }
  }

  Future<bool> _handleWillPop() async {
    final session = ref.read(workoutSessionProvider);
    if (session != null && session.completedSetCount > 0) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Workout?'),
          content: Text(
              'You have ${session.completedSetCount} logged set(s). Discard this workout?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard')),
          ],
        ),
      );
      if (shouldDiscard == true) {
        ref.read(workoutSessionProvider.notifier).cancelWorkout();
        return true;
      }
      return false;
    }
    ref.read(workoutSessionProvider.notifier).cancelWorkout();
    return true;
  }

  void _handleLogSet(
      String exerciseId, int setNumber, double weight, int reps) {
    ref.read(workoutSessionProvider.notifier).logSet(
          exerciseId: exerciseId,
          setNumber: setNumber,
          actualWeight: weight,
          prescribedReps: _getPrescribedReps(exerciseId),
          actualReps: reps,
        );

    // Auto-start rest timer after set
    final exerciseName = _getExerciseName(exerciseId);
    final restDuration = _getRestDuration(exerciseId);
    ref.read(restTimerProvider.notifier).startRest(restDuration, exerciseName);

    if (mounted) {
      RestTimerSheet.show(context);
    }
  }

  String? _getExerciseName(String exerciseId) {
    if (_session == null) return null;
    for (final ex in _session!.exercises) {
      if (exerciseId.startsWith(ex.exercise)) return ex.exercise;
    }
    return null;
  }

  int _getRestDuration(String exerciseId) {
    if (_session == null) return 180;
    for (final ex in _session!.exercises) {
      if (exerciseId.startsWith(ex.exercise)) {
        if (ex.restMinutes != null) return (ex.restMinutes! * 60).round();
      }
    }
    return 180; // 3-minute default
  }

  int _getPrescribedReps(String exerciseId) {
    if (_session == null) return 5;
    for (final ex in _session!.exercises) {
      if (exerciseId.startsWith(ex.exercise)) {
        if (ex.reps is int) return ex.reps as int;
        if (ex.reps is List && (ex.reps as List).isNotEmpty) {
          return (ex.reps as List).first as int;
        }
      }
    }
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(workoutSessionProvider);
    final timerState = ref.watch(restTimerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        final shouldPop = await _handleWillPop();
        if (!shouldPop || !mounted) return;
        router.go('/dashboard');
      },
      child: Scaffold(
        key: const Key('workout-screen'),
        appBar: AppBar(
          title: Text(_session?.sessionName ??
              widget.programId.replaceAll('-', ' ').toUpperCase()),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final router = GoRouter.of(context);
              final shouldPop = await _handleWillPop();
              if (!shouldPop || !mounted) return;
              router.go('/dashboard');
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _session == null
                ? const Center(child: Text('Session not found'))
                : Stack(
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Week $_week',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    if (_session!.focus != null)
                                      Text(_session!.focus!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                  ],
                                ),
                                Text(
                                    '${sessionState?.completedSetCount ?? 0} sets logged',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: ExerciseAccordion(
                                exercises: _session!.exercises,
                                sessionState: sessionState,
                                onLogSet: _handleLogSet,
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  key: const Key('complete-workout-button'),
                                  onPressed:
                                      (sessionState?.completedSetCount ?? 0) >
                                              0
                                          ? _handleCompleteWorkout
                                          : null,
                                  child: const Text('Complete Workout'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Rest timer pill — shows when sheet is dismissed but timer is active
                      if (!timerState.isIdle)
                        Positioned(
                          bottom: 80,
                          left: 16,
                          right: 16,
                          child: GestureDetector(
                            key: const Key('rest-timer-pill'),
                            onTap: () => RestTimerSheet.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    timerState.isComplete
                                        ? Icons.check_circle
                                        : Icons.timer,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timerState.isComplete
                                        ? 'Rest complete!'
                                        : 'Rest: ${timerState.displayTime}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.expand_less,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
