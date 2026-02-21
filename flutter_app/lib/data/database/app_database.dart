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
}

@DriftDatabase(tables: [Users, ActiveCycles])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'sundee_fundee'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(activeCycles);
      }
    },
  );
}
