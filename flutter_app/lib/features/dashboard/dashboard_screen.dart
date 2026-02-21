import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/cycle_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/offline_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final activeCycleAsync = ref.watch(activeCycleProvider);

    return Scaffold(
      key: const Key('dashboard-screen'),
      appBar: AppBar(title: const Text('Dashboard')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OfflineBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Personalized greeting
                  userAsync.when(
                    data: (user) => Text(
                      user != null
                          ? 'Welcome, ${user.name}!'
                          : 'Welcome to Sundee Fundee',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    loading: () => const Text(
                      'Welcome to Sundee Fundee',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    error: (_, _) => const Text(
                      'Welcome to Sundee Fundee',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Active cycle card
                  activeCycleAsync.when(
                    data: (activeCycle) {
                      if (activeCycle == null) {
                        return Card(
                          key: const Key('no-active-cycle-card'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No active programs — Browse programs to start training',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return Card(
                        key: const Key('active-cycle-card'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      activeCycle.cycleName,
                                      key: const Key('cycle-name'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  Chip(
                                    key: const Key('cycle-status'),
                                    label: Text(activeCycle.status),
                                    backgroundColor: activeCycle.status ==
                                            'active'
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                key: const Key('cycle-week'),
                                'Week ${activeCycle.currentWeek}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('nav-programs'),
                    onPressed: () => context.go('/programs'),
                    child: const Text('Programs'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('nav-progress'),
                    onPressed: () => context.go('/progress'),
                    child: const Text('Progress'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
