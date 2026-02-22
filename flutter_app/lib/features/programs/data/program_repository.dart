import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/program_models.dart';
import '../../../domain/data/predefined_programs.dart';

class ProgramRepository {
  Future<List<ProgramV2>> getPrograms() async {
    return <ProgramV2>[
      PredefinedPrograms.baseline12Week,
      PredefinedPrograms.deadlift1Cycle,
      PredefinedPrograms.benchPress1Cycle,
    ];
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
