import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
  if (userId == null) return Stream.value([]);
  return ref.watch(cycleRepositoryProvider).watchPeriodLogs(userId: userId);
});

final symptomLogsProvider = StreamProvider<List<SymptomLogModel>>((ref) {
  final userId = ref.watch(cycleUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(cycleRepositoryProvider).watchSymptomLogs(userId: userId);
});

final cycleSettingsProvider = StreamProvider<CycleSettingsModel?>((ref) {
  final userId = ref.watch(cycleUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(cycleRepositoryProvider).watchCycleSettings(userId: userId);
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

final phaseRecommendationProvider = Provider<PhaseRecommendation?>((ref) {
  final status = ref.watch(cycleStatusProvider);
  if (status == null) return null;
  return CycleCalculations.getPhaseRecommendation(phase: status.currentPhase);
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
