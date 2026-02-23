import '../models/exercise_definitions.dart';
import '../models/injury_profile_model.dart';
import '../models/program_models.dart';

/// Pure-domain engine that adapts a [ProgramV2] for active injuries.
///
/// Responsibilities:
/// 1. Replace contraindicated exercises with pattern-equivalent alternatives.
/// 2. Inject targeted recovery-prep blocks into every session.
/// 3. Return the original program unchanged (same reference) when no injuries
///    are present (no-op fast-path).
///
/// Immutability contract: this engine never mutates its inputs. All adapted
/// objects are new instances, following the CycleProgramGenerator._copyProgram
/// pattern.
class InjuryAdaptationEngine {
  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Adapts [baseProgram] for the given [activeInjuries].
  ///
  /// Returns [baseProgram] unchanged (same reference) when [activeInjuries] is
  /// empty — zero allocation fast path.
  static ProgramV2 adaptProgram({
    required ProgramV2 baseProgram,
    required List<InjuryProfileModel> activeInjuries,
  }) {
    if (activeInjuries.isEmpty) {
      return baseProgram;
    }

    final List<ProgramWeek> adaptedWeeks = baseProgram.weeks
        .map((ProgramWeek week) => _adaptWeek(week, activeInjuries))
        .toList();

    return ProgramV2(
      id: baseProgram.id,
      name: baseProgram.name,
      category: baseProgram.category,
      description: baseProgram.description,
      durationWeeks: baseProgram.durationWeeks,
      sessionsPerWeek: baseProgram.sessionsPerWeek,
      difficulty: baseProgram.difficulty,
      phases: baseProgram.phases,
      weeks: adaptedWeeks,
      cycleAdjustmentProfile: baseProgram.cycleAdjustmentProfile,
    );
  }

  // -------------------------------------------------------------------------
  // Private — week / session / exercise adaptation
  // -------------------------------------------------------------------------

  static ProgramWeek _adaptWeek(
    ProgramWeek week,
    List<InjuryProfileModel> injuries,
  ) {
    return ProgramWeek(
      week: week.week,
      phaseId: week.phaseId,
      isTestWeek: week.isTestWeek,
      sessions: week.sessions
          .map((ProgramSession s) => _adaptSession(s, injuries))
          .toList(),
    );
  }

  static ProgramSession _adaptSession(
    ProgramSession session,
    List<InjuryProfileModel> injuries,
  ) {
    final List<ProgramExercise> adaptedExercises = session.exercises
        .map((ProgramExercise ex) => _adaptExercise(ex, injuries))
        .toList();

    final List<ProgramExercise> recoveryPrep = _buildRecoveryPrepBlock(injuries);

    return ProgramSession(
      sessionId: session.sessionId,
      sessionName: session.sessionName,
      sessionType: session.sessionType,
      focus: session.focus,
      exercises: adaptedExercises,
      recoveryPrepExercises: recoveryPrep,
    );
  }

  static ProgramExercise _adaptExercise(
    ProgramExercise ex,
    List<InjuryProfileModel> injuries,
  ) {
    if (!_isContraindicated(ex.exercise, injuries)) {
      return ex;
    }

    final _ReplacementResult replacement = _findReplacement(ex.exercise, injuries);
    return ProgramExercise(
      exercise: replacement.exerciseName,
      variant: ex.variant,
      sets: ex.sets,
      reps: ex.reps,
      percent1Rm: ex.percent1Rm,
      restMinutes: ex.restMinutes,
      notes: ex.notes,
      injuryReplacedOriginal: ex.exercise,
      injuryReplacementReason: replacement.reason,
      isContraindicatedOriginal: false,
    );
  }

  // -------------------------------------------------------------------------
  // Private — contraindication logic
  // -------------------------------------------------------------------------

