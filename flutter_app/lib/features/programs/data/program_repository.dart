import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/providers.dart';
import '../../../domain/models/program_models.dart';
import '../../repositories/domain/repository_interfaces.dart';
import '../../repositories/providers.dart';
import 'squad_squat_program.dart';

class ProgramRepository {
  ProgramRepository({
    required FirebaseFirestore? firestore,
    required EnrolledProgramRepository enrolledProgramRepository,
  })  : _firestore = firestore,
        _enrolledProgramRepository = enrolledProgramRepository;

  final FirebaseFirestore? _firestore;
  final EnrolledProgramRepository _enrolledProgramRepository;

  List<ProgramV2> get _fallbackPrograms => [
        squadSquatProgram,
      ];

  Future<List<ProgramV2>> getPrograms() async {
    final firestore = _firestore;
    if (firestore == null) {
      // Guest mode fallback
      return _fallbackPrograms;
    }

    try {
      final snapshot = await firestore.collection('programs').get();
      if (snapshot.docs.isEmpty) {
        // If Firestore is empty, return local fallback or seed it
        return _fallbackPrograms;
      }
      return snapshot.docs
          .map((doc) => ProgramV2.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return _fallbackPrograms;
    }
  }

  Future<void> pushProgram(ProgramV2 program) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw StateError('Firebase is not enabled, cannot push program.');
    }
    await firestore.collection('programs').doc(program.id).set(program.toJson());
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

  Future<void> stopProgram({
    required String userId,
    required String enrollmentId,
  }) async {
    return _enrolledProgramRepository.stopEnrollment(
      userId: userId,
      enrollmentId: enrollmentId,
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
  final firestore = ref.watch(firestoreProvider);
  return ProgramRepository(
    firestore: firestore,
    enrolledProgramRepository: enrolledRepo,
  );
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
