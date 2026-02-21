import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';

import 'package:sundee_fundee/app.dart';
import 'package:sundee_fundee/data/database/app_database.dart';
import 'package:sundee_fundee/data/repositories/workout_repository.dart';
import 'package:sundee_fundee/shared/providers/database_provider.dart';
import 'package:sundee_fundee/shared/providers/onboarding_status_provider.dart';
import 'package:sundee_fundee/core/recommendations/calculations.dart';
import 'package:sundee_fundee/core/recommendations/plateau_detection.dart';

import '../helpers/test_database.dart';
import '../helpers/fake_connectivity.dart';
import '../helpers/app_helper.dart';

late FakeConnectivityPlatform fakeConnectivity;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CHRT-01: Progress screen renders all 3 chart sections', () {
    testWidgets('progress screen shows 1RM chart, volume chart, and heatmap',
        (tester) async {
      // Use app_helper to pump app and complete onboarding
      await pumpApp(tester);
      await completeOnboarding(tester);

      // Navigate to Progress tab using correct Key
      final progressTab = find.byKey(const Key('nav-progress'));
      expect(progressTab, findsOneWidget);
      await tester.tap(progressTab);
      await tester.pumpAndSettle();

      // Verify progress screen and chart containers present
      // Keys are on outer widgets that ALWAYS render (even with no data)
      expect(find.byKey(const Key('progress-screen')), findsOneWidget);
      expect(find.byKey(const Key('one-rm-chart')), findsOneWidget);
      expect(find.byKey(const Key('weekly-volume-chart')), findsOneWidget);
      expect(find.byKey(const Key('workout-heatmap')), findsOneWidget);
    });
  });

  group('CHRT-02: Progress screen loads from local Drift while offline', () {
    setUp(() {
      fakeConnectivity = FakeConnectivityPlatform();
      ConnectivityPlatform.instance = fakeConnectivity;
    });

    tearDown(() {
      fakeConnectivity.dispose();
    });

    testWidgets('progress data renders without network connectivity',
        (tester) async {
      final db = await createTestDatabase();

      // Seed user + workout data
      final userId = await db.into(db.users).insert(UsersCompanion.insert(
            name: 'Offline User',
            experienceLevel: 'intermediate',
            goal: 'strength',
          ));

      final cycleId =
          await db.into(db.activeCycles).insert(ActiveCyclesCompanion.insert(
                userId: userId,
                programId: 'back-squat',
                cycleName: 'Test Cycle',
                startDate: DateTime.now(),
              ));

      final workoutId = await db
          .into(db.completedWorkouts)
          .insert(CompletedWorkoutsCompanion.insert(
            userId: userId,
            activeCycleId: cycleId,
            programId: 'back-squat',
            week: 1,
            completedAt: DateTime.now(),
          ));

      await db.into(db.completedSets).insert(CompletedSetsCompanion.insert(
            workoutId: workoutId,
            exerciseId: 'back-squat',
            setNumber: 1,
            actualWeight: 135,
            prescribedReps: 5,
            actualReps: 5,
            createdAt: DateTime.now(),
          ));

      // Force offline using goOffline() method
      fakeConnectivity.goOffline();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            onboardingCompleteProvider
                .overrideWith(() => OnboardingStatusNotifier(initialState: true)),
          ],
          child: const SundeeFundeeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Progress using correct Key
      await tester.tap(find.byKey(const Key('nav-progress')));
      await tester.pumpAndSettle();

      // Should still render (local data only, no network needed)
      expect(find.byKey(const Key('progress-screen')), findsOneWidget);
      expect(find.byKey(const Key('one-rm-chart')), findsOneWidget);

      await db.close();
    });
  });

  group('RECO-01: Weight recommendation follows v1.1 logic', () {
    test('getNextRecommendedWeight returns +5 on success', () {
      // Current weight 135, success → 140
      final result = getNextRecommendedWeight(135, SessionResult.success, 200);
      expect(result, equals(140));
    });

    test('getNextRecommendedWeight returns -5 on failure with floor', () {
      // Current weight 135, failure, 1RM 200 → floor is 100 (50%)
      final result = getNextRecommendedWeight(135, SessionResult.failure, 200);
      expect(result, equals(130));

      // Near floor: current 105, failure, 1RM 200 → floor is 100
      final nearFloor = getNextRecommendedWeight(105, SessionResult.failure, 200);
      expect(nearFloor, equals(100)); // 105-5=100, which equals floor
    });

    test('getNextRecommendedWeight returns 70% of 1RM for first session', () {
      // First session, 1RM 200 → 140 (70%)
      final result = getNextRecommendedWeight(0, SessionResult.first, 200);
      expect(result, equals(140));
    });

    test('epley caps reps at 10', () {
      // 135 lbs × 10 reps = 135 × (1 + 10/30) = 135 × 1.333 = 180
      final tenReps = epley(135, 10);
      expect(tenReps, closeTo(180, 0.1));

      // 135 lbs × 15 reps should equal 10 reps (capped)
      final fifteenReps = epley(135, 15);
      expect(fifteenReps, equals(tenReps));
    });

    test('roundToNearestFive rounds correctly', () {
      expect(roundToNearestFive(137), equals(135));
      expect(roundToNearestFive(138), equals(140));
      expect(roundToNearestFive(142.5), equals(145));
      expect(roundToNearestFive(142.4), equals(140));
    });

    test('wasSetSuccessful checks reps and weight', () {
      // Successful: met reps and weight
      expect(
          wasSetSuccessful(
            actualReps: 5,
            prescribedReps: 5,
            actualWeight: 135,
            prescribedWeight: 135,
          ),
          isTrue);

      // Failed: missed reps
      expect(
          wasSetSuccessful(
            actualReps: 4,
            prescribedReps: 5,
            actualWeight: 135,
            prescribedWeight: 135,
          ),
          isFalse);

      // Failed: reduced weight
      expect(
          wasSetSuccessful(
            actualReps: 5,
            prescribedReps: 5,
            actualWeight: 130,
            prescribedWeight: 135,
          ),
          isFalse);

      // No prescribed weight → only reps matter
      expect(
          wasSetSuccessful(
            actualReps: 5,
            prescribedReps: 5,
            actualWeight: 130,
            prescribedWeight: null,
          ),
          isTrue);
    });
  });

  group('RECO-02: Plateau detection flags 3 consecutive rep failures', () {
    test('detectPlateau returns true when variance < 5 lbs', () {
      // 135, 136, 134 → variance is 2 lbs < 5 → plateau
      expect(detectPlateau([135, 136, 134]), isTrue);

      // 135, 140, 145 → variance is 10 lbs ≥ 5 → no plateau
      expect(detectPlateau([135, 140, 145]), isFalse);

      // Less than 3 data points → no plateau
      expect(detectPlateau([135, 136]), isFalse);
    });

    test('detectPlateauForExercise checks rep failures per session', () async {
      final db = await createTestDatabase();

      final userId = await db.into(db.users).insert(UsersCompanion.insert(
            name: 'Plateau User',
            experienceLevel: 'intermediate',
            goal: 'strength',
          ));

      final cycleId =
          await db.into(db.activeCycles).insert(ActiveCyclesCompanion.insert(
                userId: userId,
                programId: 'back-squat',
                cycleName: 'Plateau Test Cycle',
                startDate: DateTime.now().subtract(const Duration(days: 21)),
              ));

      // Create 3 workouts with rep failures in each
      for (var i = 0; i < 3; i++) {
        final workoutId = await db
            .into(db.completedWorkouts)
            .insert(CompletedWorkoutsCompanion.insert(
              userId: userId,
              activeCycleId: cycleId,
              programId: 'back-squat',
              week: i + 1,
              completedAt:
                  DateTime.now().subtract(Duration(days: 14 - (i * 7))),
            ));

        // Each workout has a set where actualReps < prescribedReps
        await db.into(db.completedSets).insert(CompletedSetsCompanion.insert(
              workoutId: workoutId,
              exerciseId: 'back-squat',
              setNumber: 1,
              actualWeight: 135,
              prescribedReps: 5,
              actualReps: 4, // Failed to hit prescribed reps
              createdAt: DateTime.now().subtract(Duration(days: 14 - (i * 7))),
            ));
      }

      // Should detect plateau (3 consecutive sessions with rep failures)
      final result = await detectPlateauForExercise(
        db: db,
        exerciseId: 'back-squat',
        activeCycleId: cycleId,
      );

      expect(result.hasPlateau, isTrue);
      expect(result.message, contains('missed prescribed reps'));
      expect(result.recommendation, contains('deload'));

      await db.close();
    });

    test('no plateau when sessions have successful reps', () async {
      final db = await createTestDatabase();

      final userId = await db.into(db.users).insert(UsersCompanion.insert(
            name: 'Success User',
            experienceLevel: 'intermediate',
            goal: 'strength',
          ));

      final cycleId =
          await db.into(db.activeCycles).insert(ActiveCyclesCompanion.insert(
                userId: userId,
                programId: 'back-squat',
                cycleName: 'Success Test Cycle',
                startDate: DateTime.now().subtract(const Duration(days: 21)),
              ));

      // Create 3 workouts with successful reps
      for (var i = 0; i < 3; i++) {
        final workoutId = await db
            .into(db.completedWorkouts)
            .insert(CompletedWorkoutsCompanion.insert(
              userId: userId,
              activeCycleId: cycleId,
              programId: 'back-squat',
              week: i + 1,
              completedAt:
                  DateTime.now().subtract(Duration(days: 14 - (i * 7))),
            ));

        await db.into(db.completedSets).insert(CompletedSetsCompanion.insert(
              workoutId: workoutId,
              exerciseId: 'back-squat',
              setNumber: 1,
              actualWeight: 135 + (i * 5).toDouble(), // Progressive overload
              prescribedReps: 5,
              actualReps: 5, // Hit prescribed reps
              createdAt: DateTime.now().subtract(Duration(days: 14 - (i * 7))),
            ));
      }

      // Should NOT detect plateau
      final result = await detectPlateauForExercise(
        db: db,
        exerciseId: 'back-squat',
        activeCycleId: cycleId,
      );

      expect(result.hasPlateau, isFalse);

      await db.close();
    });

    // ===== WEIGHT PR TESTS (verify ordering bug is caught) =====

    test('checkAndSaveWeightPR returns false on first-ever lift', () async {
      final db = await createTestDatabase();
      final repo = WorkoutRepository(db);

      final userId = await db.into(db.users).insert(UsersCompanion.insert(
            name: 'First Lift User',
            experienceLevel: 'beginner',
            goal: 'strength',
          ));

      final cycleId =
          await db.into(db.activeCycles).insert(ActiveCyclesCompanion.insert(
                userId: userId,
                programId: 'back-squat',
                cycleName: 'First Cycle',
                startDate: DateTime.now(),
              ));

      final workoutId = await db
          .into(db.completedWorkouts)
          .insert(CompletedWorkoutsCompanion.insert(
            userId: userId,
            activeCycleId: cycleId,
            programId: 'back-squat',
            week: 1,
            completedAt: DateTime.now(),
          ));

      // No prior OneRepMaxes exist - first-ever lift
      // Should return false (historicalMax = 0 guard)
      final isPR = await repo.checkAndSaveWeightPR(
        userId: userId,
        exerciseId: 'back-squat',
        newWeight: 135,
        workoutId: workoutId,
        date: DateTime.now(),
      );

      expect(isPR, isFalse);

      // Verify no PersonalRecord was created
      final records = await (db.select(db.personalRecords)
            ..where((t) => t.userId.equals(userId)))
          .get();
      expect(records, isEmpty);

      await db.close();
    });

    test('checkAndSaveWeightPR fires on second session when weight exceeds first',
        () async {
      final db = await createTestDatabase();
      final repo = WorkoutRepository(db);

      final userId = await db.into(db.users).insert(UsersCompanion.insert(
            name: 'PR User',
            experienceLevel: 'intermediate',
            goal: 'strength',
          ));

      final cycleId =
          await db.into(db.activeCycles).insert(ActiveCyclesCompanion.insert(
                userId: userId,
                programId: 'back-squat',
                cycleName: 'PR Test Cycle',
                startDate: DateTime.now().subtract(const Duration(days: 7)),
              ));

      // ===== SESSION 1: 135 lbs =====
      await db.into(db.completedWorkouts).insert(CompletedWorkoutsCompanion.insert(
            userId: userId,
            activeCycleId: cycleId,
            programId: 'back-squat',
            week: 1,
            completedAt: DateTime.now().subtract(const Duration(days: 7)),
          ));

      // Save 1RM for session 1 (this establishes the baseline)
      await repo.saveOneRepMax(
        userId: userId,
        exerciseId: 'back-squat',
        weight: 135, // Session 1 max
        date: DateTime.now().subtract(const Duration(days: 7)),
      );

      // ===== SESSION 2: 140 lbs =====
      final workout2Id = await db
          .into(db.completedWorkouts)
          .insert(CompletedWorkoutsCompanion.insert(
            userId: userId,
            activeCycleId: cycleId,
            programId: 'back-squat',
            week: 2,
            completedAt: DateTime.now(),
          ));

      // CRITICAL: Check weight PR BEFORE saving session 2's 1RM
      // This is the correct order per Plan 04 fix
      final isPR = await repo.checkAndSaveWeightPR(
        userId: userId,
        exerciseId: 'back-squat',
        newWeight: 140, // Session 2 weight > Session 1 (135)
        workoutId: workout2Id,
        date: DateTime.now(),
      );

      // Should detect weight PR (140 > 135)
      expect(isPR, isTrue);

      // Verify PersonalRecord was created
      final records = await (db.select(db.personalRecords)
            ..where((t) => t.userId.equals(userId))
            ..where((t) => t.type.equals('weight')))
          .get();
      expect(records, hasLength(1));
      expect(records.first.value, equals(140));
      expect(records.first.exerciseId, equals('back-squat'));

      await db.close();
    });
  });
}
