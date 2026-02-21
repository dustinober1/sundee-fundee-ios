import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'database_provider.dart';

/// Provides the current [User] from the Drift DB, or `null` if none exists.
///
/// Used by the dashboard greeting and other screens that need the user's
/// persisted name, experience level, and goal.
final userProvider = FutureProvider<User?>((ref) async {
  final db = ref.watch(databaseProvider);
  final users = await db.select(db.users).get();
  return users.isEmpty ? null : users.first;
});
