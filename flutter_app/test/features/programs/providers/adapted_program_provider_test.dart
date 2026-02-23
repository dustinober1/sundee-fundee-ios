import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_adaptation_policy.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';
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
}