  /// Contraindication map: injury location keyword → set of
  /// contraindicated categories or muscle group keywords.
  ///
  /// Matching rules:
  /// - Location matching is case-insensitive contains check on
  ///   [InjuryProfileModel.location].
  /// - An exercise is contraindicated if ANY active injury matches it.
  static const Map<String, _ContraindicationRule> _contraindicationRules =
      <String, _ContraindicationRule>{
    'knee': _ContraindicationRule(
      categories: <String>['Squat Variations'],
      muscleGroupKeywords: <String>['quads'],
    ),
    'shoulder': _ContraindicationRule(
      categories: <String>[
        'Overhead Pressing',
        'Bench Press Variations',
      ],
      muscleGroupKeywords: <String>['shoulders'],
    ),
    'back': _ContraindicationRule(
      categories: <String>['Hinge Variations', 'Deadlift Variations'],
      muscleGroupKeywords: <String>['back'],
    ),
    'spine': _ContraindicationRule(
      categories: <String>['Hinge Variations', 'Deadlift Variations'],
      muscleGroupKeywords: <String>['back'],
    ),
    'hip': _ContraindicationRule(
      categories: <String>[],
      muscleGroupKeywords: <String>['glutes', 'hamstrings'],
    ),
  };

  /// Lazy O(1) lookup map: exercise id → [ExerciseDefinition].
  static Map<String, ExerciseDefinition>? _exerciseMap;

  static Map<String, ExerciseDefinition> get _exercises {
    _exerciseMap ??= <String, ExerciseDefinition>{
      for (final ExerciseDefinition def in Exercises.all) def.id: def,
    };
    return _exerciseMap!;
  }

