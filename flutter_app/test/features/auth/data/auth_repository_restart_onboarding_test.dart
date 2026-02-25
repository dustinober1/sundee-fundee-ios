import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/auth/data/auth_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/data/guest_mode_store.dart';

void main() {
  group('AuthRepository restartOnboardingForUser', () {
    late FakeFirebaseFirestore firestore;
    late AuthRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = AuthRepository(
        guestModeStore: GuestModeStore(),
        firebaseEnabled: true,
        firestore: firestore,
      );
    });

    test('clears onboarding and injury/disclaimer fields together', () async {
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'displayName': 'Dustin',
        'name': 'Dustin',
        'genderRaw': 'male',
        'cycleTrackingEnabled': true,
        'onboardingComplete': true,
        'injuryProfiles': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'inj-1', 'status': 'active'},
        ],
        'acknowledgedInjuryDisclaimerIds': <String, dynamic>{
          'inj-1': DateTime.utc(2026, 2, 1).toIso8601String(),
        },
      });

      await repository.restartOnboardingForUser('u1');

      final Map<String, dynamic>? data =
          (await firestore.collection('users').doc('u1').get()).data();
      expect(data, isNotNull);

      expect(data!['displayName'], '');
      expect(data['name'], '');
      expect(data['genderRaw'], 'preferNotToSay');
      expect(data['cycleTrackingEnabled'], isFalse);
      expect(data['onboardingComplete'], isFalse);
      expect(data['injuryProfiles'], isEmpty);
      expect(data['acknowledgedInjuryDisclaimerIds'], isEmpty);
      expect(data['profileUpdatedAt'], isNotNull);
      expect(data['updatedAt'], isNotNull);
    });

    test('preserves unrelated profile fields while resetting onboarding branch',
        () async {
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'displayName': 'Dustin',
        'name': 'Dustin',
        'email': 'dustin@example.com',
        'experienceLevelRaw': 'intermediate',
        'primaryGoalRaw': 'strength',
        'onboardingComplete': true,
        'injuryProfiles': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'inj-1', 'status': 'active'},
        ],
        'acknowledgedInjuryDisclaimerIds': <String, dynamic>{
          'inj-1': DateTime.utc(2026, 2, 1).toIso8601String(),
        },
      });

      await repository.restartOnboardingForUser('u1');

      final Map<String, dynamic>? data =
          (await firestore.collection('users').doc('u1').get()).data();
      expect(data, isNotNull);
      expect(data!['email'], 'dustin@example.com');
      expect(data['experienceLevelRaw'], 'intermediate');
      expect(data['primaryGoalRaw'], 'strength');
      expect(data['name'], '');
      expect(data['onboardingComplete'], isFalse);
      expect(data['injuryProfiles'], isEmpty);
      expect(data['acknowledgedInjuryDisclaimerIds'], isEmpty);
    });

    test('is idempotent when restart is requested multiple times', () async {
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'displayName': 'Dustin',
        'name': 'Dustin',
        'onboardingComplete': true,
        'injuryProfiles': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'inj-1', 'status': 'active'},
        ],
      });

      await repository.restartOnboardingForUser('u1');
      await repository.restartOnboardingForUser('u1');

      final Map<String, dynamic>? data =
          (await firestore.collection('users').doc('u1').get()).data();
      expect(data, isNotNull);
      expect(data!['displayName'], '');
      expect(data['name'], '');
      expect(data['onboardingComplete'], isFalse);
      expect(data['injuryProfiles'], isEmpty);
      expect(data['acknowledgedInjuryDisclaimerIds'], isEmpty);
    });
  });
}
