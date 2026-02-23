import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/program_models.dart';
import '../../programs/data/program_repository.dart';
import '../../programs/data/squad_squat_program.dart';
import 'widgets/interactive_program_builder.dart';

class AdminProgramsScreen extends ConsumerStatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  ConsumerState<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends ConsumerState<AdminProgramsScreen> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pushFromJson() async {
    final text = _jsonController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      final program = ProgramV2.fromJson(jsonMap);

      await ref.read(programRepositoryProvider).pushProgram(program);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully pushed: ${program.name}')),
        );
        _jsonController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pushBaseline() async {
    setState(() => _isLoading = true);
    try {
      final program = squadSquatProgram;
      await ref.read(programRepositoryProvider).pushProgram(program);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully pushed 12-Week Squad Squat Peak!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Interactive Builder'),
              Tab(text: 'JSON Uploader'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            InteractiveProgramBuilder(
              onPush: (program) async {
                await ref.read(programRepositoryProvider).pushProgram(program);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully pushed: ${program.name}')),
                  );
                }
              },
            ),
            _buildJsonUploader(),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonUploader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Program JSON Uploader',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _pushBaseline,
            child: const Text('Push 12-Week Squad Squat Peak Default Program'),
          ),
          const SizedBox(height: 24),
          const Text('Or Paste Program JSON below:'),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _jsonController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Full Program JSON structure expected:\n'
                    '{\n'
                    '  "id": "my-program-id",\n'
                    '  "name": "Program Name",\n'
                    '  "weeks": [\n'
                    '    {\n'
                    '      "week": 1,\n'
                    '      "sessions": [\n'
                    '        {\n'
                    '          "sessionId": "w1-d1",\n'
                    '          "exercises": [\n'
                    '            {"exercise": "squat", "sets": 3, "reps": "8-10"}\n'
                    '          ]\n'
                    '        }\n'
                    '      ]\n'
                    '    }\n'
                    '  ]\n'
                    '}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _pushFromJson,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Push Program JSON to Team'),
          ),
        ],
      ),
    );
  }
}
