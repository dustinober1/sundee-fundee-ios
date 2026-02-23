import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/injury_profile_model.dart';
import 'package:sundee_fundee_flutter/features/profile/data/profile_repository.dart';

void main() {
  group('ProfileRepository', () {
    test('normalizes legacy profile shape when watching user', () async {
      final firestore = FakeFirebaseFirestore();
      final ProfileRepository repository =
          ProfileRepository(firestore: firestore);

      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'id': 'u1',
        'displayName': 'Legacy Name',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'female',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'onboardingComplete': false,
        'injuryProfile': <String, dynamic>{
          'id': 'legacy',
          'location': 'Knee',
          'movementLimitations': 'No sprinting',
          'recoveryGoal': 'Pain free running',
          'status': 'active',
        },
      });

      final user = await repository.watchUserProfile('u1').first;
      expect(user, isNotNull);
      expect(user!.name, 'Legacy Name');
      expect(user.injuryProfiles, hasLength(1));
      expect(user.injuryProfiles.first.location, 'Knee');
      expect(user.onboardingCompleteComputed, isTrue);
    });

    test('save and resolve injury preserve history in profile list', () async {
      final firestore = FakeFirebaseFirestore();
      final ProfileRepository repository =
          ProfileRepository(firestore: firestore);
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'id': 'u1',
        'name': 'User',
        'experienceLevelRaw': 'beginner',
        'primaryGoalRaw': 'strength',
        'genderRaw': 'female',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      });

      final InjuryProfileModel injury = InjuryProfileModel(
        id: 'inj-1',
        location: 'Shoulder',
        movementLimitations: 'No overhead press',
        recoveryGoal: 'Return to pressing',
        status: InjuryStatus.active,
        createdAt: DateTime.utc(2026, 1, 2),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      await repository.saveInjuryProfile(userId: 'u1', injury: injury);
      await repository.resolveInjury(userId: 'u1', injuryId: 'inj-1');

      final user = await repository.watchUserProfile('u1').first;
      expect(user, isNotNull);
      expect(user!.injuryProfiles, hasLength(1));
      expect(user.injuryProfiles.first.status, InjuryStatus.resolved);
      expect(user.injuryProfiles.first.resolvedAt, isNotNull);
    });

    test('failed writes are queued for retry', () async {
      final ProfileRepository repository = ProfileRepository(firestore: null);
      final InjuryProfileModel injury = InjuryProfileModel(
        id: 'inj-1',
        location: 'Knee',
        movementLimitations: 'No jumping',
        recoveryGoal: 'Pain free squat',
        status: InjuryStatus.active,
        createdAt: DateTime.utc(2026, 1, 2),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      await expectLater(
        () => repository.saveInjuryProfile(userId: 'u1', injury: injury),
        throwsStateError,
      );
      expect(repository.pendingWriteCount, 1);
    });
  });
}
