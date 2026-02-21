// ProgramV2 model classes — matches v1.1 TypeScript interfaces.
// Two JSON structures are supported:
//   1. Full-session format (back-squat): uses weeks[].sessions[], sessionsPerWeek, phases
//   2. Simple-day format (all others): uses weeks[].days[], daysPerWeek
// Both parse into the same Dart model with nullability for optional fields.

class ProgramV2 {
  final String id;
  final String name;
  final String category;
  final String description;
  final int durationWeeks;
  final int sessionsPerWeek;
  final String difficulty;
  final List<Phase> phases;
  final List<WeekV2> weeks;

  const ProgramV2({
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

  factory ProgramV2.fromJson(Map<String, dynamic> json) => ProgramV2(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        durationWeeks: json['durationWeeks'] as int,
        // Support both sessionsPerWeek (back-squat) and daysPerWeek (others)
        sessionsPerWeek:
            (json['sessionsPerWeek'] ?? json['daysPerWeek']) as int,
        difficulty: json['difficulty'] as String,
        phases: json['phases'] != null
            ? (json['phases'] as List)
                .map((e) => Phase.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        weeks: (json['weeks'] as List)
            .map((e) => WeekV2.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Phase {
  final String id;
  final String name;
  final String goal;
  final List<int> weekRange;

  const Phase({
    required this.id,
    required this.name,
    required this.goal,
    required this.weekRange,
  });

  factory Phase.fromJson(Map<String, dynamic> json) => Phase(
        id: json['id'] as String,
        name: json['name'] as String,
        goal: json['goal'] as String,
        weekRange: (json['weekRange'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
      );
}

class Session {
  final String sessionId;
  final String sessionName;
  final String? sessionType;
  final String? focus;
  final List<ExerciseV2> exercises;

  const Session({
    required this.sessionId,
    required this.sessionName,
    this.sessionType,
    this.focus,
    required this.exercises,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    // Full-session format: has sessionId, sessionName, sessionType, focus
    if (json.containsKey('sessionId')) {
      return Session(
        sessionId: json['sessionId'] as String,
        sessionName: json['sessionName'] as String,
        sessionType: json['sessionType'] as String?,
        focus: json['focus'] as String?,
        exercises: (json['exercises'] as List)
            .map((e) => ExerciseV2.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    // Simple-day format: has 'day' number and 'exercises'
    final dayNum = json['day'] as int;
    return Session(
      sessionId: 'day-$dayNum',
      sessionName: 'Day $dayNum',
      sessionType: null,
      focus: null,
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseV2.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExerciseV2 {
  final String exercise;
  final String? variant;
  final dynamic sets;
  final dynamic reps;
  final double percent1RM;
  final double? restMinutes;
  final String? notes;

  const ExerciseV2({
    required this.exercise,
    this.variant,
    required this.sets,
    required this.reps,
    required this.percent1RM,
    this.restMinutes,
    this.notes,
  });

  factory ExerciseV2.fromJson(Map<String, dynamic> json) => ExerciseV2(
        exercise: json['exercise'] as String,
        variant: json['variant'] as String?,
        sets: json['sets'],
        reps: json['reps'],
        percent1RM: (json['percent1RM'] as num).toDouble(),
        restMinutes: (json['restMinutes'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );

  String get setsDisplay => '$sets';

  String get repsDisplay {
    if (reps is List) {
      final list = reps as List;
      return '${list.first}–${list.last}';
    }
    return '$reps';
  }
}

class WeekV2 {
  final int week;
  final String? phaseId;
  final bool isTestWeek;
  final List<Session> sessions;

  const WeekV2({
    required this.week,
    this.phaseId,
    this.isTestWeek = false,
    required this.sessions,
  });

  factory WeekV2.fromJson(Map<String, dynamic> json) {
    // Support both 'sessions' (back-squat) and 'days' (others) keys
    final rawSessions =
        (json['sessions'] ?? json['days']) as List? ?? [];
    return WeekV2(
      week: json['week'] as int,
      phaseId: json['phaseId'] as String?,
      isTestWeek: json['isTestWeek'] as bool? ?? false,
      sessions: rawSessions
          .map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
