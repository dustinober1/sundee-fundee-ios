import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/features/auth/presentation/loading_screen.dart';
import 'package:sundee_fundee_flutter/features/auth/presentation/onboarding_screen.dart';
import 'package:sundee_fundee_flutter/features/auth/presentation/sign_in_screen.dart';
import 'package:sundee_fundee_flutter/features/settings/presentation/legal_screen.dart';

void main() {
  testWidgets('sign in screen meets labeled tap target guideline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('onboarding screen meets labeled tap target guideline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('legal screen meets text contrast guideline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LegalScreen()));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('sign in screen handles larger text scaling', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const MaterialApp(home: SignInScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('loading screen exposes logo semantics label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingScreen()));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image && widget.semanticLabel == 'Sundee Fundee logo',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign in legal links are accessible buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Terms'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Privacy Policy'), findsOneWidget);
  });
}
