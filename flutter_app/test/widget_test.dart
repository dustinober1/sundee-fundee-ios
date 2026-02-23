import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundee_fundee_flutter/app/app.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';
import 'package:sundee_fundee_flutter/features/auth/providers.dart';

void main() {
  testWidgets('renders dashboard shell for authenticated session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStreamProvider.overrideWith(
            (Ref ref) => Stream<AuthSession>.value(
              const AuthSession(status: AuthStatus.authenticated),
            ),
          ),
        ],
        child: const SundeeFundeeApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Workout History'), findsOneWidget);
  });
}
