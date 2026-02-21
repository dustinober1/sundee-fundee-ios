import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get experienceLevel => text()();
  TextColumn get goal => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class ActiveCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get programId => text()();
  TextColumn get cycleName => text()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get currentWeek =>
      integer().withDefault(const Constant(1))();
  TextColumn get currentSessionId => text().nullable()();
  TextColumn get currentPhase => text().nullable()();
  // status values: 'active', 'completed', 'paused'
  TextColumn get status =>
      text().withDefault(const Constant('active'))();
  TextColumn get syncId => text().nullable().unique()();
}

class CompletedWorkouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get activeCycleId =>
      integer().references(ActiveCycles, #id)();
  TextColumn get programId => text()();
  IntColumn get week => integer()();
  IntColumn get day => integer().nullable()();
  TextColumn get sessionId => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get duration => integer().nullable()(); // seconds
  TextColumn get notes => text().nullable()();
  TextColumn get syncId => text().nullable().unique()();
}

class CompletedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(
    CompletedWorkouts,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get exerciseId => text()();
  IntColumn get setNumber => integer()();
  RealColumn get prescribedWeight => real().nullable()();
  RealColumn get actualWeight => real()();
  IntColumn get prescribedReps => integer()();
  IntColumn get actualReps => integer()();
  IntColumn get rpe => integer().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  TextColumn get overrideReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncId => text().nullable().unique()();
}

class OneRepMaxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get exerciseId => text()();
  RealColumn get weight => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get syncId => text().nullable().unique()();
}

class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get exerciseId => text()();
  TextColumn get type => text()(); // 'weight' or 'volume'
  RealColumn get value => real()();
  IntColumn get workoutId =>
      integer().references(CompletedWorkouts, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get syncId => text().nullable().unique()();
}

@DriftDatabase(tables: [
  Users,
  ActiveCycles,
  CompletedWorkouts,
  CompletedSets,
  OneRepMaxes,
  PersonalRecords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'sundee_fundee'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(activeCycles);
      }
      if (from < 3) {
        await m.createTable(completedWorkouts);
        await m.createTable(completedSets);
        await m.createTable(oneRepMaxes);
        await m.createTable(personalRecords);
      }
      if (from < 4) {
        await m.addColumn(completedWorkouts, completedWorkouts.syncId);
        await m.addColumn(completedSets, completedSets.syncId);
        await m.addColumn(activeCycles, activeCycles.syncId);
        await m.addColumn(oneRepMaxes, oneRepMaxes.syncId);
        await m.addColumn(personalRecords, personalRecords.syncId);
      }
    },
  );
}
