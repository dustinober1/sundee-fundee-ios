// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _experienceLevelMeta = const VerificationMeta(
    'experienceLevel',
  );
  @override
  late final GeneratedColumn<String> experienceLevel = GeneratedColumn<String>(
    'experience_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    experienceLevel,
    goal,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('experience_level')) {
      context.handle(
        _experienceLevelMeta,
        experienceLevel.isAcceptableOrUnknown(
          data['experience_level']!,
          _experienceLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_experienceLevelMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      experienceLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}experience_level'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final String experienceLevel;
  final String goal;
  final DateTime createdAt;
  const User({
    required this.id,
    required this.name,
    required this.experienceLevel,
    required this.goal,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['experience_level'] = Variable<String>(experienceLevel);
    map['goal'] = Variable<String>(goal);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      experienceLevel: Value(experienceLevel),
      goal: Value(goal),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      experienceLevel: serializer.fromJson<String>(json['experienceLevel']),
      goal: serializer.fromJson<String>(json['goal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'experienceLevel': serializer.toJson<String>(experienceLevel),
      'goal': serializer.toJson<String>(goal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? experienceLevel,
    String? goal,
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    goal: goal ?? this.goal,
    createdAt: createdAt ?? this.createdAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      experienceLevel: data.experienceLevel.present
          ? data.experienceLevel.value
          : this.experienceLevel,
      goal: data.goal.present ? data.goal.value : this.goal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, experienceLevel, goal, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.experienceLevel == this.experienceLevel &&
          other.goal == this.goal &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> experienceLevel;
  final Value<String> goal;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.experienceLevel = const Value.absent(),
    this.goal = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String experienceLevel,
    required String goal,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       experienceLevel = Value(experienceLevel),
       goal = Value(goal);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? experienceLevel,
    Expression<String>? goal,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (experienceLevel != null) 'experience_level': experienceLevel,
      if (goal != null) 'goal': goal,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? experienceLevel,
    Value<String>? goal,
    Value<DateTime>? createdAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (experienceLevel.present) {
      map['experience_level'] = Variable<String>(experienceLevel.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('experienceLevel: $experienceLevel, ')
          ..write('goal: $goal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ActiveCyclesTable extends ActiveCycles
    with TableInfo<$ActiveCyclesTable, ActiveCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleNameMeta = const VerificationMeta(
    'cycleName',
  );
  @override
  late final GeneratedColumn<String> cycleName = GeneratedColumn<String>(
    'cycle_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentWeekMeta = const VerificationMeta(
    'currentWeek',
  );
  @override
  late final GeneratedColumn<int> currentWeek = GeneratedColumn<int>(
    'current_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currentSessionIdMeta = const VerificationMeta(
    'currentSessionId',
  );
  @override
  late final GeneratedColumn<String> currentSessionId = GeneratedColumn<String>(
    'current_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPhaseMeta = const VerificationMeta(
    'currentPhase',
  );
  @override
  late final GeneratedColumn<String> currentPhase = GeneratedColumn<String>(
    'current_phase',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    programId,
    cycleName,
    startDate,
    currentWeek,
    currentSessionId,
    currentPhase,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActiveCycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('cycle_name')) {
      context.handle(
        _cycleNameMeta,
        cycleName.isAcceptableOrUnknown(data['cycle_name']!, _cycleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleNameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('current_week')) {
      context.handle(
        _currentWeekMeta,
        currentWeek.isAcceptableOrUnknown(
          data['current_week']!,
          _currentWeekMeta,
        ),
      );
    }
    if (data.containsKey('current_session_id')) {
      context.handle(
        _currentSessionIdMeta,
        currentSessionId.isAcceptableOrUnknown(
          data['current_session_id']!,
          _currentSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('current_phase')) {
      context.handle(
        _currentPhaseMeta,
        currentPhase.isAcceptableOrUnknown(
          data['current_phase']!,
          _currentPhaseMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      cycleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      currentWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_week'],
      )!,
      currentSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_session_id'],
      ),
      currentPhase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_phase'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ActiveCyclesTable createAlias(String alias) {
    return $ActiveCyclesTable(attachedDatabase, alias);
  }
}

class ActiveCycle extends DataClass implements Insertable<ActiveCycle> {
  final int id;
  final int userId;
  final String programId;
  final String cycleName;
  final DateTime startDate;
  final int currentWeek;
  final String? currentSessionId;
  final String? currentPhase;
  final String status;
  const ActiveCycle({
    required this.id,
    required this.userId,
    required this.programId,
    required this.cycleName,
    required this.startDate,
    required this.currentWeek,
    this.currentSessionId,
    this.currentPhase,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['program_id'] = Variable<String>(programId);
    map['cycle_name'] = Variable<String>(cycleName);
    map['start_date'] = Variable<DateTime>(startDate);
    map['current_week'] = Variable<int>(currentWeek);
    if (!nullToAbsent || currentSessionId != null) {
      map['current_session_id'] = Variable<String>(currentSessionId);
    }
    if (!nullToAbsent || currentPhase != null) {
      map['current_phase'] = Variable<String>(currentPhase);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  ActiveCyclesCompanion toCompanion(bool nullToAbsent) {
    return ActiveCyclesCompanion(
      id: Value(id),
      userId: Value(userId),
      programId: Value(programId),
      cycleName: Value(cycleName),
      startDate: Value(startDate),
      currentWeek: Value(currentWeek),
      currentSessionId: currentSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentSessionId),
      currentPhase: currentPhase == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPhase),
      status: Value(status),
    );
  }

  factory ActiveCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveCycle(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      programId: serializer.fromJson<String>(json['programId']),
      cycleName: serializer.fromJson<String>(json['cycleName']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      currentWeek: serializer.fromJson<int>(json['currentWeek']),
      currentSessionId: serializer.fromJson<String?>(json['currentSessionId']),
      currentPhase: serializer.fromJson<String?>(json['currentPhase']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'programId': serializer.toJson<String>(programId),
      'cycleName': serializer.toJson<String>(cycleName),
      'startDate': serializer.toJson<DateTime>(startDate),
      'currentWeek': serializer.toJson<int>(currentWeek),
      'currentSessionId': serializer.toJson<String?>(currentSessionId),
      'currentPhase': serializer.toJson<String?>(currentPhase),
      'status': serializer.toJson<String>(status),
    };
  }

  ActiveCycle copyWith({
    int? id,
    int? userId,
    String? programId,
    String? cycleName,
    DateTime? startDate,
    int? currentWeek,
    Value<String?> currentSessionId = const Value.absent(),
    Value<String?> currentPhase = const Value.absent(),
    String? status,
  }) => ActiveCycle(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    programId: programId ?? this.programId,
    cycleName: cycleName ?? this.cycleName,
    startDate: startDate ?? this.startDate,
    currentWeek: currentWeek ?? this.currentWeek,
    currentSessionId: currentSessionId.present
        ? currentSessionId.value
        : this.currentSessionId,
    currentPhase: currentPhase.present ? currentPhase.value : this.currentPhase,
    status: status ?? this.status,
  );
  ActiveCycle copyWithCompanion(ActiveCyclesCompanion data) {
    return ActiveCycle(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      programId: data.programId.present ? data.programId.value : this.programId,
      cycleName: data.cycleName.present ? data.cycleName.value : this.cycleName,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      currentWeek: data.currentWeek.present
          ? data.currentWeek.value
          : this.currentWeek,
      currentSessionId: data.currentSessionId.present
          ? data.currentSessionId.value
          : this.currentSessionId,
      currentPhase: data.currentPhase.present
          ? data.currentPhase.value
          : this.currentPhase,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveCycle(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('programId: $programId, ')
          ..write('cycleName: $cycleName, ')
          ..write('startDate: $startDate, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('currentSessionId: $currentSessionId, ')
          ..write('currentPhase: $currentPhase, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    programId,
    cycleName,
    startDate,
    currentWeek,
    currentSessionId,
    currentPhase,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveCycle &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.programId == this.programId &&
          other.cycleName == this.cycleName &&
          other.startDate == this.startDate &&
          other.currentWeek == this.currentWeek &&
          other.currentSessionId == this.currentSessionId &&
          other.currentPhase == this.currentPhase &&
          other.status == this.status);
}

class ActiveCyclesCompanion extends UpdateCompanion<ActiveCycle> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> programId;
  final Value<String> cycleName;
  final Value<DateTime> startDate;
  final Value<int> currentWeek;
  final Value<String?> currentSessionId;
  final Value<String?> currentPhase;
  final Value<String> status;
  const ActiveCyclesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.programId = const Value.absent(),
    this.cycleName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.currentWeek = const Value.absent(),
    this.currentSessionId = const Value.absent(),
    this.currentPhase = const Value.absent(),
    this.status = const Value.absent(),
  });
  ActiveCyclesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String programId,
    required String cycleName,
    required DateTime startDate,
    this.currentWeek = const Value.absent(),
    this.currentSessionId = const Value.absent(),
    this.currentPhase = const Value.absent(),
    this.status = const Value.absent(),
  }) : userId = Value(userId),
       programId = Value(programId),
       cycleName = Value(cycleName),
       startDate = Value(startDate);
  static Insertable<ActiveCycle> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? programId,
    Expression<String>? cycleName,
    Expression<DateTime>? startDate,
    Expression<int>? currentWeek,
    Expression<String>? currentSessionId,
    Expression<String>? currentPhase,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (programId != null) 'program_id': programId,
      if (cycleName != null) 'cycle_name': cycleName,
      if (startDate != null) 'start_date': startDate,
      if (currentWeek != null) 'current_week': currentWeek,
      if (currentSessionId != null) 'current_session_id': currentSessionId,
      if (currentPhase != null) 'current_phase': currentPhase,
      if (status != null) 'status': status,
    });
  }

  ActiveCyclesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? programId,
    Value<String>? cycleName,
    Value<DateTime>? startDate,
    Value<int>? currentWeek,
    Value<String?>? currentSessionId,
    Value<String?>? currentPhase,
    Value<String>? status,
  }) {
    return ActiveCyclesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      programId: programId ?? this.programId,
      cycleName: cycleName ?? this.cycleName,
      startDate: startDate ?? this.startDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      currentPhase: currentPhase ?? this.currentPhase,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (cycleName.present) {
      map['cycle_name'] = Variable<String>(cycleName.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (currentWeek.present) {
      map['current_week'] = Variable<int>(currentWeek.value);
    }
    if (currentSessionId.present) {
      map['current_session_id'] = Variable<String>(currentSessionId.value);
    }
    if (currentPhase.present) {
      map['current_phase'] = Variable<String>(currentPhase.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveCyclesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('programId: $programId, ')
          ..write('cycleName: $cycleName, ')
          ..write('startDate: $startDate, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('currentSessionId: $currentSessionId, ')
          ..write('currentPhase: $currentPhase, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $CompletedWorkoutsTable extends CompletedWorkouts
    with TableInfo<$CompletedWorkoutsTable, CompletedWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedWorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _activeCycleIdMeta = const VerificationMeta(
    'activeCycleId',
  );
  @override
  late final GeneratedColumn<int> activeCycleId = GeneratedColumn<int>(
    'active_cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES active_cycles (id)',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekMeta = const VerificationMeta('week');
  @override
  late final GeneratedColumn<int> week = GeneratedColumn<int>(
    'week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    activeCycleId,
    programId,
    week,
    day,
    sessionId,
    completedAt,
    duration,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedWorkout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('active_cycle_id')) {
      context.handle(
        _activeCycleIdMeta,
        activeCycleId.isAcceptableOrUnknown(
          data['active_cycle_id']!,
          _activeCycleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeCycleIdMeta);
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('week')) {
      context.handle(
        _weekMeta,
        week.isAcceptableOrUnknown(data['week']!, _weekMeta),
      );
    } else if (isInserting) {
      context.missing(_weekMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletedWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedWorkout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      activeCycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_cycle_id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      week: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $CompletedWorkoutsTable createAlias(String alias) {
    return $CompletedWorkoutsTable(attachedDatabase, alias);
  }
}

class CompletedWorkout extends DataClass
    implements Insertable<CompletedWorkout> {
  final int id;
  final int userId;
  final int activeCycleId;
  final String programId;
  final int week;
  final int? day;
  final String? sessionId;
  final DateTime completedAt;
  final int? duration;
  final String? notes;
  const CompletedWorkout({
    required this.id,
    required this.userId,
    required this.activeCycleId,
    required this.programId,
    required this.week,
    this.day,
    this.sessionId,
    required this.completedAt,
    this.duration,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['active_cycle_id'] = Variable<int>(activeCycleId);
    map['program_id'] = Variable<String>(programId);
    map['week'] = Variable<int>(week);
    if (!nullToAbsent || day != null) {
      map['day'] = Variable<int>(day);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CompletedWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return CompletedWorkoutsCompanion(
      id: Value(id),
      userId: Value(userId),
      activeCycleId: Value(activeCycleId),
      programId: Value(programId),
      week: Value(week),
      day: day == null && nullToAbsent ? const Value.absent() : Value(day),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      completedAt: Value(completedAt),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory CompletedWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedWorkout(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      activeCycleId: serializer.fromJson<int>(json['activeCycleId']),
      programId: serializer.fromJson<String>(json['programId']),
      week: serializer.fromJson<int>(json['week']),
      day: serializer.fromJson<int?>(json['day']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      duration: serializer.fromJson<int?>(json['duration']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'activeCycleId': serializer.toJson<int>(activeCycleId),
      'programId': serializer.toJson<String>(programId),
      'week': serializer.toJson<int>(week),
      'day': serializer.toJson<int?>(day),
      'sessionId': serializer.toJson<String?>(sessionId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'duration': serializer.toJson<int?>(duration),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CompletedWorkout copyWith({
    int? id,
    int? userId,
    int? activeCycleId,
    String? programId,
    int? week,
    Value<int?> day = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    DateTime? completedAt,
    Value<int?> duration = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => CompletedWorkout(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    activeCycleId: activeCycleId ?? this.activeCycleId,
    programId: programId ?? this.programId,
    week: week ?? this.week,
    day: day.present ? day.value : this.day,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    completedAt: completedAt ?? this.completedAt,
    duration: duration.present ? duration.value : this.duration,
    notes: notes.present ? notes.value : this.notes,
  );
  CompletedWorkout copyWithCompanion(CompletedWorkoutsCompanion data) {
    return CompletedWorkout(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      activeCycleId: data.activeCycleId.present
          ? data.activeCycleId.value
          : this.activeCycleId,
      programId: data.programId.present ? data.programId.value : this.programId,
      week: data.week.present ? data.week.value : this.week,
      day: data.day.present ? data.day.value : this.day,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      duration: data.duration.present ? data.duration.value : this.duration,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedWorkout(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('activeCycleId: $activeCycleId, ')
          ..write('programId: $programId, ')
          ..write('week: $week, ')
          ..write('day: $day, ')
          ..write('sessionId: $sessionId, ')
          ..write('completedAt: $completedAt, ')
          ..write('duration: $duration, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    activeCycleId,
    programId,
    week,
    day,
    sessionId,
    completedAt,
    duration,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedWorkout &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.activeCycleId == this.activeCycleId &&
          other.programId == this.programId &&
          other.week == this.week &&
          other.day == this.day &&
          other.sessionId == this.sessionId &&
          other.completedAt == this.completedAt &&
          other.duration == this.duration &&
          other.notes == this.notes);
}

class CompletedWorkoutsCompanion extends UpdateCompanion<CompletedWorkout> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> activeCycleId;
  final Value<String> programId;
  final Value<int> week;
  final Value<int?> day;
  final Value<String?> sessionId;
  final Value<DateTime> completedAt;
  final Value<int?> duration;
  final Value<String?> notes;
  const CompletedWorkoutsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.activeCycleId = const Value.absent(),
    this.programId = const Value.absent(),
    this.week = const Value.absent(),
    this.day = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.duration = const Value.absent(),
    this.notes = const Value.absent(),
  });
  CompletedWorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int activeCycleId,
    required String programId,
    required int week,
    this.day = const Value.absent(),
    this.sessionId = const Value.absent(),
    required DateTime completedAt,
    this.duration = const Value.absent(),
    this.notes = const Value.absent(),
  }) : userId = Value(userId),
       activeCycleId = Value(activeCycleId),
       programId = Value(programId),
       week = Value(week),
       completedAt = Value(completedAt);
  static Insertable<CompletedWorkout> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? activeCycleId,
    Expression<String>? programId,
    Expression<int>? week,
    Expression<int>? day,
    Expression<String>? sessionId,
    Expression<DateTime>? completedAt,
    Expression<int>? duration,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (activeCycleId != null) 'active_cycle_id': activeCycleId,
      if (programId != null) 'program_id': programId,
      if (week != null) 'week': week,
      if (day != null) 'day': day,
      if (sessionId != null) 'session_id': sessionId,
      if (completedAt != null) 'completed_at': completedAt,
      if (duration != null) 'duration': duration,
      if (notes != null) 'notes': notes,
    });
  }

  CompletedWorkoutsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? activeCycleId,
    Value<String>? programId,
    Value<int>? week,
    Value<int?>? day,
    Value<String?>? sessionId,
    Value<DateTime>? completedAt,
    Value<int?>? duration,
    Value<String?>? notes,
  }) {
    return CompletedWorkoutsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activeCycleId: activeCycleId ?? this.activeCycleId,
      programId: programId ?? this.programId,
      week: week ?? this.week,
      day: day ?? this.day,
      sessionId: sessionId ?? this.sessionId,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (activeCycleId.present) {
      map['active_cycle_id'] = Variable<int>(activeCycleId.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (week.present) {
      map['week'] = Variable<int>(week.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('activeCycleId: $activeCycleId, ')
          ..write('programId: $programId, ')
          ..write('week: $week, ')
          ..write('day: $day, ')
          ..write('sessionId: $sessionId, ')
          ..write('completedAt: $completedAt, ')
          ..write('duration: $duration, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $CompletedSetsTable extends CompletedSets
    with TableInfo<$CompletedSetsTable, CompletedSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completed_workouts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
    'set_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescribedWeightMeta = const VerificationMeta(
    'prescribedWeight',
  );
  @override
  late final GeneratedColumn<double> prescribedWeight = GeneratedColumn<double>(
    'prescribed_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualWeightMeta = const VerificationMeta(
    'actualWeight',
  );
  @override
  late final GeneratedColumn<double> actualWeight = GeneratedColumn<double>(
    'actual_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescribedRepsMeta = const VerificationMeta(
    'prescribedReps',
  );
  @override
  late final GeneratedColumn<int> prescribedReps = GeneratedColumn<int>(
    'prescribed_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualRepsMeta = const VerificationMeta(
    'actualReps',
  );
  @override
  late final GeneratedColumn<int> actualReps = GeneratedColumn<int>(
    'actual_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<int> rpe = GeneratedColumn<int>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideReasonMeta = const VerificationMeta(
    'overrideReason',
  );
  @override
  late final GeneratedColumn<String> overrideReason = GeneratedColumn<String>(
    'override_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    exerciseId,
    setNumber,
    prescribedWeight,
    actualWeight,
    prescribedReps,
    actualReps,
    rpe,
    restSeconds,
    overrideReason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('prescribed_weight')) {
      context.handle(
        _prescribedWeightMeta,
        prescribedWeight.isAcceptableOrUnknown(
          data['prescribed_weight']!,
          _prescribedWeightMeta,
        ),
      );
    }
    if (data.containsKey('actual_weight')) {
      context.handle(
        _actualWeightMeta,
        actualWeight.isAcceptableOrUnknown(
          data['actual_weight']!,
          _actualWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualWeightMeta);
    }
    if (data.containsKey('prescribed_reps')) {
      context.handle(
        _prescribedRepsMeta,
        prescribedReps.isAcceptableOrUnknown(
          data['prescribed_reps']!,
          _prescribedRepsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prescribedRepsMeta);
    }
    if (data.containsKey('actual_reps')) {
      context.handle(
        _actualRepsMeta,
        actualReps.isAcceptableOrUnknown(data['actual_reps']!, _actualRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_actualRepsMeta);
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    }
    if (data.containsKey('override_reason')) {
      context.handle(
        _overrideReasonMeta,
        overrideReason.isAcceptableOrUnknown(
          data['override_reason']!,
          _overrideReasonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletedSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_number'],
      )!,
      prescribedWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prescribed_weight'],
      ),
      actualWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_weight'],
      )!,
      prescribedReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prescribed_reps'],
      )!,
      actualReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_reps'],
      )!,
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe'],
      ),
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      ),
      overrideReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CompletedSetsTable createAlias(String alias) {
    return $CompletedSetsTable(attachedDatabase, alias);
  }
}

class CompletedSet extends DataClass implements Insertable<CompletedSet> {
  final int id;
  final int workoutId;
  final String exerciseId;
  final int setNumber;
  final double? prescribedWeight;
  final double actualWeight;
  final int prescribedReps;
  final int actualReps;
  final int? rpe;
  final int? restSeconds;
  final String? overrideReason;
  final DateTime createdAt;
  const CompletedSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    this.prescribedWeight,
    required this.actualWeight,
    required this.prescribedReps,
    required this.actualReps,
    this.rpe,
    this.restSeconds,
    this.overrideReason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_number'] = Variable<int>(setNumber);
    if (!nullToAbsent || prescribedWeight != null) {
      map['prescribed_weight'] = Variable<double>(prescribedWeight);
    }
    map['actual_weight'] = Variable<double>(actualWeight);
    map['prescribed_reps'] = Variable<int>(prescribedReps);
    map['actual_reps'] = Variable<int>(actualReps);
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<int>(rpe);
    }
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    if (!nullToAbsent || overrideReason != null) {
      map['override_reason'] = Variable<String>(overrideReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CompletedSetsCompanion toCompanion(bool nullToAbsent) {
    return CompletedSetsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      setNumber: Value(setNumber),
      prescribedWeight: prescribedWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(prescribedWeight),
      actualWeight: Value(actualWeight),
      prescribedReps: Value(prescribedReps),
      actualReps: Value(actualReps),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      overrideReason: overrideReason == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideReason),
      createdAt: Value(createdAt),
    );
  }

  factory CompletedSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedSet(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      prescribedWeight: serializer.fromJson<double?>(json['prescribedWeight']),
      actualWeight: serializer.fromJson<double>(json['actualWeight']),
      prescribedReps: serializer.fromJson<int>(json['prescribedReps']),
      actualReps: serializer.fromJson<int>(json['actualReps']),
      rpe: serializer.fromJson<int?>(json['rpe']),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      overrideReason: serializer.fromJson<String?>(json['overrideReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setNumber': serializer.toJson<int>(setNumber),
      'prescribedWeight': serializer.toJson<double?>(prescribedWeight),
      'actualWeight': serializer.toJson<double>(actualWeight),
      'prescribedReps': serializer.toJson<int>(prescribedReps),
      'actualReps': serializer.toJson<int>(actualReps),
      'rpe': serializer.toJson<int?>(rpe),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'overrideReason': serializer.toJson<String?>(overrideReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CompletedSet copyWith({
    int? id,
    int? workoutId,
    String? exerciseId,
    int? setNumber,
    Value<double?> prescribedWeight = const Value.absent(),
    double? actualWeight,
    int? prescribedReps,
    int? actualReps,
    Value<int?> rpe = const Value.absent(),
    Value<int?> restSeconds = const Value.absent(),
    Value<String?> overrideReason = const Value.absent(),
    DateTime? createdAt,
  }) => CompletedSet(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    setNumber: setNumber ?? this.setNumber,
    prescribedWeight: prescribedWeight.present
        ? prescribedWeight.value
        : this.prescribedWeight,
    actualWeight: actualWeight ?? this.actualWeight,
    prescribedReps: prescribedReps ?? this.prescribedReps,
    actualReps: actualReps ?? this.actualReps,
    rpe: rpe.present ? rpe.value : this.rpe,
    restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
    overrideReason: overrideReason.present
        ? overrideReason.value
        : this.overrideReason,
    createdAt: createdAt ?? this.createdAt,
  );
  CompletedSet copyWithCompanion(CompletedSetsCompanion data) {
    return CompletedSet(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      prescribedWeight: data.prescribedWeight.present
          ? data.prescribedWeight.value
          : this.prescribedWeight,
      actualWeight: data.actualWeight.present
          ? data.actualWeight.value
          : this.actualWeight,
      prescribedReps: data.prescribedReps.present
          ? data.prescribedReps.value
          : this.prescribedReps,
      actualReps: data.actualReps.present
          ? data.actualReps.value
          : this.actualReps,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
      overrideReason: data.overrideReason.present
          ? data.overrideReason.value
          : this.overrideReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedSet(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('prescribedWeight: $prescribedWeight, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('prescribedReps: $prescribedReps, ')
          ..write('actualReps: $actualReps, ')
          ..write('rpe: $rpe, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('overrideReason: $overrideReason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    exerciseId,
    setNumber,
    prescribedWeight,
    actualWeight,
    prescribedReps,
    actualReps,
    rpe,
    restSeconds,
    overrideReason,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedSet &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.setNumber == this.setNumber &&
          other.prescribedWeight == this.prescribedWeight &&
          other.actualWeight == this.actualWeight &&
          other.prescribedReps == this.prescribedReps &&
          other.actualReps == this.actualReps &&
          other.rpe == this.rpe &&
          other.restSeconds == this.restSeconds &&
          other.overrideReason == this.overrideReason &&
          other.createdAt == this.createdAt);
}

class CompletedSetsCompanion extends UpdateCompanion<CompletedSet> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<String> exerciseId;
  final Value<int> setNumber;
  final Value<double?> prescribedWeight;
  final Value<double> actualWeight;
  final Value<int> prescribedReps;
  final Value<int> actualReps;
  final Value<int?> rpe;
  final Value<int?> restSeconds;
  final Value<String?> overrideReason;
  final Value<DateTime> createdAt;
  const CompletedSetsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.prescribedWeight = const Value.absent(),
    this.actualWeight = const Value.absent(),
    this.prescribedReps = const Value.absent(),
    this.actualReps = const Value.absent(),
    this.rpe = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.overrideReason = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CompletedSetsCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    required String exerciseId,
    required int setNumber,
    this.prescribedWeight = const Value.absent(),
    required double actualWeight,
    required int prescribedReps,
    required int actualReps,
    this.rpe = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.overrideReason = const Value.absent(),
    required DateTime createdAt,
  }) : workoutId = Value(workoutId),
       exerciseId = Value(exerciseId),
       setNumber = Value(setNumber),
       actualWeight = Value(actualWeight),
       prescribedReps = Value(prescribedReps),
       actualReps = Value(actualReps),
       createdAt = Value(createdAt);
  static Insertable<CompletedSet> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? setNumber,
    Expression<double>? prescribedWeight,
    Expression<double>? actualWeight,
    Expression<int>? prescribedReps,
    Expression<int>? actualReps,
    Expression<int>? rpe,
    Expression<int>? restSeconds,
    Expression<String>? overrideReason,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setNumber != null) 'set_number': setNumber,
      if (prescribedWeight != null) 'prescribed_weight': prescribedWeight,
      if (actualWeight != null) 'actual_weight': actualWeight,
      if (prescribedReps != null) 'prescribed_reps': prescribedReps,
      if (actualReps != null) 'actual_reps': actualReps,
      if (rpe != null) 'rpe': rpe,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (overrideReason != null) 'override_reason': overrideReason,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CompletedSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutId,
    Value<String>? exerciseId,
    Value<int>? setNumber,
    Value<double?>? prescribedWeight,
    Value<double>? actualWeight,
    Value<int>? prescribedReps,
    Value<int>? actualReps,
    Value<int?>? rpe,
    Value<int?>? restSeconds,
    Value<String?>? overrideReason,
    Value<DateTime>? createdAt,
  }) {
    return CompletedSetsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      prescribedWeight: prescribedWeight ?? this.prescribedWeight,
      actualWeight: actualWeight ?? this.actualWeight,
      prescribedReps: prescribedReps ?? this.prescribedReps,
      actualReps: actualReps ?? this.actualReps,
      rpe: rpe ?? this.rpe,
      restSeconds: restSeconds ?? this.restSeconds,
      overrideReason: overrideReason ?? this.overrideReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (prescribedWeight.present) {
      map['prescribed_weight'] = Variable<double>(prescribedWeight.value);
    }
    if (actualWeight.present) {
      map['actual_weight'] = Variable<double>(actualWeight.value);
    }
    if (prescribedReps.present) {
      map['prescribed_reps'] = Variable<int>(prescribedReps.value);
    }
    if (actualReps.present) {
      map['actual_reps'] = Variable<int>(actualReps.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<int>(rpe.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (overrideReason.present) {
      map['override_reason'] = Variable<String>(overrideReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedSetsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('prescribedWeight: $prescribedWeight, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('prescribedReps: $prescribedReps, ')
          ..write('actualReps: $actualReps, ')
          ..write('rpe: $rpe, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('overrideReason: $overrideReason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OneRepMaxesTable extends OneRepMaxes
    with TableInfo<$OneRepMaxesTable, OneRepMaxe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OneRepMaxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, userId, exerciseId, weight, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'one_rep_maxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<OneRepMaxe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OneRepMaxe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OneRepMaxe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $OneRepMaxesTable createAlias(String alias) {
    return $OneRepMaxesTable(attachedDatabase, alias);
  }
}

class OneRepMaxe extends DataClass implements Insertable<OneRepMaxe> {
  final int id;
  final int userId;
  final String exerciseId;
  final double weight;
  final DateTime date;
  const OneRepMaxe({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.weight,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['weight'] = Variable<double>(weight);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  OneRepMaxesCompanion toCompanion(bool nullToAbsent) {
    return OneRepMaxesCompanion(
      id: Value(id),
      userId: Value(userId),
      exerciseId: Value(exerciseId),
      weight: Value(weight),
      date: Value(date),
    );
  }

  factory OneRepMaxe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OneRepMaxe(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      weight: serializer.fromJson<double>(json['weight']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'weight': serializer.toJson<double>(weight),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  OneRepMaxe copyWith({
    int? id,
    int? userId,
    String? exerciseId,
    double? weight,
    DateTime? date,
  }) => OneRepMaxe(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    exerciseId: exerciseId ?? this.exerciseId,
    weight: weight ?? this.weight,
    date: date ?? this.date,
  );
  OneRepMaxe copyWithCompanion(OneRepMaxesCompanion data) {
    return OneRepMaxe(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      weight: data.weight.present ? data.weight.value : this.weight,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OneRepMaxe(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('weight: $weight, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, exerciseId, weight, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OneRepMaxe &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.exerciseId == this.exerciseId &&
          other.weight == this.weight &&
          other.date == this.date);
}

class OneRepMaxesCompanion extends UpdateCompanion<OneRepMaxe> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> exerciseId;
  final Value<double> weight;
  final Value<DateTime> date;
  const OneRepMaxesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.weight = const Value.absent(),
    this.date = const Value.absent(),
  });
  OneRepMaxesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String exerciseId,
    required double weight,
    required DateTime date,
  }) : userId = Value(userId),
       exerciseId = Value(exerciseId),
       weight = Value(weight),
       date = Value(date);
  static Insertable<OneRepMaxe> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? exerciseId,
    Expression<double>? weight,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (weight != null) 'weight': weight,
      if (date != null) 'date': date,
    });
  }

  OneRepMaxesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? exerciseId,
    Value<double>? weight,
    Value<DateTime>? date,
  }) {
    return OneRepMaxesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      weight: weight ?? this.weight,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OneRepMaxesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('weight: $weight, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $PersonalRecordsTable extends PersonalRecords
    with TableInfo<$PersonalRecordsTable, PersonalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completed_workouts (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    exerciseId,
    type,
    value,
    workoutId,
    date,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $PersonalRecordsTable createAlias(String alias) {
    return $PersonalRecordsTable(attachedDatabase, alias);
  }
}

class PersonalRecord extends DataClass implements Insertable<PersonalRecord> {
  final int id;
  final int userId;
  final String exerciseId;
  final String type;
  final double value;
  final int workoutId;
  final DateTime date;
  const PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.type,
    required this.value,
    required this.workoutId,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['type'] = Variable<String>(type);
    map['value'] = Variable<double>(value);
    map['workout_id'] = Variable<int>(workoutId);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  PersonalRecordsCompanion toCompanion(bool nullToAbsent) {
    return PersonalRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      exerciseId: Value(exerciseId),
      type: Value(type),
      value: Value(value),
      workoutId: Value(workoutId),
      date: Value(date),
    );
  }

  factory PersonalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalRecord(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<double>(json['value']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<double>(value),
      'workoutId': serializer.toJson<int>(workoutId),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  PersonalRecord copyWith({
    int? id,
    int? userId,
    String? exerciseId,
    String? type,
    double? value,
    int? workoutId,
    DateTime? date,
  }) => PersonalRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    exerciseId: exerciseId ?? this.exerciseId,
    type: type ?? this.type,
    value: value ?? this.value,
    workoutId: workoutId ?? this.workoutId,
    date: date ?? this.date,
  );
  PersonalRecord copyWithCompanion(PersonalRecordsCompanion data) {
    return PersonalRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('workoutId: $workoutId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, exerciseId, type, value, workoutId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.exerciseId == this.exerciseId &&
          other.type == this.type &&
          other.value == this.value &&
          other.workoutId == this.workoutId &&
          other.date == this.date);
}

class PersonalRecordsCompanion extends UpdateCompanion<PersonalRecord> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> exerciseId;
  final Value<String> type;
  final Value<double> value;
  final Value<int> workoutId;
  final Value<DateTime> date;
  const PersonalRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.date = const Value.absent(),
  });
  PersonalRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String exerciseId,
    required String type,
    required double value,
    required int workoutId,
    required DateTime date,
  }) : userId = Value(userId),
       exerciseId = Value(exerciseId),
       type = Value(type),
       value = Value(value),
       workoutId = Value(workoutId),
       date = Value(date);
  static Insertable<PersonalRecord> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? exerciseId,
    Expression<String>? type,
    Expression<double>? value,
    Expression<int>? workoutId,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (workoutId != null) 'workout_id': workoutId,
      if (date != null) 'date': date,
    });
  }

  PersonalRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? exerciseId,
    Value<String>? type,
    Value<double>? value,
    Value<int>? workoutId,
    Value<DateTime>? date,
  }) {
    return PersonalRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      type: type ?? this.type,
      value: value ?? this.value,
      workoutId: workoutId ?? this.workoutId,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('workoutId: $workoutId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ActiveCyclesTable activeCycles = $ActiveCyclesTable(this);
  late final $CompletedWorkoutsTable completedWorkouts =
      $CompletedWorkoutsTable(this);
  late final $CompletedSetsTable completedSets = $CompletedSetsTable(this);
  late final $OneRepMaxesTable oneRepMaxes = $OneRepMaxesTable(this);
  late final $PersonalRecordsTable personalRecords = $PersonalRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    activeCycles,
    completedWorkouts,
    completedSets,
    oneRepMaxes,
    personalRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'completed_workouts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('completed_sets', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String name,
      required String experienceLevel,
      required String goal,
      Value<DateTime> createdAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> experienceLevel,
      Value<String> goal,
      Value<DateTime> createdAt,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ActiveCyclesTable, List<ActiveCycle>>
  _activeCyclesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.activeCycles,
    aliasName: $_aliasNameGenerator(db.users.id, db.activeCycles.userId),
  );

  $$ActiveCyclesTableProcessedTableManager get activeCyclesRefs {
    final manager = $$ActiveCyclesTableTableManager(
      $_db,
      $_db.activeCycles,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_activeCyclesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompletedWorkoutsTable, List<CompletedWorkout>>
  _completedWorkoutsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completedWorkouts,
        aliasName: $_aliasNameGenerator(
          db.users.id,
          db.completedWorkouts.userId,
        ),
      );

  $$CompletedWorkoutsTableProcessedTableManager get completedWorkoutsRefs {
    final manager = $$CompletedWorkoutsTableTableManager(
      $_db,
      $_db.completedWorkouts,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _completedWorkoutsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OneRepMaxesTable, List<OneRepMaxe>>
  _oneRepMaxesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.oneRepMaxes,
    aliasName: $_aliasNameGenerator(db.users.id, db.oneRepMaxes.userId),
  );

  $$OneRepMaxesTableProcessedTableManager get oneRepMaxesRefs {
    final manager = $$OneRepMaxesTableTableManager(
      $_db,
      $_db.oneRepMaxes,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_oneRepMaxesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonalRecordsTable, List<PersonalRecord>>
  _personalRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personalRecords,
    aliasName: $_aliasNameGenerator(db.users.id, db.personalRecords.userId),
  );

  $$PersonalRecordsTableProcessedTableManager get personalRecordsRefs {
    final manager = $$PersonalRecordsTableTableManager(
      $_db,
      $_db.personalRecords,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _personalRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get experienceLevel => $composableBuilder(
    column: $table.experienceLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> activeCyclesRefs(
    Expression<bool> Function($$ActiveCyclesTableFilterComposer f) f,
  ) {
    final $$ActiveCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activeCycles,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActiveCyclesTableFilterComposer(
            $db: $db,
            $table: $db.activeCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> completedWorkoutsRefs(
    Expression<bool> Function($$CompletedWorkoutsTableFilterComposer f) f,
  ) {
    final $$CompletedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> oneRepMaxesRefs(
    Expression<bool> Function($$OneRepMaxesTableFilterComposer f) f,
  ) {
    final $$OneRepMaxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.oneRepMaxes,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OneRepMaxesTableFilterComposer(
            $db: $db,
            $table: $db.oneRepMaxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personalRecordsRefs(
    Expression<bool> Function($$PersonalRecordsTableFilterComposer f) f,
  ) {
    final $$PersonalRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personalRecords,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalRecordsTableFilterComposer(
            $db: $db,
            $table: $db.personalRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get experienceLevel => $composableBuilder(
    column: $table.experienceLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get experienceLevel => $composableBuilder(
    column: $table.experienceLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> activeCyclesRefs<T extends Object>(
    Expression<T> Function($$ActiveCyclesTableAnnotationComposer a) f,
  ) {
    final $$ActiveCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activeCycles,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActiveCyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.activeCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> completedWorkoutsRefs<T extends Object>(
    Expression<T> Function($$CompletedWorkoutsTableAnnotationComposer a) f,
  ) {
    final $$CompletedWorkoutsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.completedWorkouts,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedWorkoutsTableAnnotationComposer(
                $db: $db,
                $table: $db.completedWorkouts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> oneRepMaxesRefs<T extends Object>(
    Expression<T> Function($$OneRepMaxesTableAnnotationComposer a) f,
  ) {
    final $$OneRepMaxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.oneRepMaxes,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OneRepMaxesTableAnnotationComposer(
            $db: $db,
            $table: $db.oneRepMaxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personalRecordsRefs<T extends Object>(
    Expression<T> Function($$PersonalRecordsTableAnnotationComposer a) f,
  ) {
    final $$PersonalRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personalRecords,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.personalRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({
            bool activeCyclesRefs,
            bool completedWorkoutsRefs,
            bool oneRepMaxesRefs,
            bool personalRecordsRefs,
          })
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> experienceLevel = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                experienceLevel: experienceLevel,
                goal: goal,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String experienceLevel,
                required String goal,
                Value<DateTime> createdAt = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                experienceLevel: experienceLevel,
                goal: goal,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                activeCyclesRefs = false,
                completedWorkoutsRefs = false,
                oneRepMaxesRefs = false,
                personalRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (activeCyclesRefs) db.activeCycles,
                    if (completedWorkoutsRefs) db.completedWorkouts,
                    if (oneRepMaxesRefs) db.oneRepMaxes,
                    if (personalRecordsRefs) db.personalRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (activeCyclesRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          ActiveCycle
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._activeCyclesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).activeCyclesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (completedWorkoutsRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          CompletedWorkout
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._completedWorkoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).completedWorkoutsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (oneRepMaxesRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          OneRepMaxe
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._oneRepMaxesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).oneRepMaxesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (personalRecordsRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          PersonalRecord
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._personalRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).personalRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({
        bool activeCyclesRefs,
        bool completedWorkoutsRefs,
        bool oneRepMaxesRefs,
        bool personalRecordsRefs,
      })
    >;
typedef $$ActiveCyclesTableCreateCompanionBuilder =
    ActiveCyclesCompanion Function({
      Value<int> id,
      required int userId,
      required String programId,
      required String cycleName,
      required DateTime startDate,
      Value<int> currentWeek,
      Value<String?> currentSessionId,
      Value<String?> currentPhase,
      Value<String> status,
    });
typedef $$ActiveCyclesTableUpdateCompanionBuilder =
    ActiveCyclesCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> programId,
      Value<String> cycleName,
      Value<DateTime> startDate,
      Value<int> currentWeek,
      Value<String?> currentSessionId,
      Value<String?> currentPhase,
      Value<String> status,
    });

final class $$ActiveCyclesTableReferences
    extends BaseReferences<_$AppDatabase, $ActiveCyclesTable, ActiveCycle> {
  $$ActiveCyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.activeCycles.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CompletedWorkoutsTable, List<CompletedWorkout>>
  _completedWorkoutsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completedWorkouts,
        aliasName: $_aliasNameGenerator(
          db.activeCycles.id,
          db.completedWorkouts.activeCycleId,
        ),
      );

  $$CompletedWorkoutsTableProcessedTableManager get completedWorkoutsRefs {
    final manager = $$CompletedWorkoutsTableTableManager(
      $_db,
      $_db.completedWorkouts,
    ).filter((f) => f.activeCycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _completedWorkoutsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ActiveCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveCyclesTable> {
  $$ActiveCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleName => $composableBuilder(
    column: $table.cycleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentWeek => $composableBuilder(
    column: $table.currentWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentSessionId => $composableBuilder(
    column: $table.currentSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentPhase => $composableBuilder(
    column: $table.currentPhase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> completedWorkoutsRefs(
    Expression<bool> Function($$CompletedWorkoutsTableFilterComposer f) f,
  ) {
    final $$CompletedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.activeCycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ActiveCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveCyclesTable> {
  $$ActiveCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleName => $composableBuilder(
    column: $table.cycleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentWeek => $composableBuilder(
    column: $table.currentWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentSessionId => $composableBuilder(
    column: $table.currentSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentPhase => $composableBuilder(
    column: $table.currentPhase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActiveCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveCyclesTable> {
  $$ActiveCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<String> get cycleName =>
      $composableBuilder(column: $table.cycleName, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get currentWeek => $composableBuilder(
    column: $table.currentWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentSessionId => $composableBuilder(
    column: $table.currentSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentPhase => $composableBuilder(
    column: $table.currentPhase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> completedWorkoutsRefs<T extends Object>(
    Expression<T> Function($$CompletedWorkoutsTableAnnotationComposer a) f,
  ) {
    final $$CompletedWorkoutsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.completedWorkouts,
          getReferencedColumn: (t) => t.activeCycleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedWorkoutsTableAnnotationComposer(
                $db: $db,
                $table: $db.completedWorkouts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ActiveCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActiveCyclesTable,
          ActiveCycle,
          $$ActiveCyclesTableFilterComposer,
          $$ActiveCyclesTableOrderingComposer,
          $$ActiveCyclesTableAnnotationComposer,
          $$ActiveCyclesTableCreateCompanionBuilder,
          $$ActiveCyclesTableUpdateCompanionBuilder,
          (ActiveCycle, $$ActiveCyclesTableReferences),
          ActiveCycle,
          PrefetchHooks Function({bool userId, bool completedWorkoutsRefs})
        > {
  $$ActiveCyclesTableTableManager(_$AppDatabase db, $ActiveCyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<String> cycleName = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<int> currentWeek = const Value.absent(),
                Value<String?> currentSessionId = const Value.absent(),
                Value<String?> currentPhase = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => ActiveCyclesCompanion(
                id: id,
                userId: userId,
                programId: programId,
                cycleName: cycleName,
                startDate: startDate,
                currentWeek: currentWeek,
                currentSessionId: currentSessionId,
                currentPhase: currentPhase,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String programId,
                required String cycleName,
                required DateTime startDate,
                Value<int> currentWeek = const Value.absent(),
                Value<String?> currentSessionId = const Value.absent(),
                Value<String?> currentPhase = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => ActiveCyclesCompanion.insert(
                id: id,
                userId: userId,
                programId: programId,
                cycleName: cycleName,
                startDate: startDate,
                currentWeek: currentWeek,
                currentSessionId: currentSessionId,
                currentPhase: currentPhase,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ActiveCyclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, completedWorkoutsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completedWorkoutsRefs) db.completedWorkouts,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$ActiveCyclesTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$ActiveCyclesTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completedWorkoutsRefs)
                        await $_getPrefetchedData<
                          ActiveCycle,
                          $ActiveCyclesTable,
                          CompletedWorkout
                        >(
                          currentTable: table,
                          referencedTable: $$ActiveCyclesTableReferences
                              ._completedWorkoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ActiveCyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).completedWorkoutsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.activeCycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ActiveCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActiveCyclesTable,
      ActiveCycle,
      $$ActiveCyclesTableFilterComposer,
      $$ActiveCyclesTableOrderingComposer,
      $$ActiveCyclesTableAnnotationComposer,
      $$ActiveCyclesTableCreateCompanionBuilder,
      $$ActiveCyclesTableUpdateCompanionBuilder,
      (ActiveCycle, $$ActiveCyclesTableReferences),
      ActiveCycle,
      PrefetchHooks Function({bool userId, bool completedWorkoutsRefs})
    >;
typedef $$CompletedWorkoutsTableCreateCompanionBuilder =
    CompletedWorkoutsCompanion Function({
      Value<int> id,
      required int userId,
      required int activeCycleId,
      required String programId,
      required int week,
      Value<int?> day,
      Value<String?> sessionId,
      required DateTime completedAt,
      Value<int?> duration,
      Value<String?> notes,
    });
typedef $$CompletedWorkoutsTableUpdateCompanionBuilder =
    CompletedWorkoutsCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> activeCycleId,
      Value<String> programId,
      Value<int> week,
      Value<int?> day,
      Value<String?> sessionId,
      Value<DateTime> completedAt,
      Value<int?> duration,
      Value<String?> notes,
    });

final class $$CompletedWorkoutsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CompletedWorkoutsTable,
          CompletedWorkout
        > {
  $$CompletedWorkoutsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.completedWorkouts.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ActiveCyclesTable _activeCycleIdTable(_$AppDatabase db) =>
      db.activeCycles.createAlias(
        $_aliasNameGenerator(
          db.completedWorkouts.activeCycleId,
          db.activeCycles.id,
        ),
      );

  $$ActiveCyclesTableProcessedTableManager get activeCycleId {
    final $_column = $_itemColumn<int>('active_cycle_id')!;

    final manager = $$ActiveCyclesTableTableManager(
      $_db,
      $_db.activeCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_activeCycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CompletedSetsTable, List<CompletedSet>>
  _completedSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.completedSets,
    aliasName: $_aliasNameGenerator(
      db.completedWorkouts.id,
      db.completedSets.workoutId,
    ),
  );

  $$CompletedSetsTableProcessedTableManager get completedSetsRefs {
    final manager = $$CompletedSetsTableTableManager(
      $_db,
      $_db.completedSets,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_completedSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonalRecordsTable, List<PersonalRecord>>
  _personalRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personalRecords,
    aliasName: $_aliasNameGenerator(
      db.completedWorkouts.id,
      db.personalRecords.workoutId,
    ),
  );

  $$PersonalRecordsTableProcessedTableManager get personalRecordsRefs {
    final manager = $$PersonalRecordsTableTableManager(
      $_db,
      $_db.personalRecords,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _personalRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompletedWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedWorkoutsTable> {
  $$CompletedWorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ActiveCyclesTableFilterComposer get activeCycleId {
    final $$ActiveCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activeCycleId,
      referencedTable: $db.activeCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActiveCyclesTableFilterComposer(
            $db: $db,
            $table: $db.activeCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> completedSetsRefs(
    Expression<bool> Function($$CompletedSetsTableFilterComposer f) f,
  ) {
    final $$CompletedSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedSetsTableFilterComposer(
            $db: $db,
            $table: $db.completedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personalRecordsRefs(
    Expression<bool> Function($$PersonalRecordsTableFilterComposer f) f,
  ) {
    final $$PersonalRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personalRecords,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalRecordsTableFilterComposer(
            $db: $db,
            $table: $db.personalRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompletedWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedWorkoutsTable> {
  $$CompletedWorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ActiveCyclesTableOrderingComposer get activeCycleId {
    final $$ActiveCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activeCycleId,
      referencedTable: $db.activeCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActiveCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.activeCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedWorkoutsTable> {
  $$CompletedWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<int> get week =>
      $composableBuilder(column: $table.week, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ActiveCyclesTableAnnotationComposer get activeCycleId {
    final $$ActiveCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.activeCycleId,
      referencedTable: $db.activeCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActiveCyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.activeCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> completedSetsRefs<T extends Object>(
    Expression<T> Function($$CompletedSetsTableAnnotationComposer a) f,
  ) {
    final $$CompletedSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completedSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.completedSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personalRecordsRefs<T extends Object>(
    Expression<T> Function($$PersonalRecordsTableAnnotationComposer a) f,
  ) {
    final $$PersonalRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personalRecords,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.personalRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompletedWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedWorkoutsTable,
          CompletedWorkout,
          $$CompletedWorkoutsTableFilterComposer,
          $$CompletedWorkoutsTableOrderingComposer,
          $$CompletedWorkoutsTableAnnotationComposer,
          $$CompletedWorkoutsTableCreateCompanionBuilder,
          $$CompletedWorkoutsTableUpdateCompanionBuilder,
          (CompletedWorkout, $$CompletedWorkoutsTableReferences),
          CompletedWorkout,
          PrefetchHooks Function({
            bool userId,
            bool activeCycleId,
            bool completedSetsRefs,
            bool personalRecordsRefs,
          })
        > {
  $$CompletedWorkoutsTableTableManager(
    _$AppDatabase db,
    $CompletedWorkoutsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedWorkoutsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> activeCycleId = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<int> week = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => CompletedWorkoutsCompanion(
                id: id,
                userId: userId,
                activeCycleId: activeCycleId,
                programId: programId,
                week: week,
                day: day,
                sessionId: sessionId,
                completedAt: completedAt,
                duration: duration,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int activeCycleId,
                required String programId,
                required int week,
                Value<int?> day = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                required DateTime completedAt,
                Value<int?> duration = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => CompletedWorkoutsCompanion.insert(
                id: id,
                userId: userId,
                activeCycleId: activeCycleId,
                programId: programId,
                week: week,
                day: day,
                sessionId: sessionId,
                completedAt: completedAt,
                duration: duration,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletedWorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                userId = false,
                activeCycleId = false,
                completedSetsRefs = false,
                personalRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completedSetsRefs) db.completedSets,
                    if (personalRecordsRefs) db.personalRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$CompletedWorkoutsTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$CompletedWorkoutsTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (activeCycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.activeCycleId,
                                    referencedTable:
                                        $$CompletedWorkoutsTableReferences
                                            ._activeCycleIdTable(db),
                                    referencedColumn:
                                        $$CompletedWorkoutsTableReferences
                                            ._activeCycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completedSetsRefs)
                        await $_getPrefetchedData<
                          CompletedWorkout,
                          $CompletedWorkoutsTable,
                          CompletedSet
                        >(
                          currentTable: table,
                          referencedTable: $$CompletedWorkoutsTableReferences
                              ._completedSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletedWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).completedSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (personalRecordsRefs)
                        await $_getPrefetchedData<
                          CompletedWorkout,
                          $CompletedWorkoutsTable,
                          PersonalRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CompletedWorkoutsTableReferences
                              ._personalRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletedWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).personalRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CompletedWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedWorkoutsTable,
      CompletedWorkout,
      $$CompletedWorkoutsTableFilterComposer,
      $$CompletedWorkoutsTableOrderingComposer,
      $$CompletedWorkoutsTableAnnotationComposer,
      $$CompletedWorkoutsTableCreateCompanionBuilder,
      $$CompletedWorkoutsTableUpdateCompanionBuilder,
      (CompletedWorkout, $$CompletedWorkoutsTableReferences),
      CompletedWorkout,
      PrefetchHooks Function({
        bool userId,
        bool activeCycleId,
        bool completedSetsRefs,
        bool personalRecordsRefs,
      })
    >;
typedef $$CompletedSetsTableCreateCompanionBuilder =
    CompletedSetsCompanion Function({
      Value<int> id,
      required int workoutId,
      required String exerciseId,
      required int setNumber,
      Value<double?> prescribedWeight,
      required double actualWeight,
      required int prescribedReps,
      required int actualReps,
      Value<int?> rpe,
      Value<int?> restSeconds,
      Value<String?> overrideReason,
      required DateTime createdAt,
    });
typedef $$CompletedSetsTableUpdateCompanionBuilder =
    CompletedSetsCompanion Function({
      Value<int> id,
      Value<int> workoutId,
      Value<String> exerciseId,
      Value<int> setNumber,
      Value<double?> prescribedWeight,
      Value<double> actualWeight,
      Value<int> prescribedReps,
      Value<int> actualReps,
      Value<int?> rpe,
      Value<int?> restSeconds,
      Value<String?> overrideReason,
      Value<DateTime> createdAt,
    });

final class $$CompletedSetsTableReferences
    extends BaseReferences<_$AppDatabase, $CompletedSetsTable, CompletedSet> {
  $$CompletedSetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompletedWorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.completedWorkouts.createAlias(
        $_aliasNameGenerator(
          db.completedSets.workoutId,
          db.completedWorkouts.id,
        ),
      );

  $$CompletedWorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$CompletedWorkoutsTableTableManager(
      $_db,
      $_db.completedWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompletedSetsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedSetsTable> {
  $$CompletedSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get prescribedWeight => $composableBuilder(
    column: $table.prescribedWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prescribedReps => $composableBuilder(
    column: $table.prescribedReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CompletedWorkoutsTableFilterComposer get workoutId {
    final $$CompletedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedSetsTable> {
  $$CompletedSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get prescribedWeight => $composableBuilder(
    column: $table.prescribedWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prescribedReps => $composableBuilder(
    column: $table.prescribedReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletedWorkoutsTableOrderingComposer get workoutId {
    final $$CompletedWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletedSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedSetsTable> {
  $$CompletedSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<double> get prescribedWeight => $composableBuilder(
    column: $table.prescribedWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get actualWeight => $composableBuilder(
    column: $table.actualWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prescribedReps => $composableBuilder(
    column: $table.prescribedReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CompletedWorkoutsTableAnnotationComposer get workoutId {
    final $$CompletedWorkoutsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.workoutId,
          referencedTable: $db.completedWorkouts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedWorkoutsTableAnnotationComposer(
                $db: $db,
                $table: $db.completedWorkouts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CompletedSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedSetsTable,
          CompletedSet,
          $$CompletedSetsTableFilterComposer,
          $$CompletedSetsTableOrderingComposer,
          $$CompletedSetsTableAnnotationComposer,
          $$CompletedSetsTableCreateCompanionBuilder,
          $$CompletedSetsTableUpdateCompanionBuilder,
          (CompletedSet, $$CompletedSetsTableReferences),
          CompletedSet,
          PrefetchHooks Function({bool workoutId})
        > {
  $$CompletedSetsTableTableManager(_$AppDatabase db, $CompletedSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setNumber = const Value.absent(),
                Value<double?> prescribedWeight = const Value.absent(),
                Value<double> actualWeight = const Value.absent(),
                Value<int> prescribedReps = const Value.absent(),
                Value<int> actualReps = const Value.absent(),
                Value<int?> rpe = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<String?> overrideReason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CompletedSetsCompanion(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                prescribedWeight: prescribedWeight,
                actualWeight: actualWeight,
                prescribedReps: prescribedReps,
                actualReps: actualReps,
                rpe: rpe,
                restSeconds: restSeconds,
                overrideReason: overrideReason,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
                required String exerciseId,
                required int setNumber,
                Value<double?> prescribedWeight = const Value.absent(),
                required double actualWeight,
                required int prescribedReps,
                required int actualReps,
                Value<int?> rpe = const Value.absent(),
                Value<int?> restSeconds = const Value.absent(),
                Value<String?> overrideReason = const Value.absent(),
                required DateTime createdAt,
              }) => CompletedSetsCompanion.insert(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                prescribedWeight: prescribedWeight,
                actualWeight: actualWeight,
                prescribedReps: prescribedReps,
                actualReps: actualReps,
                rpe: rpe,
                restSeconds: restSeconds,
                overrideReason: overrideReason,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletedSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable: $$CompletedSetsTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn: $$CompletedSetsTableReferences
                                    ._workoutIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CompletedSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedSetsTable,
      CompletedSet,
      $$CompletedSetsTableFilterComposer,
      $$CompletedSetsTableOrderingComposer,
      $$CompletedSetsTableAnnotationComposer,
      $$CompletedSetsTableCreateCompanionBuilder,
      $$CompletedSetsTableUpdateCompanionBuilder,
      (CompletedSet, $$CompletedSetsTableReferences),
      CompletedSet,
      PrefetchHooks Function({bool workoutId})
    >;
typedef $$OneRepMaxesTableCreateCompanionBuilder =
    OneRepMaxesCompanion Function({
      Value<int> id,
      required int userId,
      required String exerciseId,
      required double weight,
      required DateTime date,
    });
typedef $$OneRepMaxesTableUpdateCompanionBuilder =
    OneRepMaxesCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> exerciseId,
      Value<double> weight,
      Value<DateTime> date,
    });

final class $$OneRepMaxesTableReferences
    extends BaseReferences<_$AppDatabase, $OneRepMaxesTable, OneRepMaxe> {
  $$OneRepMaxesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.oneRepMaxes.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OneRepMaxesTableFilterComposer
    extends Composer<_$AppDatabase, $OneRepMaxesTable> {
  $$OneRepMaxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OneRepMaxesTableOrderingComposer
    extends Composer<_$AppDatabase, $OneRepMaxesTable> {
  $$OneRepMaxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OneRepMaxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OneRepMaxesTable> {
  $$OneRepMaxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OneRepMaxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OneRepMaxesTable,
          OneRepMaxe,
          $$OneRepMaxesTableFilterComposer,
          $$OneRepMaxesTableOrderingComposer,
          $$OneRepMaxesTableAnnotationComposer,
          $$OneRepMaxesTableCreateCompanionBuilder,
          $$OneRepMaxesTableUpdateCompanionBuilder,
          (OneRepMaxe, $$OneRepMaxesTableReferences),
          OneRepMaxe,
          PrefetchHooks Function({bool userId})
        > {
  $$OneRepMaxesTableTableManager(_$AppDatabase db, $OneRepMaxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OneRepMaxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OneRepMaxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OneRepMaxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
              }) => OneRepMaxesCompanion(
                id: id,
                userId: userId,
                exerciseId: exerciseId,
                weight: weight,
                date: date,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String exerciseId,
                required double weight,
                required DateTime date,
              }) => OneRepMaxesCompanion.insert(
                id: id,
                userId: userId,
                exerciseId: exerciseId,
                weight: weight,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OneRepMaxesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$OneRepMaxesTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$OneRepMaxesTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OneRepMaxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OneRepMaxesTable,
      OneRepMaxe,
      $$OneRepMaxesTableFilterComposer,
      $$OneRepMaxesTableOrderingComposer,
      $$OneRepMaxesTableAnnotationComposer,
      $$OneRepMaxesTableCreateCompanionBuilder,
      $$OneRepMaxesTableUpdateCompanionBuilder,
      (OneRepMaxe, $$OneRepMaxesTableReferences),
      OneRepMaxe,
      PrefetchHooks Function({bool userId})
    >;
typedef $$PersonalRecordsTableCreateCompanionBuilder =
    PersonalRecordsCompanion Function({
      Value<int> id,
      required int userId,
      required String exerciseId,
      required String type,
      required double value,
      required int workoutId,
      required DateTime date,
    });
typedef $$PersonalRecordsTableUpdateCompanionBuilder =
    PersonalRecordsCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> exerciseId,
      Value<String> type,
      Value<double> value,
      Value<int> workoutId,
      Value<DateTime> date,
    });

final class $$PersonalRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PersonalRecordsTable, PersonalRecord> {
  $$PersonalRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.personalRecords.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CompletedWorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.completedWorkouts.createAlias(
        $_aliasNameGenerator(
          db.personalRecords.workoutId,
          db.completedWorkouts.id,
        ),
      );

  $$CompletedWorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$CompletedWorkoutsTableTableManager(
      $_db,
      $_db.completedWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonalRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompletedWorkoutsTableFilterComposer get workoutId {
    final $$CompletedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompletedWorkoutsTableOrderingComposer get workoutId {
    final $$CompletedWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.completedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletedWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.completedWorkouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonalRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalRecordsTable> {
  $$PersonalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompletedWorkoutsTableAnnotationComposer get workoutId {
    final $$CompletedWorkoutsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.workoutId,
          referencedTable: $db.completedWorkouts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletedWorkoutsTableAnnotationComposer(
                $db: $db,
                $table: $db.completedWorkouts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PersonalRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalRecordsTable,
          PersonalRecord,
          $$PersonalRecordsTableFilterComposer,
          $$PersonalRecordsTableOrderingComposer,
          $$PersonalRecordsTableAnnotationComposer,
          $$PersonalRecordsTableCreateCompanionBuilder,
          $$PersonalRecordsTableUpdateCompanionBuilder,
          (PersonalRecord, $$PersonalRecordsTableReferences),
          PersonalRecord,
          PrefetchHooks Function({bool userId, bool workoutId})
        > {
  $$PersonalRecordsTableTableManager(
    _$AppDatabase db,
    $PersonalRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
              }) => PersonalRecordsCompanion(
                id: id,
                userId: userId,
                exerciseId: exerciseId,
                type: type,
                value: value,
                workoutId: workoutId,
                date: date,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String exerciseId,
                required String type,
                required double value,
                required int workoutId,
                required DateTime date,
              }) => PersonalRecordsCompanion.insert(
                id: id,
                userId: userId,
                exerciseId: exerciseId,
                type: type,
                value: value,
                workoutId: workoutId,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonalRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false, workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$PersonalRecordsTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$PersonalRecordsTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable:
                                    $$PersonalRecordsTableReferences
                                        ._workoutIdTable(db),
                                referencedColumn:
                                    $$PersonalRecordsTableReferences
                                        ._workoutIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PersonalRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalRecordsTable,
      PersonalRecord,
      $$PersonalRecordsTableFilterComposer,
      $$PersonalRecordsTableOrderingComposer,
      $$PersonalRecordsTableAnnotationComposer,
      $$PersonalRecordsTableCreateCompanionBuilder,
      $$PersonalRecordsTableUpdateCompanionBuilder,
      (PersonalRecord, $$PersonalRecordsTableReferences),
      PersonalRecord,
      PrefetchHooks Function({bool userId, bool workoutId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ActiveCyclesTableTableManager get activeCycles =>
      $$ActiveCyclesTableTableManager(_db, _db.activeCycles);
  $$CompletedWorkoutsTableTableManager get completedWorkouts =>
      $$CompletedWorkoutsTableTableManager(_db, _db.completedWorkouts);
  $$CompletedSetsTableTableManager get completedSets =>
      $$CompletedSetsTableTableManager(_db, _db.completedSets);
  $$OneRepMaxesTableTableManager get oneRepMaxes =>
      $$OneRepMaxesTableTableManager(_db, _db.oneRepMaxes);
  $$PersonalRecordsTableTableManager get personalRecords =>
      $$PersonalRecordsTableTableManager(_db, _db.personalRecords);
}
