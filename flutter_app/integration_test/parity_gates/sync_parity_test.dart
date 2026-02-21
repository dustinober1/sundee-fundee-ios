import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sundee_fundee/features/auth/auth_screen.dart';
import 'package:sundee_fundee/shared/providers/sync_provider.dart';
import 'package:sundee_fundee/shared/providers/supabase_provider.dart';
import 'package:sundee_fundee/shared/widgets/sync_status_badge.dart';

// ---------------------------------------------------------------------------
// Fake SyncNotifier that returns a pre-configured SyncState without touching
// the Supabase or connectivity providers.
// ---------------------------------------------------------------------------
class _FakeSyncNotifier extends SyncNotifier {
  final SyncState _initial;
  _FakeSyncNotifier(this._initial);

  @override
  SyncState build() => _initial;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // SYNC-01: Optional auth — sign-in UI exists and is reachable
  // =========================================================================
  group('SYNC-01: Optional auth + sign-in UI', () {
    testWidgets('auth screen renders sign-in form fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('auth-screen')), findsOneWidget);
      expect(find.byKey(const Key('auth-email-field')), findsOneWidget);
      expect(find.byKey(const Key('auth-password-field')), findsOneWidget);
    });

    testWidgets('auth screen has submit button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
    });

    testWidgets('auth screen has toggle between sign-in and create-account',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('auth-toggle')), findsOneWidget);
    });

    testWidgets('toggle switches from sign-in to create-account mode',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pump();

      // Initially in sign-in mode
      expect(find.text('Sign In'), findsWidgets);

      // Tap toggle to switch to create account mode
      await tester.tap(find.byKey(const Key('auth-toggle')));
      await tester.pump();

      expect(find.text('Create Account'), findsWidgets);
    });
  });

  // =========================================================================
  // SYNC-02: Sync status badge — renders all 6 SyncStatus states
  // =========================================================================
  group('SYNC-02: Sync status badge', () {
    testWidgets('sync badge renders for all SyncStatus values without crashing',
        (tester) async {
      for (final status in SyncStatus.values) {
        final syncState = SyncState(status: status);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseClientProvider.overrideWithValue(null),
              syncProvider.overrideWith(() => _FakeSyncNotifier(syncState)),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  actions: const [SyncStatusBadge()],
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pump();

        // The badge key is always present regardless of status
        expect(find.byKey(const Key('sync-status-badge')), findsOneWidget,
            reason: 'sync-status-badge key should be present for $status');
      }
    });

    testWidgets('sync badge shows cloud_off icon when status is offline',
        (tester) async {
      const syncState = SyncState(status: SyncStatus.offline);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
            syncProvider
                .overrideWith(() => _FakeSyncNotifier(syncState)),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [SyncStatusBadge()],
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('sync badge shows cloud_done icon when status is synced',
        (tester) async {
      const syncState = SyncState(status: SyncStatus.synced);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
            syncProvider
                .overrideWith(() => _FakeSyncNotifier(syncState)),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [SyncStatusBadge()],
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('sync badge renders SizedBox.shrink when status is disabled',
        (tester) async {
      const syncState = SyncState(status: SyncStatus.disabled);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
            syncProvider
                .overrideWith(() => _FakeSyncNotifier(syncState)),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [SyncStatusBadge()],
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Disabled → badge key is present but wraps SizedBox.shrink (invisible)
      expect(find.byKey(const Key('sync-status-badge')), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      expect(find.byIcon(Icons.cloud_done), findsNothing);
    });
  });

  // =========================================================================
  // SYNC-03: Local-first defaults — sync is disabled when Supabase unconfigured
  // =========================================================================
  group('SYNC-03: Local-first defaults', () {
    test('SyncNotifier is disabled when Supabase is unconfigured', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.status, equals(SyncStatus.disabled));
    });

    test('SyncNotifier isAuthenticated is false when Supabase is null', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.isAuthenticated, isFalse);
    });

    testWidgets('auth screen renders without error when Supabase is null',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );
      await tester.pump();

      // Screen renders without crashing — local-first: auth is optional
      expect(find.byKey(const Key('auth-screen')), findsOneWidget);
    });
  });
}
