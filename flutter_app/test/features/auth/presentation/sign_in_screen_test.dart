import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/auth/data/auth_repository.dart';
import 'package:sundee_fundee_flutter/features/auth/data/guest_mode_store.dart';
import 'package:sundee_fundee_flutter/features/auth/presentation/sign_in_screen.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';

class _ThrowingAuthRepository extends AuthRepository {
  _ThrowingAuthRepository()
      : super(
          guestModeStore: GuestModeStore(),
          firebaseEnabled: false,
        );

  @override
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw Exception('network timeout');
  }
}

void main() {
  testWidgets('shows concise action-focused error copy on sign-in failure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_ThrowingAuthRepository()),
        ],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'pw');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Could not reach the server. Please try again.'), findsOneWidget);
    expect(find.textContaining('Exception: network timeout'), findsNothing);
  });
}
