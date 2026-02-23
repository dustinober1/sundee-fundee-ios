import 'json_utils.dart';

class ProgramV2 {
  ProgramV2({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.durationWeeks,
    required this.sessionsPerWeek,
    required this.difficulty,
    required this.phases,
    required this.weeks,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final int durationWeeks;
  final int sessionsPerWeek;
  final String difficulty;
  final List<ProgramPhase> phases;
  final List<ProgramWeek> weeks;

  factory ProgramV2.fromJson(Map<String, dynamic> json) {
    final List<dynamic> phaseJson =
        json['phases'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> weekJson =
        json['weeks'] as List<dynamic>? ?? <dynamic>[];

    final String id = json['id'] as String? ?? '';
    if (id.isEmpty) {
      throw const FormatException(
        'Program JSON must include a non-empty "id" field.',
      );
    }

    return ProgramV2(
      id: id,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 0,
      sessionsPerWeek: (json['sessionsPerWeek'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty'] as String? ?? '',
      phases: phaseJson
          .map(
            (dynamic item) =>
                ProgramPhase.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      weeks: weekJson
          .map(
            (dynamic item) =>
                ProgramWeek.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'durationWeeks': durationWeeks,
      'sessionsPerWeek': sessionsPerWeek,
      'difficulty': difficulty,
      'phases': phases.map((ProgramPhase phase) => phase.toJson()).toList(),
      'weeks': weeks.map((ProgramWeek week) => week.toJson()).toList(),
    };
  }
}

class ProgramPhase {
  ProgramPhase({
    required this.id,
    required this.name,
    required this.goal,
    required this.weekRange,
  });

  final String id;
  final String name;
  final String goal;
  final List<int> weekRange;

  factory ProgramPhase.fromJson(Map<String, dynamic> json) {
    final List<dynamic> range =
        json['weekRange'] as List<dynamic>? ?? <dynamic>[];

    return ProgramPhase(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      goal: json['goal'] as String? ?? '',
      weekRange: range.map((dynamic item) => (item as num).toInt()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'goal': goal,
      'weekRange': weekRange,
    };
  }
}

class ProgramWeek {
  ProgramWeek({
    required this.week,
    required this.phaseId,
    required this.isTestWeek,
    required this.sessions,
  });

  final int week;
  final String? phaseId;
  final bool? isTestWeek;
  final List<ProgramSession> sessions;

  factory ProgramWeek.fromJson(Map<String, dynamic> json) {
    final List<dynamic> sessionsJson =
        json['sessions'] as List<dynamic>? ?? <dynamic>[];

    return ProgramWeek(
      week: (json['week'] as num?)?.toInt() ?? 0,
      phaseId: json['phaseId'] as String?,
      isTestWeek: json['isTestWeek'] as bool?,
      sessions: sessionsJson
          .map(
            (dynamic item) =>
                ProgramSession.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'week': week,
      'phaseId': phaseId,
      'isTestWeek': isTestWeek,
      'sessions':
          sessions.map((ProgramSession session) => session.toJson()).toList(),
    };
  }
}

class ProgramSession {
  ProgramSession({
    required this.sessionId,
    required this.sessionName,
    required this.sessionType,
    required this.focus,
    required this.exercises,
  });

  final String sessionId;
  final String sessionName;
  final String sessionType;
  final String focus;
  final List<ProgramExercise> exercises;

  String get id => sessionId;

  factory ProgramSession.fromJson(Map<String, dynamic> json) {
    final List<dynamic> exercisesJson =
        json['exercises'] as List<dynamic>? ?? <dynamic>[];

    return ProgramSession(
      sessionId: json['sessionId'] as String? ?? '',
      sessionName: json['sessionName'] as String? ?? '',
      sessionType: json['sessionType'] as String? ?? '',
      focus: json['focus'] as String? ?? '',
      exercises: exercisesJson
          .map(
            (dynamic item) =>
                ProgramExercise.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'sessionName': sessionName,
      'sessionType': sessionType,
      'focus': focus,
      'exercises': exercises
          .map((ProgramExercise exercise) => exercise.toJson())
          .toList(),
    };
  }
}

class ProgramExercise {
  ProgramExercise({
    required this.exercise,
    required this.variant,
    required this.sets,
    required this.reps,
    required this.percent1Rm,
    required this.restMinutes,
    required this.notes,
  });

  final String exercise;
  final String? variant;
  final ExerciseValue sets;
  final ExerciseValue reps;
  final double? percent1Rm;
  final double? restMinutes;
  final String? notes;

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exercise: json['exercise'] as String? ?? '',
      variant: json['variant'] as String?,
      sets: ExerciseValue.fromJson(json['sets']),
      reps: ExerciseValue.fromJson(json['reps']),
      percent1Rm: (json['percent1RM'] as num?)?.toDouble(),
      restMinutes: (json['restMinutes'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exercise': exercise,
      'variant': variant,
      'sets': sets.toJson(),
      'reps': reps.toJson(),
      'percent1RM': percent1Rm,
      'restMinutes': restMinutes,
      'notes': notes,
    };
  }
}

enum ExerciseValueType { fixed, amrap, range, text }

class ExerciseValue {
  const ExerciseValue._({
    required this.type,
    this.fixedValue,
    this.minValue,
    this.maxValue,
    this.textValue,
  });

  factory ExerciseValue.fixed(int value) {
    return ExerciseValue._(type: ExerciseValueType.fixed, fixedValue: value);
  }

  factory ExerciseValue.amrap() {
    return const ExerciseValue._(type: ExerciseValueType.amrap);
  }

  factory ExerciseValue.range(int min, int max) {
    return ExerciseValue._(
      type: ExerciseValueType.range,
      minValue: min,
      maxValue: max,
    );
  }

  factory ExerciseValue.text(String text) {
    return ExerciseValue._(type: ExerciseValueType.text, textValue: text);
  }

  final ExerciseValueType type;
  final int? fixedValue;
  final int? minValue;
  final int? maxValue;
  final String? textValue;

  static ExerciseValue fromJson(dynamic jsonValue) {
    if (jsonValue is int) {
      return ExerciseValue.fixed(jsonValue);
    }

    if (jsonValue is num) {
      return ExerciseValue.fixed(jsonValue.toInt());
    }

    if (jsonValue is String) {
      final String val = jsonValue.trim().toUpperCase();
      if (val == 'AMRAP') {
        return ExerciseValue.amrap();
      }

      // Handle "8-10" or "8 - 10"
      if (val.contains('-')) {
        final List<String> parts = val.split('-');
        if (parts.length == 2) {
          final int? min = int.tryParse(parts[0].trim());
          final int? max = int.tryParse(parts[1].trim());
          if (min != null && max != null) {
            return ExerciseValue.range(min, max);
          }
        }
      }

      // Handle single number string "5"
      final int? single = int.tryParse(val);
      if (single != null) {
        return ExerciseValue.fixed(single);
      }

      // Fallback for everything else ("5 minutes", "500m")
      return ExerciseValue.text(jsonValue);
    }

    if (jsonValue is List<dynamic> && jsonValue.length == 2) {
      final int? min = jsonValue[0] is num
          ? (jsonValue[0] as num).toInt()
          : int.tryParse(jsonValue[0].toString());
      final int? max = jsonValue[1] is num
          ? (jsonValue[1] as num).toInt()
          : int.tryParse(jsonValue[1].toString());

      if (min != null && max != null) {
        return ExerciseValue.range(min, max);
      }
    }

    throw FormatException(
      'Expected Int, "AMRAP", "8-10", or [Int, Int] for ExerciseValue. Got: $jsonValue',
    );
  }

  dynamic toJson() {
    switch (type) {
      case ExerciseValueType.fixed:
        return fixedValue;
      case ExerciseValueType.amrap:
        return 'AMRAP';
      case ExerciseValueType.range:
        return <int>[minValue!, maxValue!];
      case ExerciseValueType.text:
        return textValue;
    }
  }

  String get displayString {
    switch (type) {
      case ExerciseValueType.fixed:
        return '${fixedValue ?? 0}';
      case ExerciseValueType.amrap:
        return 'AMRAP';
      case ExerciseValueType.range:
        return '${minValue ?? 0}-${maxValue ?? 0}';
      case ExerciseValueType.text:
        return textValue ?? '';
    }
  }
}

class EnrolledProgramModel {
  EnrolledProgramModel({
    required this.id,
    required this.programId,
    required this.startDate,
    required this.currentWeek,
    required this.currentDay,
    this.isActive = true,
    this.completedAt,
  });

  final String id;
  final String programId;
  final DateTime startDate;
  final int currentWeek;
  final int currentDay;
  final bool isActive;
  final DateTime? completedAt;

  factory EnrolledProgramModel.fromJson(Map<String, dynamic> json) {
    return EnrolledProgramModel(
      id: json['id'] as String? ?? '',
      programId: json['programId'] as String? ?? '',
      startDate: parseDateTime(json['startDate'], fieldName: 'startDate'),
      currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 1,
      currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] as bool? ?? true,
      completedAt: parseNullableDateTime(json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'programId': programId,
      'startDate': startDate.toIso8601String(),
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'isActive': isActive,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  EnrolledProgramModel copyWith({
    int? currentWeek,
    int? currentDay,
    bool? isActive,
    DateTime? completedAt,
  }) {
    return EnrolledProgramModel(
      id: id,
      programId: programId,
      startDate: startDate,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      isActive: isActive ?? this.isActive,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
