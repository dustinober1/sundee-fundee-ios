import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../migration/providers.dart';

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
          const Text('Flutter + Firebase transition baseline'),
          const SizedBox(height: 8),
          const Text('Dashboard coming soon.'),
          const SizedBox(height: 8),
          Text(stateMessage),
        ],
      ),
    );
  }
}
