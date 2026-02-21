import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/cycle_provider.dart';
import '../../shared/providers/program_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../data/models/program_v2.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  String get programId => widget.programId;

  Future<void> _startCycle(ProgramV2 program) async {
    final user = await ref.read(userProvider.future);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete onboarding first')),
        );
      }
      return;
    }

    final result = await ref.read(cycleRepositoryProvider).startCycle(
      userId: user.id,
      programId: program.id,
      cycleName: program.name,
    );

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You already have an active program. Complete or stop it first.',
            ),
          ),
        );
      }
      return;
    }

    // Refresh dashboard active cycle
    ref.invalidate(activeCycleProvider);
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(programByIdProvider(programId));
    final activeCycleAsync = ref.watch(activeCycleProvider);

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
                  'Frequency: ${program.sessionsPerWeek} sessions per week',
                ),
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              phase.goal,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Weeks ${phase.weekRange.first}–'
                              '${phase.weekRange.last}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Start Training button — shows active badge if already running
                activeCycleAsync.when(
                  data: (activeCycle) {
                    if (activeCycle != null &&
                        activeCycle.programId == programId) {
                      return Chip(
                        key: const Key('active-cycle-badge'),
                        label: const Text('Currently Active'),
                        avatar: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      );
                    }
                    return ElevatedButton(
                      key: const Key('start-cycle-button'),
                      onPressed: () => _startCycle(program),
                      child: const Text('Start This Program'),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, _) => ElevatedButton(
                    key: const Key('start-cycle-button'),
                    onPressed: () => _startCycle(program),
                    child: const Text('Start This Program'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
