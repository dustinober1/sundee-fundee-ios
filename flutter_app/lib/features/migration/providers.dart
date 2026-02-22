import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../repositories/providers.dart';
import 'data/legacy_migration_orchestrator.dart';
import 'data/legacy_migration_service.dart';

final legacyMigrationServiceProvider = Provider<LegacyMigrationService>((
  Ref ref,
) {
  return LegacyMigrationService();
});

final migrationFirestoreProvider = Provider<FirebaseFirestore?>((Ref ref) {
  if (!firebaseAuthEnabled) {
    return null;
  }
  return FirebaseFirestore.instance;
});

final migrationAnalyticsProvider = Provider<FirebaseAnalytics?>((Ref ref) {
  if (!firebaseAuthEnabled) {
    return null;
  }
  return FirebaseAnalytics.instance;
});

final migrationCrashlyticsProvider = Provider<FirebaseCrashlytics?>((Ref ref) {
  if (!firebaseAuthEnabled) {
    return null;
  }
  return FirebaseCrashlytics.instance;
});

final legacyMigrationOrchestratorProvider =
    Provider<LegacyMigrationOrchestrator>((Ref ref) {
      return LegacyMigrationOrchestrator(
        legacyMigrationService: ref.watch(legacyMigrationServiceProvider),
        workoutRepository: ref.watch(workoutRepositoryProvider),
        cycleRepository: ref.watch(cycleRepositoryProvider),
        liftRepository: ref.watch(liftRepositoryProvider),
        recordRepository: ref.watch(recordRepositoryProvider),
        customProgramRepository: ref.watch(customProgramRepositoryProvider),
        firestore: ref.watch(migrationFirestoreProvider),
        analytics: ref.watch(migrationAnalyticsProvider),
        crashlytics: ref.watch(migrationCrashlyticsProvider),
      );
    });
