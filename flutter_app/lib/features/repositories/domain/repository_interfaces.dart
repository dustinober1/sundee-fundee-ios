import '../../../domain/models/active_cycle_model.dart';
import '../../../domain/models/completed_set_model.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/custom_program_model.dart';
import '../../../domain/models/cycle_models.dart';
import '../../../domain/models/lift_max_model.dart';
import '../../../domain/models/one_rep_max_model.dart';
import '../../../domain/models/personal_record_model.dart';

abstract class WorkoutRepository {
  Future<void> saveWorkout({
    required String userId,
    required CompletedWorkoutModel workout,
  });

  Stream<List<CompletedWorkoutModel>> watchWorkouts({required String userId});

  Future<void> saveCompletedSet({
    required String userId,
    required CompletedSetModel completedSet,
  });

  Stream<List<CompletedSetModel>> watchCompletedSets({
    required String userId,
    required String workoutId,
  });
}

abstract class CycleRepository {
  Future<void> saveActiveCycle({
    required String userId,
    required ActiveCycleModel cycle,
  });

  Stream<List<ActiveCycleModel>> watchActiveCycles({required String userId});

  Stream<List<PeriodLogModel>> watchPeriodLogs({required String userId});

  Future<void> savePeriodLog({
    required String userId,
    required PeriodLogModel log,
  });

  Future<void> deletePeriodLog({required String userId, required String logId});

  Stream<List<SymptomLogModel>> watchSymptomLogs({required String userId});

  Future<void> saveSymptomLog({
    required String userId,
    required SymptomLogModel log,
  });

  Stream<CycleSettingsModel?> watchCycleSettings({required String userId});

  Future<void> saveCycleSettings({
    required String userId,
    required CycleSettingsModel settings,
  });
}

abstract class LiftRepository {
  Future<void> saveLiftMax({
    required String userId,
    required LiftMaxModel liftMax,
  });

  Stream<List<LiftMaxModel>> watchLiftMaxes({required String userId});

  Future<void> saveOneRepMax({
    required String userId,
    required OneRepMaxModel oneRepMax,
  });

  Stream<List<OneRepMaxModel>> watchOneRepMaxes({required String userId});
}

abstract class RecordRepository {
  Future<void> saveRecord({
    required String userId,
    required PersonalRecordModel record,
  });

  Stream<List<PersonalRecordModel>> watchRecords({required String userId});
}

abstract class CustomProgramRepository {
  Future<void> saveCustomProgram({
    required String userId,
    required CustomProgramModel program,
  });

  Stream<List<CustomProgramModel>> watchCustomPrograms({
    required String userId,
  });
}
