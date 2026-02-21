import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/cycle_repository.dart';
import 'database_provider.dart';
import 'user_provider.dart';

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CycleRepository(db);
});

/// Watches the current user's active cycle. Returns null if no active cycle.
/// Invalidate this provider after starting/completing a cycle to refresh.
final activeCycleProvider = FutureProvider<ActiveCycle?>((ref) async {
  final user = await ref.watch(userProvider.future);
  if (user == null) return null;
  return ref.read(cycleRepositoryProvider).getActiveCycle(user.id);
});
