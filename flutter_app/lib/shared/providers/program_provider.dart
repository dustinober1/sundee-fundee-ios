import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/program_v2.dart';
import '../../data/repositories/program_repository.dart';

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository();
});

final programsProvider = FutureProvider<List<ProgramV2>>((ref) async {
  return ref.read(programRepositoryProvider).getAllPrograms();
});

final programByIdProvider =
    FutureProvider.family<ProgramV2?, String>((ref, id) async {
  return ref.read(programRepositoryProvider).getProgramById(id);
});
