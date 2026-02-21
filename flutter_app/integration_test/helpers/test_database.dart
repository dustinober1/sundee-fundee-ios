import 'package:drift/native.dart';
import 'package:sundee_fundee/data/database/app_database.dart';

/// Creates an in-memory database for integration tests.
///
/// Enables foreign keys for cascade delete (per STATE.md pattern).
Future<AppDatabase> createTestDatabase() async {
  final db = AppDatabase(NativeDatabase.memory());
  // Enable FK for cascade delete (STATE.md pattern)
  await db.customStatement('PRAGMA foreign_keys = ON');
  return db;
}
