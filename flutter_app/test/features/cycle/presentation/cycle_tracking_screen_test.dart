import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/calculations/cycle_calculations.dart';
import 'package:sundee_fundee_flutter/domain/enums.dart';
import 'package:sundee_fundee_flutter/domain/models/cycle_models.dart';
import 'package:sundee_fundee_flutter/features/cycle/presentation/cycle_tracking_screen.dart';
import 'package:sundee_fundee_flutter/features/cycle/providers.dart';

CycleSettingsModel _settings(String userId) {
  return CycleSettingsModel(
    id: 'settings',
    userId: userId,
    averageCycleLength: 28,
    averagePeriodLength: 5,
    lutealPhaseLength: 14,
    enabledSymptomIds: const <String>[],
    notificationsEnabled: false,
  );
}

CycleStatusResult _status(CyclePhase phase) {
  return CycleStatusResult(
    currentPhase: phase,
    cycleDay: 2,
    daysUntilNextPhase: 3,
    predictedNextPeriod: DateTime.utc(2026, 3, 1),
    phaseStartDate: DateTime.utc(2026, 2, 20),
    phaseEndDate: DateTime.utc(2026, 2, 24),
  );
}

Future<void> _pump({
  required WidgetTester tester,
  required CycleStatusResult? status,
  required List<PeriodLogModel> logs,
}) async {
  const String userId = 'user-1';

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cycleUserIdProvider.overrideWith((Ref ref) => userId),
        periodLogsProvider.overrideWith(
          (Ref ref) => Stream<List<PeriodLogModel>>.value(logs),
        ),
        cycleStatusProvider.overrideWith((Ref ref) => status),
        cycleSettingsProvider.overrideWith(
          (Ref ref) => Stream<CycleSettingsModel?>.value(_settings(userId)),
        ),
      ],
      child: const MaterialApp(home: CycleTrackingScreen()),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows sharkweek cue during menstrual phase', (
    WidgetTester tester,
  ) async {
    final List<PeriodLogModel> logs = <PeriodLogModel>[
      PeriodLogModel(
        id: 'log-1',
        userId: 'user-1',
        startDate: DateTime.utc(2026, 2, 20),
        endDate: DateTime.utc(2026, 2, 24),
        flowLevel: FlowLevel.medium,
        notes: null,
      ),
    ];

    await _pump(
      tester: tester,
      status: _status(CyclePhase.menstrual),
      logs: logs,
    );
    expect(find.bySemanticsLabel('Sharkweek menstrual phase indicator'), findsOneWidget);
  });

  testWidgets('does not show sharkweek cue outside menstrual phase', (
    WidgetTester tester,
  ) async {
    final List<PeriodLogModel> logs = <PeriodLogModel>[
      PeriodLogModel(
        id: 'log-1',
        userId: 'user-1',
        startDate: DateTime.utc(2026, 2, 20),
        endDate: DateTime.utc(2026, 2, 24),
        flowLevel: FlowLevel.medium,
        notes: null,
      ),
    ];

    await _pump(tester: tester, status: _status(CyclePhase.luteal), logs: logs);
    expect(find.bySemanticsLabel('Sharkweek menstrual phase indicator'), findsNothing);
  });

  testWidgets('shows neutral unavailable and sync messaging for missing cycle status', (
    WidgetTester tester,
  ) async {
    await _pump(tester: tester, status: null, logs: const <PeriodLogModel>[]);

    expect(find.textContaining('Cycle data unavailable'), findsOneWidget);
    expect(find.textContaining('Last synced'), findsOneWidget);
  });
}
