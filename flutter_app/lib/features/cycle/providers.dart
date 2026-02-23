import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/calculations/cycle_adaptation_policy.dart';
import '../../domain/calculations/cycle_calculations.dart';
import '../../domain/enums.dart';
import '../../domain/models/cycle_models.dart';
import '../auth/domain/auth_state.dart';
import '../auth/providers.dart';
import '../repositories/providers.dart';

// ─── Auth ────────────────────────────────────────────────────────────────────

final cycleUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(authSessionStreamProvider).value;
  if (session?.status == AuthStatus.guest) return 'guest';
  return session?.user?.uid;
});

// ─── Streams ─────────────────────────────────────────────────────────────────

final periodLogsProvider = StreamProvider<List<PeriodLogModel>>((ref) {
  final userId = ref.watch(cycleUserIdProvider);
  if (userId == null || userId == 'guest') return Stream.value([]);
  return ref
      .watch(cycleRepositoryProvider)
      .watchPeriodLogs(userId: userId)
      .timeout(const Duration(seconds: 10));
});

final symptomLogsProvider = StreamProvider<List<SymptomLogModel>>((ref) {
  final userId = ref.watch(cycleUserIdProvider);
  if (userId == null || userId == 'guest') return Stream.value([]);
  return ref
      .watch(cycleRepositoryProvider)
      .watchSymptomLogs(userId: userId)
      .timeout(const Duration(seconds: 10));
});

final cycleSettingsProvider = StreamProvider<CycleSettingsModel?>((ref) {
  final userId = ref.watch(cycleUserIdProvider);
  if (userId == null || userId == 'guest') return Stream.value(null);
  return ref
      .watch(cycleRepositoryProvider)
      .watchCycleSettings(userId: userId)
      .timeout(const Duration(seconds: 10));
});

final cycleAdaptationPreferencesProvider =
    StreamProvider<CycleAdaptationPreferencesModel?>((ref) {
  final userId = ref.watch(cycleUserIdProvider);
  if (userId == null || userId == 'guest') return Stream.value(null);
  return ref
      .watch(cycleRepositoryProvider)
      .watchCycleAdaptationPreferences(userId: userId)
      .timeout(const Duration(seconds: 10));
});

// ─── Computed ────────────────────────────────────────────────────────────────

/// Default settings used when the user has not yet configured their cycle.
CycleSettingsModel defaultCycleSettings(String userId) {
  return CycleSettingsModel(
    id: 'settings',
    userId: userId,
    averageCycleLength: 28,
    averagePeriodLength: 5,
    lutealPhaseLength: 14,
    enabledSymptomIds: <String>[],
    notificationsEnabled: false,
  );
}

CycleAdaptationPreferencesModel defaultCycleAdaptationPreferences(
  String userId,
) {
  return CycleAdaptationPreferencesModel(
    id: 'programAdaptation',
    userId: userId,
    enabled: true,
    readinessScore: null,
    autoApplyDuringWorkout: false,
    showAdjustmentDetails: true,
  );
}

final cycleStatusProvider = Provider<CycleStatusResult?>((ref) {
  final periodLogs = ref.watch(periodLogsProvider).value ?? [];
  final userId = ref.watch(cycleUserIdProvider) ?? '';
  final settings =
      ref.watch(cycleSettingsProvider).value ?? defaultCycleSettings(userId);

  return CycleCalculations.calculateCycleStatus(
    periodLogs: periodLogs,
    settings: settings,
  );
});

final cycleLastSyncedAtProvider = Provider<DateTime?>((ref) {
  final List<PeriodLogModel> logs = ref.watch(periodLogsProvider).value ?? [];
  if (logs.isEmpty) return null;

  final List<PeriodLogModel> sorted = List<PeriodLogModel>.from(logs)
    ..sort((PeriodLogModel a, PeriodLogModel b) {
      return b.startDate.compareTo(a.startDate);
    });
  return sorted.first.startDate;
});

final cycleDataUnavailableProvider = Provider<bool>((ref) {
  final status = ref.watch(cycleStatusProvider);
  return status == null;
});

final phaseRecommendationProvider = Provider<PhaseRecommendation?>((ref) {
  final status = ref.watch(cycleStatusProvider);
  if (status == null) return null;
  return CycleCalculations.getPhaseRecommendation(phase: status.currentPhase);
});

