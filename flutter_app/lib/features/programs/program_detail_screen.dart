import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/program_provider.dart';

class ProgramDetailScreen extends ConsumerWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(programByIdProvider(programId));

    return Scaffold(
      key: const Key('program-detail-screen'),
      appBar: AppBar(title: const Text('Program Details')),
      body: programAsync.when(
        data: (program) {
          if (program == null) {
            return const Center(child: Text('Program not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: name + difficulty badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        program.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Chip(label: Text(program.difficulty)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(program.description),
                const SizedBox(height: 16),
                // Metadata
                Text('Duration: ${program.durationWeeks} weeks'),
                Text(
                    'Frequency: ${program.sessionsPerWeek} sessions per week'),
                const SizedBox(height: 24),
                // Training phases (only shown if program has them)
                if (program.phases.isNotEmpty) ...[
                  Text(
                    'Training Phases',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...program.phases.map(
                    (phase) => Card(
                      key: Key('phase-${phase.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phase.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              phase.goal,
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Weeks ${phase.weekRange.first}–'
                              '${phase.weekRange.last}',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Start Training button — enabled in Plan 03
                ElevatedButton(
                  key: const Key('start-cycle-button'),
                  onPressed: null,
                  child: const Text('Start This Program'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error: $error')),
      ),
    );
  }
}
