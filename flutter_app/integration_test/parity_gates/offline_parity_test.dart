import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sundee_fundee/shared/providers/database_provider.dart';
import '../helpers/app_helper.dart';
import '../helpers/fake_connectivity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Offline Scenarios (QUAL-02)', () {
    late FakeConnectivityPlatform fakeConnectivity;

    setUp(() {
      fakeConnectivity = FakeConnectivityPlatform();
      ConnectivityPlatform.instance = fakeConnectivity;
    });

    tearDown(() {
      fakeConnectivity.dispose();
    });

    testWidgets('shows offline banner when connectivity is lost',
        (tester) async {
      fakeConnectivity.goOffline();
      await pumpApp(tester);
      await completeOnboarding(tester);
      // Pump to let the offline stream event settle
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      // Verify offline banner is visible
      expect(find.byKey(const Key('offline-banner')), findsOneWidget);
      expect(find.text('You are offline'), findsOneWidget);
    });

    testWidgets('hides offline banner when connectivity returns',
        (tester) async {
      fakeConnectivity.goOffline();
      await pumpApp(tester);
      await completeOnboarding(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('offline-banner')), findsOneWidget);
      // Reconnect
      fakeConnectivity.goOnline();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      // Banner should be gone
      expect(find.byKey(const Key('offline-banner')), findsNothing);
    });

    testWidgets('app functions offline — Drift persists locally',
        (tester) async {
      fakeConnectivity.goOffline();
      await pumpApp(tester);
      await completeOnboarding(tester);
      expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);

      // Verify Drift persistence: query the DB for the user row
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('dashboard-screen'))),
      );
      final db = container.read(databaseProvider);
      final users = await db.select(db.users).get();
      expect(users, isNotEmpty, reason: 'Onboarding should persist user to Drift');
      expect(users.first.name, 'Test User');
      expect(users.first.experienceLevel, 'beginner');
    });
  });
}