final cycleLastKnownPhaseProvider = Provider<CyclePhase?>((ref) {
  final CycleStatusResult? currentStatus = ref.watch(cycleStatusProvider);
  if (currentStatus != null) {
    return currentStatus.currentPhase;
  }

  final List<PeriodLogModel> logs = ref.watch(periodLogsProvider).value ?? [];
  if (logs.isEmpty) {
    return null;
  }

  final String userId = ref.watch(cycleUserIdProvider) ?? '';
  final CycleSettingsModel settings =
      ref.watch(cycleSettingsProvider).value ?? defaultCycleSettings(userId);
  final List<PeriodLogModel> sorted = List<PeriodLogModel>.from(logs)
    ..sort((PeriodLogModel a, PeriodLogModel b) {
      return b.startDate.compareTo(a.startDate);
    });

  final CycleStatusResult? lastKnown = CycleCalculations.calculateCycleStatus(
    periodLogs: logs,
    settings: settings,
    referenceDate: sorted.first.startDate,
  );
  return lastKnown?.currentPhase;
});

final cycleAdaptationConfidenceProvider = Provider<AdaptationConfidence>((ref) {
  const CycleAdaptationPolicy policy = CycleAdaptationPolicy();
  final CycleStatusResult? status = ref.watch(cycleStatusProvider);
  final CyclePhase? lastKnown = ref.watch(cycleLastKnownPhaseProvider);
  final List<PeriodLogModel> logs = ref.watch(periodLogsProvider).value ?? [];
  final DateTime? lastSyncedAt = ref.watch(cycleLastSyncedAtProvider);

  return policy.resolveConfidence(
    currentPhase: status?.currentPhase,
    lastKnownPhase: lastKnown,
    periodLogCount: logs.length,
    lastPeriodStart: lastSyncedAt,
    referenceDate: DateTime.now(),
  );
});

// ─── Controller ──────────────────────────────────────────────────────────────

class CycleController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> savePeriodLog(PeriodLogModel log) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cycleRepositoryProvider);
      await repo.savePeriodLog(userId: log.userId, log: log);
    });
  }

  Future<void> deletePeriodLog({
    required String userId,
    required String logId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cycleRepositoryProvider);
      await repo.deletePeriodLog(userId: userId, logId: logId);
    });
  }

  Future<void> saveSymptomLog(SymptomLogModel log) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cycleRepositoryProvider);
      await repo.saveSymptomLog(userId: log.userId, log: log);
    });
  }

  Future<void> saveCycleSettings(CycleSettingsModel settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cycleRepositoryProvider);
      await repo.saveCycleSettings(userId: settings.userId, settings: settings);
    });
  }

  Future<void> saveCycleAdaptationPreferences(
    CycleAdaptationPreferencesModel preferences,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cycleRepositoryProvider);
      await repo.saveCycleAdaptationPreferences(
        userId: preferences.userId,
        preferences: preferences,
      );
    });
  }

  /// Quick-start a new period from today.
  Future<void> startPeriod() async {
    final userId = ref.read(cycleUserIdProvider);
    if (userId == null || userId == 'guest') return;

    final log = PeriodLogModel(
      id: const Uuid().v4(),
      userId: userId,
      startDate: DateTime.now(),
      endDate: null,
      flowLevel: FlowLevel.medium,
      notes: null,
    );
    await savePeriodLog(log);
  }

  /// End the most-recent open period.
  Future<void> endPeriod() async {
    final userId = ref.read(cycleUserIdProvider);
    if (userId == null || userId == 'guest') return;

    final logs = ref.read(periodLogsProvider).value ?? [];
    if (logs.isEmpty) return;

    final openLog = logs.firstWhere(
      (l) => l.endDate == null,
      orElse: () => logs.first,
    );

    final updated = PeriodLogModel(
      id: openLog.id,
      userId: openLog.userId,
      startDate: openLog.startDate,
      endDate: DateTime.now(),
      flowLevel: openLog.flowLevel,
      notes: openLog.notes,
    );
    await savePeriodLog(updated);
  }
}

final cycleControllerProvider =
    AsyncNotifierProvider<CycleController, void>(() => CycleController());
