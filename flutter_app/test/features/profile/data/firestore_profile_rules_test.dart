import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('firestore rules enforce owner checks and profile schema keys',
      () async {
    final File rulesFile = File('../firestore.rules');
    final String rules = await rulesFile.readAsString();

    expect(rules, contains('function isOwner(userId)'));
    expect(rules, contains('match /users/{userId}'));
    expect(rules, contains('injuryProfiles'));
    expect(rules, contains('onboardingComplete'));
    expect(rules, contains('profileUpdatedAt'));
  });
}
