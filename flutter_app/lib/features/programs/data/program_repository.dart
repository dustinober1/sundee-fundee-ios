import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/providers.dart';
import '../../../domain/data/predefined_programs.dart';
import '../../../domain/models/program_models.dart';
import '../../repositories/domain/repository_interfaces.dart';
import '../../repositories/providers.dart';

class ProgramRepository {
  ProgramRepository(
      {required EnrolledProgramRepository enrolledProgramRepository})
      : _enrolledProgramRepository = enrolledProgramRepository;

  final EnrolledProgramRepository _enrolledProgramRepository;

  Future<List<ProgramV2>> getPrograms() async {
    return <ProgramV2>[
      PredefinedPrograms.baseline12Week,
      PredefinedPrograms.squat2Cycle,
      PredefinedPrograms.deadlift1Cycle,
      PredefinedPrograms.benchPress1Cycle,
    ];
  }

  Future<void> enrollUser({
    required String userId,
    required String programId,
  }) async {
    final enrollment = EnrolledProgramModel(
      id: const Uuid().v4(),
      programId: programId,
      startDate: DateTime.now(),
      currentWeek: 1,
      currentDay: 1,
    );
    return _enrolledProgramRepository.enrollUser(
      userId: userId,
      enrollment: enrollment,
    );
  }

  Stream<EnrolledProgramModel?> watchActiveEnrollment(
      {required String userId}) {
    return _enrolledProgramRepository.watchActiveEnrollment(userId: userId);
  }
}

final Provider<ProgramRepository> programRepositoryProvider =
    Provider<ProgramRepository>((Ref ref) {
  final enrolledRepo = ref.watch(enrolledProgramRepositoryProvider);
  return ProgramRepository(enrolledProgramRepository: enrolledRepo);
});

final FutureProvider<List<ProgramV2>> programsProvider =
    FutureProvider<List<ProgramV2>>((Ref ref) async {
  final ProgramRepository repository = ref.watch(programRepositoryProvider);
  return repository.getPrograms();
});

final StreamProvider<EnrolledProgramModel?> activeEnrollmentProvider =
    StreamProvider<EnrolledProgramModel?>((Ref ref) {
  final userId = ref.watch(authSessionStreamProvider).asData?.value.user?.uid;
  if (userId == null) {
    return Stream.value(null);
  }
  final repository = ref.watch(programRepositoryProvider);
  return repository.watchActiveEnrollment(userId: userId);
});

final StreamProvider<ProgramV2?> activeProgramProvider =
    StreamProvider<ProgramV2?>((Ref ref) async* {
  final enrollment = ref.watch(activeEnrollmentProvider).asData?.value;
  if (enrollment == null) {
    yield null;
    return;
  }

  final programs = await ref.watch(programsProvider.future);
  yield programs.firstWhere(
    (p) => p.id == enrollment.programId,
    orElse: () =>
        throw StateError('Program not found: ${enrollment.programId}'),
  );
});
