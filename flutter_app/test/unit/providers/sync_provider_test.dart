import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sundee_fundee/shared/providers/sync_provider.dart';
import 'package:sundee_fundee/shared/providers/supabase_provider.dart';

void main() {
  // -------------------------------------------------------------------------
  // SyncStatus enum
  // -------------------------------------------------------------------------
  group('SyncStatus', () {
    test('has all 6 expected values', () {
      expect(SyncStatus.values, hasLength(6));
      expect(
        SyncStatus.values,
        containsAll([
          SyncStatus.disabled,
          SyncStatus.offline,
          SyncStatus.pending,
          SyncStatus.syncing,
          SyncStatus.synced,
          SyncStatus.error,
        ]),
      );
    });
  });

  // -------------------------------------------------------------------------
  // SyncState value class
  // -------------------------------------------------------------------------
  group('SyncState', () {
    test('default constructor has correct defaults', () {
      const state = SyncState();
      expect(state.status, equals(SyncStatus.disabled));
      expect(state.lastSyncedAt, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates status field', () {
      const original = SyncState(status: SyncStatus.offline);
      final updated = original.copyWith(status: SyncStatus.synced);
      expect(updated.status, equals(SyncStatus.synced));
    });

    test('copyWith preserves unchanged fields', () {
      final now = DateTime(2025, 6, 1);
      final original = SyncState(
        status: SyncStatus.synced,
        lastSyncedAt: now,
        isAuthenticated: true,
      );
      final updated = original.copyWith(status: SyncStatus.syncing);
      expect(updated.lastSyncedAt, equals(now));
      expect(updated.isAuthenticated, isTrue);
      expect(updated.status, equals(SyncStatus.syncing));
    });

    test('copyWith can set errorMessage', () {
      const original = SyncState();
      final updated = original.copyWith(errorMessage: 'network error');
      expect(updated.errorMessage, equals('network error'));
    });

    test('copyWith without errorMessage argument preserves existing error', () {
      const original = SyncState(errorMessage: 'old error');
      final updated = original.copyWith(status: SyncStatus.syncing);
      expect(updated.errorMessage, equals('old error'));
    });

    test('copyWith isAuthenticated can be toggled', () {
      const original = SyncState(isAuthenticated: false);
      final updated = original.copyWith(isAuthenticated: true);
      expect(updated.isAuthenticated, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // SyncNotifier — state transitions via ProviderContainer
  // -------------------------------------------------------------------------
  group('SyncNotifier', () {
    test('returns disabled status when supabaseClientProvider is null', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.status, equals(SyncStatus.disabled));
    });

    test('isAuthenticated defaults to false when Supabase is null', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.isAuthenticated, isFalse);
    });

    test('lastSyncedAt is null when Supabase is null', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.lastSyncedAt, isNull);
    });

    test('errorMessage is null in initial disabled state', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(syncProvider);
      expect(state.errorMessage, isNull);
    });
  });
}
