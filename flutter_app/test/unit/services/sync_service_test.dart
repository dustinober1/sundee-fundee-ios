import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sundee_fundee/data/database/app_database.dart';
import 'package:sundee_fundee/services/sync_service.dart';

// ---------------------------------------------------------------------------
// Minimal stub — queue and withRetry tests never call SupabaseClient methods.
// ---------------------------------------------------------------------------
class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late AppDatabase db;
  late SyncService service;

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      }),
    );
    SharedPreferences.setMockInitialValues({});
    service = SyncService(db: db, supabase: _FakeSupabaseClient());
  });

  tearDown(() async {
    await db.close();
  });

  // -------------------------------------------------------------------------
  // Queue operations (SharedPreferences-backed, no Supabase calls)
  // -------------------------------------------------------------------------
  group('SyncService — queue operations', () {
    test('getQueue returns empty list initially', () async {
      final queue = await service.getQueue();
      expect(queue, isEmpty);
    });

    test('enqueue adds a workout ID to the queue', () async {
      await service.enqueue(42);
      final queue = await service.getQueue();
      expect(queue, contains(42));
    });

    test('enqueue is idempotent — same ID not duplicated', () async {
      await service.enqueue(42);
      await service.enqueue(42);
      final queue = await service.getQueue();
      expect(queue, equals([42]));
    });

    test('dequeue removes a specific workout ID', () async {
      await service.enqueue(1);
      await service.enqueue(2);
      await service.dequeue(1);
      final queue = await service.getQueue();
      expect(queue, isNot(contains(1)));
      expect(queue, contains(2));
    });

    test('dequeue on absent ID is a no-op', () async {
      await service.enqueue(99);
      await service.dequeue(0); // not in queue
      final queue = await service.getQueue();
      expect(queue, equals([99]));
    });

    test('getQueue returns correct list after multiple enqueues', () async {
      await service.enqueue(10);
      await service.enqueue(20);
      await service.enqueue(30);
      final queue = await service.getQueue();
      expect(queue, containsAll([10, 20, 30]));
      expect(queue.length, equals(3));
    });

    test('getQueue persists across calls (SharedPreferences round-trip)',
        () async {
      await service.enqueue(7);

      // Create a fresh SyncService — same SharedPreferences mock is reused.
      final service2 = SyncService(db: db, supabase: _FakeSupabaseClient());
      final queue = await service2.getQueue();
      expect(queue, contains(7));
    });
  });

  // -------------------------------------------------------------------------
  // withRetry — retry logic and call-count verification
  // -------------------------------------------------------------------------
  group('SyncService — withRetry', () {
    test('succeeds on first attempt — returns result without retrying',
        () async {
      int calls = 0;
      final result = await service.withRetry<String>(() async {
        calls++;
        return 'done';
      });
      expect(result, equals('done'));
      expect(calls, equals(1));
    });

    test('fails all attempts with maxAttempts=1 — throws immediately',
        () async {
      // maxAttempts=1 → no retry, no delay
      int calls = 0;
      Object? caught;
      try {
        await service.withRetry<void>(
          () async {
            calls++;
            throw Exception('always fails');
          },
          maxAttempts: 1,
        );
      } catch (e) {
        caught = e;
      }
      expect(calls, equals(1));
      expect(caught, isA<Exception>());
    });

    test('retries on transient failure — succeeds on second attempt', () async {
      // maxAttempts=3: first attempt fails (1 s back-off), second succeeds.
      int calls = 0;
      final result = await service.withRetry<String>(
        () async {
          calls++;
          if (calls == 1) throw Exception('transient');
          return 'recovered';
        },
        maxAttempts: 3,
      );
      expect(result, equals('recovered'));
      expect(calls, equals(2));
    });

    test('exhausts maxAttempts=2 and rethrows — correct call count', () async {
      // maxAttempts=2: attempt 1 fails (1 s back-off), attempt 2 fails → rethrow.
      int calls = 0;
      Object? caught;
      try {
        await service.withRetry<void>(
          () async {
            calls++;
            throw Exception('always fails');
          },
          maxAttempts: 2,
        );
      } catch (e) {
        caught = e;
      }
      expect(calls, equals(2));
      expect(caught, isA<Exception>());
    });
  });
}
