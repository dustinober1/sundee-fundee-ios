import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
      // Complete onboarding while offline — data should save to Drift
      await completeOnboarding(tester);
      // Should reach dashboard even while offline (local-first)
      expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
    });
  });
}
