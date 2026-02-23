import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';
import 'package:sundee_fundee_flutter/features/repositories/data/firestore_repositories.dart';

void main() {
  group('FirestoreCycleRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreCycleRepository repository;
    const String userId = 'user-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreCycleRepository(firestore: firestore);
    });

    test('savePeriodLog persists and watchPeriodLogs streams values', () async {
      final PeriodLogModel log = PeriodLogModel(
        id: 'log-1',
        userId: userId,
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 2, 5),
        flowLevel: FlowLevel.medium,
        notes: 'baseline',
      );

      await repository.savePeriodLog(userId: userId, log: log);

      final List<PeriodLogModel> logs =
          await repository.watchPeriodLogs(userId: userId).first;

      expect(logs, hasLength(1));
      expect(logs.first.id, 'log-1');
      expect(logs.first.flowLevel, FlowLevel.medium);
    });

    test('saveCycleSettings persists and watchCycleSettings reads it',
        () async {
      final CycleSettingsModel settings = CycleSettingsModel(
        id: 'settings',
        userId: userId,
        averageCycleLength: 29,
        averagePeriodLength: 5,
        lutealPhaseLength: 14,
        enabledSymptomIds: const <String>['cramps'],
        notificationsEnabled: true,
      );

      await repository.saveCycleSettings(userId: userId, settings: settings);

      final CycleSettingsModel? stored =
          await repository.watchCycleSettings(userId: userId).first;

      expect(stored, isNotNull);
      expect(stored!.averageCycleLength, 29);
      expect(stored.enabledSymptomIds, contains('cramps'));
      expect(stored.notificationsEnabled, isTrue);
    });

    test(
      'saveCycleAdaptationPreferences persists and watch reads preferences',
      () async {
        final CycleAdaptationPreferencesModel preferences =
            CycleAdaptationPreferencesModel(
          id: 'programAdaptation',
          userId: userId,
          enabled: true,
          readinessScore: 7.5,
          autoApplyDuringWorkout: false,
          showAdjustmentDetails: true,
          updatedAt: DateTime.utc(2026, 2, 23, 12),
        );

        await repository.saveCycleAdaptationPreferences(
          userId: userId,
          preferences: preferences,
        );

        final CycleAdaptationPreferencesModel? stored = await repository
            .watchCycleAdaptationPreferences(userId: userId)
            .first;

        expect(stored, isNotNull);
        expect(stored!.enabled, isTrue);
        expect(stored.readinessScore, closeTo(7.5, 0.0001));
        expect(stored.showAdjustmentDetails, isTrue);
      },
    );
  });
}
