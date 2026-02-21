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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $ActiveCyclesTable activeCycles = $ActiveCyclesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, activeCycles];
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
          PrefetchHooks Function({bool activeCyclesRefs})
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
          prefetchHooksCallback: ({activeCyclesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (activeCyclesRefs) db.activeCycles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (activeCyclesRefs)
                    await $_getPrefetchedData<User, $UsersTable, ActiveCycle>(
                      currentTable: table,
                      referencedTable: $$UsersTableReferences
                          ._activeCyclesRefsTable(db),
                      managerFromTypedResult: (p0) => $$UsersTableReferences(
                        db,
                        table,
                        p0,
                      ).activeCyclesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
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
      PrefetchHooks Function({bool activeCyclesRefs})
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
          PrefetchHooks Function({bool userId})
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
                                referencedTable: $$ActiveCyclesTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$ActiveCyclesTableReferences
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
      PrefetchHooks Function({bool userId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$ActiveCyclesTableTableManager get activeCycles =>
      $$ActiveCyclesTableTableManager(_db, _db.activeCycles);
}
