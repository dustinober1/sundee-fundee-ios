import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum WorkoutSyncOperationType {
  completedSet,
  workoutSummary,
  liftMax,
  enrollmentProgress,
}

WorkoutSyncOperationType workoutSyncOperationTypeFromJson(String raw) {
  switch (raw) {
    case 'completed_set':
      return WorkoutSyncOperationType.completedSet;
    case 'workout_summary':
      return WorkoutSyncOperationType.workoutSummary;
    case 'lift_max':
      return WorkoutSyncOperationType.liftMax;
    case 'enrollment_progress':
      return WorkoutSyncOperationType.enrollmentProgress;
    default:
      throw FormatException('Unknown workout sync operation: $raw');
  }
}

String workoutSyncOperationTypeToJson(WorkoutSyncOperationType type) {
  switch (type) {
    case WorkoutSyncOperationType.completedSet:
      return 'completed_set';
    case WorkoutSyncOperationType.workoutSummary:
      return 'workout_summary';
    case WorkoutSyncOperationType.liftMax:
      return 'lift_max';
    case WorkoutSyncOperationType.enrollmentProgress:
      return 'enrollment_progress';
  }
}

class PendingWorkoutWriteIntent {
  const PendingWorkoutWriteIntent({
    required this.id,
    required this.type,
    required this.userId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  final String id;
  final WorkoutSyncOperationType type;
  final String userId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttemptAt;

  PendingWorkoutWriteIntent copyWith({
    int? retryCount,
    DateTime? lastAttemptAt,
  }) {
    return PendingWorkoutWriteIntent(
      id: id,
      type: type,
      userId: userId,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  factory PendingWorkoutWriteIntent.fromJson(Map<String, dynamic> json) {
    return PendingWorkoutWriteIntent(
      id: json['id'] as String,
      type: workoutSyncOperationTypeFromJson(json['type'] as String),
      userId: json['userId'] as String,
      payload:
          (json['payload'] as Map<dynamic, dynamic>).cast<String, dynamic>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': workoutSyncOperationTypeToJson(type),
      'userId': userId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    };
  }
}

class WorkoutSyncQueueStore {
  WorkoutSyncQueueStore({SharedPreferences? sharedPreferences})
      : _sharedPreferences = sharedPreferences;

  static const String _queueStorageKey = 'workout_sync_pending_writes_v1';

  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> _prefs() async {
    final SharedPreferences? cached = _sharedPreferences;
    if (cached != null) {
      return cached;
    }
    final SharedPreferences loaded = await SharedPreferences.getInstance();
    _sharedPreferences = loaded;
    return loaded;
  }

  Future<List<PendingWorkoutWriteIntent>> readPendingWrites() async {
    final SharedPreferences prefs = await _prefs();
    final String? raw = prefs.getString(_queueStorageKey);
    if (raw == null || raw.isEmpty) {
      return const <PendingWorkoutWriteIntent>[];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              PendingWorkoutWriteIntent.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> writePendingWrites(
      List<PendingWorkoutWriteIntent> writes) async {
    final SharedPreferences prefs = await _prefs();
    final String encoded = jsonEncode(
      writes.map((PendingWorkoutWriteIntent write) => write.toJson()).toList(),
    );
    await prefs.setString(_queueStorageKey, encoded);
  }

  Future<void> enqueuePendingWrites(
    List<PendingWorkoutWriteIntent> writes,
  ) async {
    if (writes.isEmpty) {
      return;
    }
    final List<PendingWorkoutWriteIntent> existing = await readPendingWrites();
    final Map<String, PendingWorkoutWriteIntent> byId =
        <String, PendingWorkoutWriteIntent>{
      for (final PendingWorkoutWriteIntent write in existing) write.id: write,
    };
    for (final PendingWorkoutWriteIntent write in writes) {
      byId[write.id] = write;
    }
    await writePendingWrites(byId.values.toList(growable: false));
  }

  Future<void> removePendingWriteIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final List<PendingWorkoutWriteIntent> existing = await readPendingWrites();
    final List<PendingWorkoutWriteIntent> next =
        existing.where((PendingWorkoutWriteIntent write) {
      return !ids.contains(write.id);
    }).toList(growable: false);
    await writePendingWrites(next);
  }
}
