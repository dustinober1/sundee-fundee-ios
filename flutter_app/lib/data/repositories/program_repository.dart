import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/program_v2.dart';

class ProgramRepository {
  final Map<String, ProgramV2> _cache = {};

  static const _programFiles = [
    'back-squat-complete-cycle',
    'bench-press-strength',
    'box-jump-power',
    'burpees-conditioning',
    'deadlift-5x5',
    'front-squat-volume',
  ];

  Future<List<ProgramV2>> getAllPrograms() async {
    if (_cache.isEmpty) {
      await _loadAllPrograms();
    }
    return _cache.values.toList();
  }

  Future<ProgramV2?> getProgramById(String id) async {
    if (_cache.isEmpty) {
      await _loadAllPrograms();
    }
    return _cache[id];
  }

  Future<void> _loadAllPrograms() async {
    for (final filename in _programFiles) {
      final jsonString =
          await rootBundle.loadString('assets/programs/$filename.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final program = ProgramV2.fromJson(json);
      _cache[program.id] = program;
    }
  }
}
