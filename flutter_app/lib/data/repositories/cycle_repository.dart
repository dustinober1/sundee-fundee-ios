import 'package:drift/drift.dart';
import '../database/app_database.dart';

class CycleRepository {
  final AppDatabase _db;

  CycleRepository(this._db);

  /// Start a new training cycle. Returns the inserted cycle's ID.
  /// If user already has an active cycle, returns null (enforce single active cycle).
  Future<int?> startCycle({
    required int userId,
    required String programId,
    required String cycleName,
  }) async {
    // Check for existing active cycle
    final existing = await getActiveCycle(userId);
    if (existing != null) return null;

    return await _db.into(_db.activeCycles).insert(
      ActiveCyclesCompanion.insert(
        userId: userId,
        programId: programId,
        cycleName: cycleName,
        startDate: DateTime.now(),
      ),
    );
  }

  /// Get the active cycle for a user (status == 'active'), or null if none.
  Future<ActiveCycle?> getActiveCycle(int userId) async {
    final query = _db.select(_db.activeCycles)
      ..where((t) => t.userId.equals(userId) & t.status.equals('active'));
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  /// Update cycle progress (week, session, phase).
  Future<void> updateProgress({
    required int cycleId,
    int? currentWeek,
    String? currentSessionId,
    String? currentPhase,
  }) async {
    final companion = ActiveCyclesCompanion(
      currentWeek:
          currentWeek != null ? Value(currentWeek) : const Value.absent(),
      currentSessionId: Value(currentSessionId),
      currentPhase: Value(currentPhase),
    );
    await (_db.update(_db.activeCycles)
          ..where((t) => t.id.equals(cycleId)))
        .write(companion);
  }

  /// Complete a cycle (set status to 'completed').
  Future<void> completeCycle(int cycleId) async {
    await (_db.update(_db.activeCycles)
          ..where((t) => t.id.equals(cycleId)))
        .write(const ActiveCyclesCompanion(status: Value('completed')));
  }
}
