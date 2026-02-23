import 'package:flutter/material.dart';

import '../../../../domain/models/exercise_definitions.dart';
import '../../../../domain/models/program_models.dart';

class InteractiveProgramBuilder extends StatefulWidget {
  const InteractiveProgramBuilder({super.key, required this.onPush});

  final Future<void> Function(ProgramV2) onPush;

  @override
  State<InteractiveProgramBuilder> createState() => _InteractiveProgramBuilderState();
}

class _InteractiveProgramBuilderState extends State<InteractiveProgramBuilder> {
  final _idController = TextEditingController(text: 'custom-program-${DateTime.now().millisecondsSinceEpoch}');
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Strength Building');
  final _descriptionController = TextEditingController();
  
  final List<ProgramPhase> _phases = [];
  final List<ProgramWeek> _weeks = [];

  bool _isSaving = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addPhase() {
    setState(() {
      _phases.add(ProgramPhase(
        id: 'phase-${_phases.length + 1}',
        name: 'Block ${_phases.length + 1}',
        goal: '',
        weekRange: [1, 4],
      ));
    });
  }

  void _addWeek() {
    setState(() {
      final weekNum = _weeks.length + 1;
      _weeks.add(ProgramWeek(
        week: weekNum,
        phaseId: _phases.isNotEmpty ? _phases.first.id : 'block-1',
        isTestWeek: false,
        sessions: [],
      ));
    });
  }

  void _addSession(int weekIndex) {
    setState(() {
      final sessionNum = _weeks[weekIndex].sessions.length + 1;
      _weeks[weekIndex].sessions.add(ProgramSession(
        sessionId: 'w${_weeks[weekIndex].week}-d$sessionNum',
        sessionName: 'Day $sessionNum',
        sessionType: 'Lift',
        focus: 'Strength',
        exercises: [],
      ));
    });
  }

  Future<void> _addExercise(int weekIndex, int sessionIndex) async {
    final ExerciseDefinition? selected = await showSearch<ExerciseDefinition?>(
      context: context,
      delegate: ExerciseSearchDelegate(),
    );

    if (selected != null) {
      setState(() {
        _weeks[weekIndex].sessions[sessionIndex].exercises.add(ProgramExercise(
          exercise: selected.id,
          variant: null,
          sets: ExerciseValue.fixed(3),
          reps: ExerciseValue.fixed(5),
          percent1Rm: 0.7,
          restMinutes: 2.0,
          notes: null,
        ));
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a program name')));
       return;
    }

    setState(() => _isSaving = true);
    
    final program = ProgramV2(
      id: _idController.text,
      name: _nameController.text,
      category: _categoryController.text,
      description: _descriptionController.text,
      durationWeeks: _weeks.length,
      sessionsPerWeek: _weeks.isNotEmpty ? _weeks.first.sessions.length : 3,
      difficulty: 'Intermediate',
      phases: _phases.isEmpty ? [
        ProgramPhase(id: 'block-1', name: 'Phase 1', goal: 'Strength', weekRange: [1, 4])
      ] : _phases,
      weeks: _weeks,
    );

    try {
      await widget.onPush(program);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Program Name')),
          TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
          TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Structure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton(onPressed: _addPhase, child: const Text('Add Phase')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _addWeek, child: const Text('Add Week')),
                ],
              ),
            ],
          ),
          
          if (_weeks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No weeks added yet. Click Add Week to start.')),
            ),

          ..._weeks.asMap().entries.map((weekEntry) {
            final wIdx = weekEntry.key;
            final week = weekEntry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                title: Text('Week ${week.week}'),
                trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addSession(wIdx)),
                children: [
                  ...week.sessions.asMap().entries.map((sessionEntry) {
                    final sIdx = sessionEntry.key;
                    final session = sessionEntry.value;
                    return ListTile(
                      title: Text(session.sessionName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...session.exercises.map((e) => Text('• ${e.exercise} (${e.sets.displayString}x${e.reps.displayString} @ ${(e.percent1Rm! * 100).toInt()}%)')),
                          TextButton(
                            onPressed: () => _addExercise(wIdx, sIdx),
                            child: const Text('+ Add Exercise'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: _isSaving ? const CircularProgressIndicator() : const Text('Push Program to Team'),
          ),
        ],
      ),
    );
  }
}

class ExerciseSearchDelegate extends SearchDelegate<ExerciseDefinition?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = Exercises.all.where((e) => 
      e.name.toLowerCase().contains(query.toLowerCase()) || 
      e.category.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final e = results[index];
        return ListTile(
          title: Text(e.name),
          subtitle: Text(e.category),
          onTap: () => close(context, e),
        );
      },
    );
  }
}
