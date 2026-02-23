import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_adaptation_policy.dart';
import 'package:sundee_fundee_flutter/domain/calculations/injury_adaptation_engine.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/domain/models/program_models.dart';
import 'package:sundee_fundee_flutter/domain/models/user_model.dart';
import 'package:sundee_fundee_flutter/features/programs/providers/adapted_program_provider.dart';

ProgramV2 _program() {
  return ProgramV2(
    id: 'program-1',
    name: 'Program',
    category: 'Strength',
    description: 'desc',
    durationWeeks: 12,
    sessionsPerWeek: 3,
    difficulty: 'Intermediate',
    phases: const <ProgramPhase>[],
    weeks: <ProgramWeek>[
      ProgramWeek(
        week: 1,
        phaseId: null,
        isTestWeek: false,
        sessions: <ProgramSession>[
          ProgramSession(
            sessionId: 'session-heavy',
            sessionName: 'Session C',
            sessionType: 'Lift',
            focus: 'Sundee-Fundee - Volume',
            exercises: <ProgramExercise>[
              ProgramExercise(
                exercise: 'Back Squat',
                variant: null,
                sets: ExerciseValue.fixed(4),
                reps: ExerciseValue.fixed(5),
                percent1Rm: 0.8,
                restMinutes: 3,
                notes: null,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

UserModel _user({required Gender gender, required bool cycleTrackingEnabled}) {
  return UserModel(
    id: 'user-1',
    name: 'Test User',
    experienceLevel: ExperienceLevel.intermediate,
    primaryGoal: PrimaryGoal.strength,
    gender: gender,
    createdAt: DateTime.utc(2026, 1, 1),
    appleUserId: 'apple-user',
    cycleTrackingEnabled: cycleTrackingEnabled,
  );
}

InjuryProfileModel _kneeInjury() {
  return InjuryProfileModel(
    id: 'injury-knee-1',
    location: 'knee',
    movementLimitations: 'Cannot perform deep knee flexion or high-load squats',
    recoveryGoal: 'Restore full range of motion without pain',
    status: InjuryStatus.active,
    createdAt: DateTime.utc(2026, 1, 15),
    updatedAt: DateTime.utc(2026, 1, 15),
  );
}

InjuryProfileModel _shoulderInjury() {
  return InjuryProfileModel(
    id: 'injury-shoulder-1',
    location: 'shoulder',
    movementLimitations: 'Pain with overhead pressing movements',
    recoveryGoal: 'Restore overhead mobility and pressing strength',
    status: InjuryStatus.active,
    createdAt: DateTime.utc(2026, 1, 20),
    updatedAt: DateTime.utc(2026, 1, 20),
  );
}

void main() {
  test('eligible female users receive adapted active program', () {
    final ProgramV2? adapted = buildAdaptedProgramView(
      baseProgram: _program(),
      profile: _user(gender: Gender.female, cycleTrackingEnabled: true),
      preferences: const CycleAdaptationPreferencesModel(
        id: 'programAdaptation',
        userId: 'user-1',
        enabled: true,
      ),
      currentPhase: CyclePhase.ovulation,
      lastKnownPhase: CyclePhase.follicular,
      confidence: AdaptationConfidence.high,
    );

    expect(adapted, isNotNull);
    final double adaptedLoad =
        adapted!.weeks.first.sessions.first.exercises.first.percent1Rm!;
    expect(adaptedLoad, greaterThan(0.8));
    expect(adapted.id, 'program-1');
  });

  test('non-female users receive unchanged base program', () {
    final ProgramV2? adapted = buildAdaptedProgramView(
      baseProgram: _program(),
      profile: _user(gender: Gender.male, cycleTrackingEnabled: false),
      preferences: const CycleAdaptationPreferencesModel(
        id: 'programAdaptation',
        userId: 'user-1',
        enabled: true,
      ),
      currentPhase: CyclePhase.ovulation,
      lastKnownPhase: CyclePhase.follicular,
      confidence: AdaptationConfidence.high,
    );

    expect(adapted, isNotNull);
    expect(
      adapted!.weeks.first.sessions.first.exercises.first.percent1Rm,
      closeTo(0.8, 0.0001),
    );
  });

  test('disabled adaptation preference returns base program', () {
    final ProgramV2? adapted = buildAdaptedProgramView(
      baseProgram: _program(),
      profile: _user(gender: Gender.female, cycleTrackingEnabled: true),
      preferences: const CycleAdaptationPreferencesModel(
        id: 'programAdaptation',
        userId: 'user-1',
        enabled: false,
      ),
      currentPhase: CyclePhase.ovulation,
      lastKnownPhase: CyclePhase.follicular,
      confidence: AdaptationConfidence.high,
    );

    expect(adapted, isNotNull);
    expect(
      adapted!.weeks.first.sessions.first.exercises.first.percent1Rm,
      closeTo(0.8, 0.0001),
    );
  });

  group('InjuryAdaptation', () {
    test('returns base program when no active injuries', () {
      final ProgramV2 base = _program();
      final ProgramV2 result = InjuryAdaptationEngine.adaptProgram(
        baseProgram: base,
        activeInjuries: const <InjuryProfileModel>[],
      );

      // Same reference — no-op fast-path
      expect(identical(result, base), isTrue);
    });

    test('replaces contraindicated exercise when knee injury active', () {
      final ProgramV2 base = _program(); // has Back Squat
      final ProgramV2 adapted = InjuryAdaptationEngine.adaptProgram(
        baseProgram: base,
        activeInjuries: <InjuryProfileModel>[_kneeInjury()],
      );

      final ProgramExercise ex =
          adapted.weeks.first.sessions.first.exercises.first;
      // Back Squat is contraindicated for knee injuries — should be replaced
      expect(ex.exercise, isNot('Back Squat'));
      // Original exercise name is recorded in the replacement field
      expect(ex.injuryReplacedOriginal, equals('Back Squat'));
      // Per 06-01 decision: engine always sets isContraindicatedOriginal = false;
      // only user revert sets it to true.
      expect(ex.isContraindicatedOriginal, isFalse);
    });

    test('adds recovery prep to sessions when injury active', () {
      final ProgramV2 adapted = InjuryAdaptationEngine.adaptProgram(
        baseProgram: _program(),
        activeInjuries: <InjuryProfileModel>[_kneeInjury()],
      );

      final ProgramSession session = adapted.weeks.first.sessions.first;
      expect(session.recoveryPrepExercises, isNotEmpty);
    });

    test('adds shoulder-specific recovery prep when shoulder injury active', () {
      final ProgramV2 adapted = InjuryAdaptationEngine.adaptProgram(
        baseProgram: _program(),
        activeInjuries: <InjuryProfileModel>[_shoulderInjury()],
      );

      final ProgramSession session = adapted.weeks.first.sessions.first;
      expect(session.recoveryPrepExercises, isNotEmpty);
      // Shoulder-specific exercises injected
      final List<String> prepNames = session.recoveryPrepExercises
          .map((ProgramExercise e) => e.exercise)
          .toList();
      expect(
        prepNames.any(
          (String name) =>
              name.contains('Pull-Apart') || name.contains('Face Pull'),
        ),
        isTrue,
      );
    });

    test('injury adaptation composes on top of cycle adaptation', () {
      // Step 1: apply cycle adaptation layer
      final ProgramV2 cycleAdapted = buildAdaptedProgramView(
        baseProgram: _program(),
        profile: _user(gender: Gender.female, cycleTrackingEnabled: true),
        preferences: const CycleAdaptationPreferencesModel(
          id: 'programAdaptation',
          userId: 'user-1',
          enabled: true,
        ),
        currentPhase: CyclePhase.ovulation,
        lastKnownPhase: CyclePhase.follicular,
        confidence: AdaptationConfidence.high,
      )!;

      // Cycle layer should have scaled load up (ovulation phase)
      final double cycleScaledLoad =
          cycleAdapted.weeks.first.sessions.first.exercises.first.percent1Rm!;
      expect(cycleScaledLoad, greaterThan(0.8));

      // Step 2: apply injury adaptation layer on top
      final ProgramV2 bothAdapted = InjuryAdaptationEngine.adaptProgram(
        baseProgram: cycleAdapted,
        activeInjuries: <InjuryProfileModel>[_kneeInjury()],
      );

      // Both layers applied: exercise replaced (injury layer) AND load was
      // cycle-scaled (cycle layer recorded in injuryReplacedOriginal field)
      final ProgramExercise ex =
          bothAdapted.weeks.first.sessions.first.exercises.first;
      expect(ex.injuryReplacedOriginal, equals('Back Squat'));
      // Per 06-01 decision: engine always sets isContraindicatedOriginal = false
      expect(ex.isContraindicatedOriginal, isFalse);
      // The replacement exercise still carries the cycle-scaled percent1Rm
      expect(ex.percent1Rm, closeTo(cycleScaledLoad, 0.0001));

      // Recovery prep injected
      expect(
        bothAdapted.weeks.first.sessions.first.recoveryPrepExercises,
        isNotEmpty,
      );
    });
  });
}
