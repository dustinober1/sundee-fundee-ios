import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/workout_repository.dart';
import 'database_provider.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});
