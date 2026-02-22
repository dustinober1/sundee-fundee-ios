import 'json_utils.dart';

class CustomProgramModel {
  CustomProgramModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.notes,
    required this.createdAt,
    required this.exercises,
  });

  final String id;
  final String userId;
  final String name;
  final String? notes;
  final DateTime createdAt;
  final List<CustomProgramExerciseModel> exercises;

  List<CustomProgramExerciseModel> get sortedExercises {
    final List<CustomProgramExerciseModel> copied =
        List<CustomProgramExerciseModel>.from(exercises);
    copied.sort((CustomProgramExerciseModel a, CustomProgramExerciseModel b) {
      return a.order.compareTo(b.order);
    });
    return copied;
  }

  factory CustomProgramModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> exerciseList =
        json['exercises'] as List<dynamic>? ?? <dynamic>[];

    return CustomProgramModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: parseDateTime(json['createdAt'], fieldName: 'createdAt'),
      exercises: exerciseList
          .map(
            (dynamic item) => CustomProgramExerciseModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'name': name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'exercises': exercises
          .map((CustomProgramExerciseModel exercise) => exercise.toJson())
          .toList(),
    };
  }
}

class CustomProgramExerciseModel {
  CustomProgramExerciseModel({
    required this.id,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.restMinutes,
    required this.notes,
    required this.order,
  });

  final String id;
  final String exerciseId;
  final int sets;
  final int reps;
  final double restMinutes;
  final String? notes;
  final int order;

  factory CustomProgramExerciseModel.fromJson(Map<String, dynamic> json) {
    return CustomProgramExerciseModel(
      id: json['id'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      sets: parseInt(json['sets'], fallback: 3),
      reps: parseInt(json['reps'], fallback: 8),
      restMinutes: parseDouble(json['restMinutes'], fallback: 2.0),
      notes: json['notes'] as String?,
      order: parseInt(json['order'], fallback: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'restMinutes': restMinutes,
      'notes': notes,
      'order': order,
    };
  }
}
