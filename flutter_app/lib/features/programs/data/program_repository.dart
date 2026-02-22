import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/program_models.dart';
import 'deadlift_program.dart';

class ProgramRepository {
  Future<List<ProgramV2>> getPrograms() async {
    // In the future, this could fetch from Firestore or an API
    return <ProgramV2>[deadliftProgram];
  }
}

final Provider<ProgramRepository> programRepositoryProvider =
    Provider<ProgramRepository>((Ref ref) {
  return ProgramRepository();
});

final FutureProvider<List<ProgramV2>> programsProvider =
    FutureProvider<List<ProgramV2>>((Ref ref) async {
  final ProgramRepository repository = ref.watch(programRepositoryProvider);
  return repository.getPrograms();
});
