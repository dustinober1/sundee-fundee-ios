import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/auth/data/auth_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/data/guest_mode_store.dart';

void main() {
  group('AuthRepository restartOnboardingForUser', () {
    test('clears onboarding and injury/disclaimer fields together', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      final AuthRepository repository = AuthRepository(
        guestModeStore: GuestModeStore(),
        firebaseEnabled: true,
        firestore: firestore,
      );

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
  });
}
