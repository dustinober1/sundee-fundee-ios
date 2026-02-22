import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/program_models.dart';
import '../data/program_repository.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProgramV2>> programsAsync = ref.watch(programsProvider);

    return programsAsync.when(
      data: (List<ProgramV2> programs) {
        if (programs.isEmpty) {
          return const Center(child: Text('No programs available.'));
        }
        return ListView.builder(
          itemCount: programs.length,
          itemBuilder: (BuildContext context, int index) {
            final ProgramV2 program = programs[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(program.name),
                subtitle: Text(program.description),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(program.name),
                      content: Text(
                          'Would you like to start this ${program.durationWeeks}-week program?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Program started! (Mock)')),
                            );
                          },
                          child: const Text('Start'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
