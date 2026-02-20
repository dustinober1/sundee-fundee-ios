import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundee_fundee/app.dart';

void main() {
  testWidgets('App launches with onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SundeeFundeeApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-screen')), findsOneWidget);
  });
}
