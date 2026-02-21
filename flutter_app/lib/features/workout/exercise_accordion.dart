import 'package:flutter/material.dart';
import '../../data/models/program_v2.dart';
import '../../data/models/workout_session_state.dart';
import 'set_input_widget.dart';

class ExerciseAccordion extends StatefulWidget {
  final List<ExerciseV2> exercises;
  final WorkoutSessionState? sessionState;
  final void Function(
          String exerciseId, int setNumber, double weight, int reps)
      onLogSet;

  const ExerciseAccordion({
    super.key,
    required this.exercises,
    required this.sessionState,
    required this.onLogSet,
  });

  @override
  State<ExerciseAccordion> createState() => _ExerciseAccordionState();
}

class _ExerciseAccordionState extends State<ExerciseAccordion> {
  int _expandedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      key: const Key('exercise-accordion'),
      expansionCallback: (index, isExpanded) {
        setState(() {
          _expandedIndex = isExpanded ? -1 : index;
        });
      },
      children: widget.exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final exercise = entry.value;
        final exerciseId = '${exercise.exercise}-$index';
        final setCount =
            exercise.sets is int ? exercise.sets as int : 3;
        final prescribedReps =
            exercise.reps is int ? exercise.reps as int : 5;

        int completedCount = 0;
        for (int s = 1; s <= setCount; s++) {
          if (widget.sessionState?.isSetCompleted(exerciseId, s) ??
              false) {
            completedCount++;
          }
        }

        return ExpansionPanel(
          headerBuilder: (context, isExpanded) => ListTile(
            key: Key('exercise-header-$index'),
            title: Text(exercise.exercise),
            subtitle: Text(
                '${exercise.setsDisplay} sets × ${exercise.repsDisplay} reps'),
            trailing: Text(
              '$completedCount/$setCount',
              style: TextStyle(
                color: completedCount == setCount
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: List.generate(setCount, (setIndex) {
                final setNumber = setIndex + 1;
                final isCompleted =
                    widget.sessionState?.isSetCompleted(exerciseId, setNumber) ??
                        false;
                return SetInputWidget(
                  key: Key('$exerciseId-set-$setNumber'),
                  setNumber: setNumber,
                  prescribedReps: prescribedReps,
                  isCompleted: isCompleted,
                  onLog: (weight, reps) =>
                      widget.onLogSet(exerciseId, setNumber, weight, reps),
                );
              }),
            ),
          ),
          isExpanded: _expandedIndex == index,
          canTapOnHeader: true,
        );
      }).toList(),
    );
  }
}
