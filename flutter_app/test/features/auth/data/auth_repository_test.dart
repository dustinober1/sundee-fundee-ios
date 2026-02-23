import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sundee_fundee_flutter/features/auth/data/auth_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/data/guest_mode_store.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';

void main() {
  group('AuthRepository (guest mode)', () {
    late GuestModeStore guestModeStore;
    late AuthRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      guestModeStore = GuestModeStore();
      repository = AuthRepository(
        guestModeStore: guestModeStore,
        firebaseEnabled: false,
      );
    });

    test('authStateChanges emits unauthenticated when guest mode is off', () async {
      final AuthSession session = await repository.authStateChanges().first;
      expect(session.status, AuthStatus.unauthenticated);
    });

    test('authStateChanges emits guest when guest mode is enabled', () async {
      await guestModeStore.setGuestModeEnabled(true);

      final AuthSession session = await repository.authStateChanges().first;
      expect(session.status, AuthStatus.guest);
    });

    test('continueAsGuest enables guest mode and signOut clears it', () async {
      await repository.continueAsGuest();
      expect(await guestModeStore.isGuestModeEnabled(), isTrue);

      await repository.signOut();
      expect(await guestModeStore.isGuestModeEnabled(), isFalse);
    });
  });
}