  static bool _isContraindicated(
    String exerciseId,
    List<InjuryProfileModel> injuries,
  ) {
    final ExerciseDefinition? def = _exercises[exerciseId];
    if (def == null) return false;

    for (final InjuryProfileModel injury in injuries) {
      final String loc = injury.location.toLowerCase();
      for (final MapEntry<String, _ContraindicationRule> entry
          in _contraindicationRules.entries) {
        if (!loc.contains(entry.key)) continue;
        final _ContraindicationRule rule = entry.value;
        if (rule.categories.contains(def.category)) return true;
        for (final String keyword in rule.muscleGroupKeywords) {
          if (def.muscleGroups.any(
            (String mg) => mg.toLowerCase().contains(keyword),
          )) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Private — replacement logic
  // -------------------------------------------------------------------------

  /// Static regression table for primary lifts.
  /// Values are ordered by preference. Engine checks that each candidate
  /// exists in [Exercises.all] before using it.
  static const Map<String, List<String>> _regressionTable =
      <String, List<String>>{
    'Back Squat': <String>['Goblet Squat', 'Air Squats', 'Leg Press'],
    'Front Squat': <String>['Goblet Squat', 'Air Squats'],
    'Conventional Deadlift (No Straps)': <String>[
      'Romanian Deadlift / RDL (No Straps)',
      'Trap Bar / Hex Bar Deadlift (No Straps)',
    ],
    'Flat Barbell Bench Press': <String>[
      'Dumbbell Bench Press',
      'Floor Press',
    ],
    'Strict Press / Military Press': <String>[
      'Lateral Raises',
      'Z-Press',
    ],
  };

  static _ReplacementResult _findReplacement(
    String exerciseId,
    List<InjuryProfileModel> injuries,
  ) {
    final String injuryLocations = injuries
        .map((InjuryProfileModel i) => i.location)
        .join(', ');

    // Priority 3: Static regression table
    final List<String>? regressions = _regressionTable[exerciseId];
    if (regressions != null) {
      for (final String candidate in regressions) {
        if (_exercises.containsKey(candidate)) {
          return _ReplacementResult(
            exerciseName: candidate,
            reason:
                'Replaced — $injuryLocations injury limits $exerciseId. Using $candidate instead.',
          );
        }
      }
    }

    // Priority 1+2: Same category / overlapping muscle groups
    final ExerciseDefinition? original = _exercises[exerciseId];
    if (original != null) {
      // Priority 1: Same category + overlapping muscle group
      for (final ExerciseDefinition candidate in Exercises.all) {
        if (candidate.id == exerciseId) continue;
        if (_isContraindicated(candidate.id, injuries)) continue;
        if (candidate.category == original.category &&
            candidate.muscleGroups.any(
              (String mg) => original.muscleGroups.contains(mg),
            )) {
          return _ReplacementResult(
            exerciseName: candidate.id,
            reason:
                'Replaced — $injuryLocations injury limits $exerciseId. Using ${candidate.id} instead.',
          );
        }
      }

      // Priority 2: Same category, any muscle emphasis
      for (final ExerciseDefinition candidate in Exercises.all) {
        if (candidate.id == exerciseId) continue;
        if (_isContraindicated(candidate.id, injuries)) continue;
        if (candidate.category == original.category) {
          return _ReplacementResult(
            exerciseName: candidate.id,
            reason:
                'Replaced — $injuryLocations injury limits $exerciseId. Using ${candidate.id} instead.',
          );
        }
      }
    }

    // Priority 4: Bodyweight regression from safe set
    const List<String> safeBodyweight = <String>[
      'Air Squats',
      'Bird-Dogs',
      'Bodyweight Lunges',
    ];
    for (final String safe in safeBodyweight) {
      if (_exercises.containsKey(safe) &&
          !_isContraindicated(safe, injuries)) {
        return _ReplacementResult(
          exerciseName: safe,
          reason:
              'Replaced — $injuryLocations injury limits $exerciseId. Using $safe instead.',
        );
      }
    }

    // Priority 5: Annotated placeholder
    return _ReplacementResult(
      exerciseName: exerciseId,
      reason:
          'Replaced — $injuryLocations injury limits $exerciseId. Consult coach — no safe automatic replacement found.',
    );
  }

  // -------------------------------------------------------------------------
  // Private — recovery prep injection
  // -------------------------------------------------------------------------

  /// Recovery prep exercises by injury location keyword.
  /// Each entry is an exercise ID from [Exercises.all].
  static const Map<String, List<String>> _recoveryPrepMap =
      <String, List<String>>{
    'knee': <String>['Bird-Dogs', 'Bodyweight Lunges'],
    'shoulder': <String>['Banded Pull-Aparts', 'Face Pulls'],
    'back': <String>['Bird-Dogs', 'Bodyweight Lunges'],
    'spine': <String>['Bird-Dogs'],
    'hip': <String>['Bodyweight Lunges', 'Bird-Dogs'],
  };

  static const String _generalRecoveryExercise = 'Bird-Dogs';

  static List<ProgramExercise> _buildRecoveryPrepBlock(
    List<InjuryProfileModel> injuries,
  ) {
    final List<String> exerciseIds = <String>[];

    for (final InjuryProfileModel injury in injuries) {
      final String loc = injury.location.toLowerCase();
      bool matched = false;
      for (final MapEntry<String, List<String>> entry
          in _recoveryPrepMap.entries) {
        if (loc.contains(entry.key)) {
          for (final String id in entry.value) {
            if (!exerciseIds.contains(id)) {
              exerciseIds.add(id);
            }
          }
          matched = true;
        }
      }
      if (!matched && !exerciseIds.contains(_generalRecoveryExercise)) {
        exerciseIds.add(_generalRecoveryExercise);
      }
    }

    // Cap at 5
    final List<String> capped = exerciseIds.take(5).toList();

    return capped
        .where((String id) => _exercises.containsKey(id))
        .map((String id) {
      final ExerciseDefinition def = _exercises[id]!;
      return ProgramExercise(
        exercise: def.id,
        variant: null,
        sets: ExerciseValue.fixed(2),
        reps: ExerciseValue.range(8, 15),
        percent1Rm: null,
        restMinutes: 0.5,
        notes: 'Injury recovery prep — ${def.name}',
      );
    }).toList();
  }
}

// -------------------------------------------------------------------------
// Internal value types
// -------------------------------------------------------------------------

class _ContraindicationRule {
  const _ContraindicationRule({
    required this.categories,
    required this.muscleGroupKeywords,
  });

  final List<String> categories;
  final List<String> muscleGroupKeywords;
}

class _ReplacementResult {
  const _ReplacementResult({
    required this.exerciseName,
    required this.reason,
  });

  final String exerciseName;
  final String reason;
}
