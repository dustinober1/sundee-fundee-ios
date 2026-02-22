import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../migration/providers.dart';
import '../../../domain/data/predefined_programs.dart';
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthSession>>(authSessionStreamProvider, (
      AsyncValue<AuthSession>? previous,
      AsyncValue<AuthSession> next,
    ) {
      final String? userId = next.asData?.value.user?.uid;
      if (userId == null) {
        return;
      }

      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      unawaited(
        ref
            .read(legacyMigrationOrchestratorProvider)
            .migrateIfNeeded(userId: userId)
            .then((_) {})
            .catchError((Object error, StackTrace stackTrace) {
              messenger?.showSnackBar(
                SnackBar(content: Text('Legacy migration failed: $error')),
              );
            }),
      );
    });

    final AuthSession? session = ref
        .watch(authSessionStreamProvider)
        .asData
        ?.value;

    final String stateMessage;
    switch (session?.status) {
      case AuthStatus.guest:
        stateMessage = 'Guest mode active';
      case AuthStatus.authenticated:
        stateMessage = 'Signed in as ${session?.user?.email ?? 'user'}';
      case AuthStatus.needsOnboarding:
        stateMessage = 'Onboarding required';
      case AuthStatus.unauthenticated:
      case AuthStatus.loading:
      case null:
        stateMessage = 'Not signed in';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Available Programs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...[
            PredefinedPrograms.baseline12Week,
            PredefinedPrograms.deadlift1Cycle,
          ].map((program) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(program.description),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(content: Text('Enrollment coming soon!')),
                      );
                    },
                    child: const Text('Enroll in Program'),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
          Text(stateMessage),
        ],
      ),
    );
  }
}
