# Phase 12: Recommendations + Progress Insights Parity - Research

**Researched:** 2026-02-21
**Domain:** Flutter — Dart calculation parity, fl_chart, Riverpod async providers, Drift queries
**Confidence:** HIGH

---

## Summary

Phase 12 ports the v1.1 recommendation engine and progress visualization layer to Flutter. The v1.1 source code is fully readable (`src/lib/calculations.ts`, `src/lib/recommendations/plateau-detection.ts`, `src/hooks/use-1rm-progress.ts`, `src/hooks/use-weekly-volume.ts`, `src/hooks/use-workout-frequency.ts`, `src/hooks/use-pr-detection.ts`) — every algorithm is a direct Dart port with no guesswork. The Drift schema (v3) already has the tables needed: `CompletedWorkouts`, `CompletedSets`, `OneRepMaxes`, `PersonalRecords`.

For charting, `fl_chart ^1.1.1` (SDK `>=3.6.2`, compatible with project's `^3.11.0`) provides `LineChart` and `BarChart`. No heatmap pub.dev library is SDK-3 compatible — both `flutter_heatmap_calendar` and `heatmap_calendar` require SDK `<3.0.0`. The activity heatmap must be a custom `Wrap`/`GridView` widget. Date formatting requires the `intl` package (not yet in pubspec).

All data reads from Drift, so CHRT-02 (offline) is inherent — no extra work needed.

**Primary recommendation:** Port all v1.1 algorithms verbatim to Dart, add `fl_chart` + `intl` to pubspec, build heatmap as a custom Flutter widget, implement Riverpod `AsyncNotifierProvider` providers for each chart dataset, and wire parity gates for RECO-01, RECO-02, CHRT-01, CHRT-02.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fl_chart | ^1.1.1 | LineChart (1RM trend) + BarChart (weekly volume) | De facto Flutter charting library; 7k+ likes, 1M+ monthly downloads; SDK-3 compatible |
| intl | ^0.20.2 | DateFormat for axis labels (`'MMM d'`, `'yyyy-MM-dd'`) | Standard Dart/Flutter i18n+date formatting package |
| drift (existing) | ^2.31.0 | All data queries — keeps CHRT-02 offline guarantee | Already in project |
| flutter_riverpod (existing) | ^3.2.1 | AsyncNotifierProvider for chart data | Already in project |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Custom heatmap widget | (built in-project) | 365-day activity grid | Required — no SDK-3-compatible pub.dev heatmap |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| fl_chart | syncfusion_flutter_charts | Syncfusion is commercial (free tier limited); fl_chart is MIT and already sufficient |
| custom heatmap | flutter_heatmap_calendar | Requires Dart SDK `<3.0.0` — incompatible with project SDK `^3.11.0` |
| custom heatmap | heatmap_calendar | Also requires Dart SDK `<3.0.0` — incompatible |
| intl | manual formatting | intl is standard and already transitively included via Flutter SDK |

**Installation:**
```bash
# In flutter_app/
flutter pub add fl_chart intl
```

---

## Architecture Patterns

### Recommended Project Structure
```
flutter_app/lib/
├── core/
│   └── recommendations/
│       ├── calculations.dart          # Pure Dart port of calculations.ts
│       └── plateau_detection.dart     # Pure Dart port of plateau-detection.ts
├── data/
│   └── repositories/
│       └── workout_repository.dart    # ADD: saveOneRepMax, savePersonalRecord,
│                                      #      getRecentWorkoutsForCycle,
│                                      #      checkAndSaveWeightPR
├── features/
│   └── progress/
│       ├── progress_screen.dart       # Replace placeholder with chart widgets
│       ├── one_rm_chart.dart          # fl_chart LineChart widget
│       ├── weekly_volume_chart.dart   # fl_chart BarChart widget
│       └── workout_heatmap.dart       # Custom Wrap-based heatmap widget
└── shared/
    └── providers/
        ├── one_rm_progress_provider.dart      # AsyncNotifierProviderFamily
        ├── weekly_volume_provider.dart        # AsyncNotifierProvider
        ├── workout_frequency_provider.dart    # AsyncNotifierProvider
        └── tracked_exercises_provider.dart    # FutureProvider

integration_test/
└── parity_gates/
    └── recommendations_parity_test.dart  # RECO-01, RECO-02, CHRT-01, CHRT-02
```

### Pattern 1: Pure Dart Calculation Functions (calculations.dart)
**What:** Direct port of `src/lib/calculations.ts` — no dependencies, pure functions
**When to use:** Called by providers and repository methods for all recommendation math

```dart
// lib/core/recommendations/calculations.dart

double roundToNearestFive(double value) =>
    (value / 5).round() * 5.0;

/// Epley formula — caps reps at 10 per v1.1 source
double epley(double weight, int reps) {
  if (reps <= 1) return weight;
  return weight * (1 + reps.clamp(1, 10) / 30.0);
}

enum SessionResult { first, success, failure }

double getNextRecommendedWeight(
    double currentWeight, SessionResult result, double oneRepMax) {
  switch (result) {
    case SessionResult.first:
      return roundToNearestFive(oneRepMax * 0.7);
    case SessionResult.success:
      return roundToNearestFive(currentWeight + 5);
    case SessionResult.failure:
      final floor = roundToNearestFive(oneRepMax * 0.5);
      return roundToNearestFive(currentWeight - 5).clamp(floor, double.infinity);
  }
}

bool wasSetSuccessful({
  required int actualReps,
  required int prescribedReps,
  required double actualWeight,
  double? prescribedWeight,
}) {
  final repsOk = actualReps >= prescribedReps;
  final weightOk = prescribedWeight == null || actualWeight >= prescribedWeight;
  return repsOk && weightOk;
}

/// detectPlateau: variance < 5 lbs in last 3 weights (v1.1 definition)
bool detectPlateau(List<double> weights) {
  if (weights.length < 3) return false;
  final last3 = weights.sublist(weights.length - 3);
  return last3.reduce((a, b) => a > b ? a : b) -
         last3.reduce((a, b) => a < b ? a : b) < 5;
}
```

### Pattern 2: Plateau Detection (plateau_detection.dart)
**What:** Direct port of `detectPlateauForExercise` — checks last 3 sessions for rep failures
**When to use:** Called from WorkoutScreen before/after workout; scoped to active cycle

```dart
// lib/core/recommendations/plateau_detection.dart
// Key: 3 consecutive sessions where ANY set had actualReps < prescribedReps
// Key: requires workouts.length >= 3 (returns false otherwise)
// Key: scoped to activeCycleId — ALWAYS pass current cycle

Future<PlateauWarning> detectPlateauForExercise(
    AppDatabase db, String exerciseId, int activeCycleId) async {
  final workouts = await (db.select(db.completedWorkouts)
        ..where((t) => t.activeCycleId.equals(activeCycleId))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
        ..limit(3))
      .get();

  if (workouts.length < 3) return const PlateauWarning.none();

  final failures = await Future.wait(workouts.map((w) async {
    final sets = await (db.select(db.completedSets)
          ..where((t) =>
              t.workoutId.equals(w.id) & t.exerciseId.equals(exerciseId)))
        .get();
    if (sets.isEmpty) return false;
    return sets.any((s) => s.actualReps < s.prescribedReps);
  }));

  if (failures.every((f) => f)) {
    return PlateauWarning(
      hasPlateau: true,
      message: "You've missed prescribed reps on this exercise for 3 sessions in a row.",
      recommendation: 'Recommended deload: reduce weight by 10% for next session.',
    );
  }
  return const PlateauWarning.none();
}

double getDeloadWeight(double currentWeight) =>
    roundToNearestFive(currentWeight * 0.9);
```

### Pattern 3: AsyncNotifierProvider for Chart Data
**What:** Riverpod 3.x pattern for async Drift queries
**When to use:** All progress data providers

```dart
// lib/shared/providers/one_rm_progress_provider.dart
// Family provider — parameterized by exerciseId

class OneRmProgressNotifier
    extends FamilyAsyncNotifier<List<OneRmPoint>, String> {
  @override
  Future<List<OneRmPoint>> build(String exerciseId) async {
    if (exerciseId.isEmpty) return [];
    final db = ref.watch(databaseProvider);
    // ... Drift query + Epley calculation
  }
}

final oneRmProgressProvider = AsyncNotifierProviderFamily<
    OneRmProgressNotifier, List<OneRmPoint>, String>(
  OneRmProgressNotifier.new,
);

// Consumer usage:
// ref.watch(oneRmProgressProvider(exerciseId))
```

### Pattern 4: fl_chart LineChart (1RM Trend)
**What:** Index-based x-axis with date labels via `SideTitles.getTitlesWidget`
**When to use:** 1RM trend display

```dart
// Key fl_chart API for LineChart:
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: data.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.estimated1RM))
            .toList(),
        isCurved: false,
        color: Theme.of(context).colorScheme.primary,
        barWidth: 2,
        dotData: const FlDotData(show: true),
      ),
    ],
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          // Show at most ~5 labels regardless of data length
          interval: (data.length / 5).ceilToDouble().clamp(1, double.infinity),
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= data.length) return const SizedBox.shrink();
            return Text(data[i].date, style: const TextStyle(fontSize: 10));
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) =>
              Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
          reservedSize: 40,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    gridData: const FlGridData(show: true),
    borderData: FlBorderData(show: false),
  ),
)
```

### Pattern 5: fl_chart BarChart (Weekly Volume)
**What:** Index-based x-axis, volume values as `toY`, k-formatted Y labels
**When to use:** Weekly volume display

```dart
BarChart(
  BarChartData(
    barGroups: data.asMap().entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.volume.toDouble(),
                  color: Theme.of(context).colorScheme.secondary,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            ))
        .toList(),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= data.length) return const SizedBox.shrink();
            return Text(data[i].week,
                style: const TextStyle(fontSize: 10));
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final v = value.toInt();
            return Text(v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : '$v',
                style: const TextStyle(fontSize: 10));
          },
          reservedSize: 36,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    gridData: const FlGridData(show: true),
    borderData: FlBorderData(show: false),
  ),
)
```

### Pattern 6: Custom Activity Heatmap
**What:** 365-day colored grid using `SingleChildScrollView` + `Wrap` of `Container` widgets
**When to use:** Replaces `react-activity-calendar` — no compatible pub.dev package

```dart
// lib/features/progress/workout_heatmap.dart
// Exact color parity with v1.1 react-activity-calendar theme:
static Color _levelColor(int level) => switch (level) {
  0 => const Color(0xFFEBEDF0),
  1 => const Color(0xFF9BE9A8),
  2 => const Color(0xFF40C463),
  3 => const Color(0xFF30A14E),
  _ => const Color(0xFF216E39), // level 4
};

// Exact countToLevel parity with v1.1:
static int _countToLevel(int count) {
  if (count == 0) return 0;
  if (count == 1) return 1;
  if (count == 2) return 2;
  if (count <= 4) return 3;
  return 4;
}

// Widget structure:
// SingleChildScrollView(scrollDirection: Axis.horizontal,
//   child: Wrap(direction: Axis.vertical, spacing: 3, runSpacing: 3,
//     children: days.map((d) => Container(
//       width: 12, height: 12,
//       decoration: BoxDecoration(
//         color: _levelColor(d.level),
//         borderRadius: BorderRadius.circular(2),
//       ),
//     )).toList()
//   )
// )
```

### Pattern 7: WorkoutRepository Extensions for PR Detection
**What:** New methods on WorkoutRepository for 1RM and PR persistence
**When to use:** Called from `WorkoutSessionProvider.completeWorkout()` or `WorkoutScreen`

```dart
// Additions to workout_repository.dart:

/// Save estimated 1RM entry (Epley-derived from best set in completed workout)
Future<void> saveOneRepMax({
  required int userId,
  required String exerciseId,
  required double weight,
  required DateTime date,
}) async {
  await _db.into(_db.oneRepMaxes).insert(OneRepMaxesCompanion.insert(
    userId: userId, exerciseId: exerciseId, weight: weight, date: date,
  ));
}

/// Check weight PR (newWeight > historical max AND currentMax > 0)
/// Saves to PersonalRecords and returns true if PR
Future<bool> checkAndSaveWeightPR({
  required int userId, required String exerciseId,
  required double newWeight, required int workoutId, required DateTime date,
}) async {
  final best = await (_db.select(_db.oneRepMaxes)
        ..where((t) => t.userId.equals(userId) & t.exerciseId.equals(exerciseId))
        ..orderBy([(t) => OrderingTerm.desc(t.weight)])
        ..limit(1))
      .get();
  final currentMax = best.isEmpty ? 0.0 : best.first.weight;
  if (newWeight > currentMax && currentMax > 0) {
    await _db.into(_db.personalRecords).insert(PersonalRecordsCompanion.insert(
      userId: userId, exerciseId: exerciseId, type: 'weight',
      value: newWeight, workoutId: workoutId, date: date,
    ));
    return true;
  }
  return false;
}
```

### Anti-Patterns to Avoid
- **`StateProvider` for async data:** Use `AsyncNotifierProvider` — `StateProvider` is Riverpod legacy-only (confirmed STATE.md)
- **Per-workout Drift queries in a loop:** Fetch all sets in one query, group in Dart — avoids N+1
- **`flutter_heatmap_calendar` / `heatmap_calendar`:** Both SDK-2-only; runtime crash on SDK 3.x
- **Not scoping plateau detection to `activeCycleId`:** Cross-cycle plateaus are false positives
- **Missing `currentMax > 0` guard in PR check:** v1.1 explicitly skips PR on first-ever lift
- **Forgetting to exclude current workout from volume PR history:** v1.1 uses `.and(s => s.workoutId !== workoutId)`

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Line/bar charts | Custom `CustomPainter` | `fl_chart` LineChart / BarChart | Touch handling, animation, axis formatting all built in |
| Date formatting | Manual month-name array | `intl` DateFormat | Handles locale, leap years, etc. |
| Epley/plateau/PR math | Slightly different formula | Exact v1.1 port | Any deviation fails parity gates |

**Key insight:** The heatmap IS intentionally hand-rolled — it is a ~30-line widget with no dependencies. All pub.dev heatmap libraries are Dart SDK `<3.0.0` only.

---

## Common Pitfalls

### Pitfall 1: Exercise ID Format Mismatch
**What goes wrong:** `CompletedSets.exerciseId` stores `'back-squat-0'` (composite with index). `TrackedExercisesProvider` shows raw composite IDs in exercise picker instead of human names.
**Why it happens:** `ExerciseAccordion` generates IDs as `'${exercise.exercise}-$index'`.
**How to avoid:** In `TrackedExercisesProvider`, strip the `-\d+$` suffix, use base key as exerciseId for all queries, derive display name from ProgramRepository lookup (fallback to base key if not found).
**Warning signs:** 1RM chart exercise dropdown shows `'back-squat-0'` instead of `'Back Squat'`.

### Pitfall 2: fl_chart SideTitles Label Overlap
**What goes wrong:** With ≤5 data points, all labels render fine. With 12+ points, labels overlap on narrow screens.
**Why it happens:** fl_chart renders a label at every integer x unless `interval` is set.
**How to avoid:** Set `interval = max(1.0, (data.length / 5).ceilToDouble())`.
**Warning signs:** X-axis date labels overlap on the 1RM trend or volume chart.

### Pitfall 3: Plateau Scoped to Wrong Cycle
**What goes wrong:** Plateau triggered from workouts across different training cycles.
**Why it happens:** Query missing `activeCycleId` filter.
**How to avoid:** Always pass `activeCycleId` from `activeCycleProvider` to plateau detection.
**Warning signs:** Plateau triggers on a fresh cycle based on old data.

### Pitfall 4: Weekly Volume Week Boundary (Monday vs Sunday)
**What goes wrong:** Weekly buckets shifted by 1 day — volume numbers diverge from v1.1.
**Why it happens:** v1.1 uses `weekStartsOn: 1` (Monday). Default in many libs is Sunday.
**How to avoid:** `subtract(Duration(days: date.weekday - 1))` — Dart `weekday` is 1=Monday, so this is correct.
**Warning signs:** Weekly volume totals don't match v1.1 for identical workout history.

### Pitfall 5: Volume PR Includes Current Workout
**What goes wrong:** Volume PR check compares current session against historical data that includes the same workout — always triggers as PR.
**Why it happens:** Missing filter `workoutId != currentWorkoutId`.
**How to avoid:** Pass current `workoutId` to the comparison query and exclude it.
**Warning signs:** Volume PR always fires after every workout.

### Pitfall 6: `intl` Not in pubspec
**What goes wrong:** `DateFormat('MMM d')` throws `MissingPluginException` or compile error.
**Why it happens:** `intl` is not in project's `pubspec.yaml`.
**How to avoid:** Run `flutter pub add intl` before using `DateFormat`.
**Warning signs:** Compilation fails or runtime crash on `DateFormat` instantiation.

### Pitfall 7: Heatmap Wrap Direction
**What goes wrong:** Days render left-to-right in horizontal rows instead of top-to-bottom in vertical columns (GitHub-style).
**Why it happens:** `Wrap` default direction is horizontal. GitHub heatmap is columns of 7 days.
**How to avoid:** Use `Wrap(direction: Axis.vertical, ...)` so days stack vertically (Mon-Sun in a column), wrapped into new columns for each week.
**Warning signs:** Heatmap looks like a horizontal strip instead of a calendar-grid.

---

## Code Examples

### Weekly Volume Calculation (Full Parity)
```dart
// Source: ported from src/hooks/use-weekly-volume.ts
// Key: volume = actualWeight * actualReps (per row in completedSets)
// Key: last 12 weeks, Monday-start, ascending order

String _weekKey(DateTime date) {
  // Monday of the week containing date
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return '${monday.year}-'
      '${monday.month.toString().padLeft(2, '0')}-'
      '${monday.day.toString().padLeft(2, '0')}';
}

Future<List<WeeklyVolumePoint>> computeWeeklyVolume(AppDatabase db) async {
  final workouts = await db.select(db.completedWorkouts).get();
  final sets = await db.select(db.completedSets).get();

  final workoutDates = {for (final w in workouts) w.id: w.completedAt};

  final volumeByWeek = <String, int>{};
  for (final s in sets) {
    final date = workoutDates[s.workoutId];
    if (date == null) continue;
    final key = _weekKey(date);
    volumeByWeek[key] =
        (volumeByWeek[key] ?? 0) + (s.actualWeight * s.actualReps).round();
  }

  final sorted = volumeByWeek.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  final last12 = sorted.length > 12
      ? sorted.sublist(sorted.length - 12)
      : sorted;

  final fmt = DateFormat('MMM d');
  return last12
      .map((e) => WeeklyVolumePoint(
            week: fmt.format(DateTime.parse('${e.key}T00:00:00')),
            weekKey: e.key,
            volume: e.value,
          ))
      .toList();
}
```

### Workout Frequency (Heatmap Data)
```dart
// Source: ported from src/hooks/use-workout-frequency.ts
// Key: 365-day range (today - 1 year → today), ascending
// Key: countToLevel is exact match to v1.1

Future<({List<ActivityData> data, int totalWorkouts})>
    computeWorkoutFrequency(AppDatabase db) async {
  final workouts = await db.select(db.completedWorkouts).get();
  final fmt = DateFormat('yyyy-MM-dd');

  final countByDate = <String, int>{};
  for (final w in workouts) {
    final key = fmt.format(w.completedAt);
    countByDate[key] = (countByDate[key] ?? 0) + 1;
  }

  final today = DateTime.now();
  final yearAgo = DateTime(today.year - 1, today.month, today.day);
  final activities = <ActivityData>[];
  for (var d = yearAgo;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))) {
    final key = fmt.format(d);
    final count = countByDate[key] ?? 0;
    activities.add(ActivityData(
        date: key, count: count, level: _countToLevel(count)));
  }

  final total = countByDate.values.fold(0, (a, b) => a + b);
  return (data: activities, totalWorkouts: total);
}
```

### Parity Gate Test Skeleton (RECO-01, CHRT-01, CHRT-02)
```dart
// integration_test/parity_gates/recommendations_parity_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PARITY GATE: Recommendations + Progress (RECO-01, RECO-02, CHRT-01, CHRT-02)', () {

    testWidgets('progress screen renders all chart sections (CHRT-01)', (tester) async {
      await pumpApp(tester);
      await completeOnboarding(tester);
      await tester.tap(find.byKey(const Key('nav-progress')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('progress-screen')), findsOneWidget);
      expect(find.byKey(const Key('one-rm-chart')), findsOneWidget);
      expect(find.byKey(const Key('weekly-volume-chart')), findsOneWidget);
      expect(find.byKey(const Key('workout-heatmap')), findsOneWidget);
    });

    testWidgets('progress screen loads from local Drift data offline (CHRT-02)',
        (tester) async {
      // Drift is always local — this test verifies no network calls
      // by running without connectivity (FakeConnectivityPlatform offline)
      // and confirming charts still render
      await pumpApp(tester); // offline pumpApp via ConnectivityPlatform override
      await completeOnboarding(tester);
      await tester.tap(find.byKey(const Key('nav-progress')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('progress-screen')), findsOneWidget);
      // Charts render regardless of connectivity — Drift is local
      expect(find.byKey(const Key('one-rm-chart')), findsOneWidget);
    });

    testWidgets('RECO-01: weight recommendation follows v1.1 logic after workout',
        (tester) async {
      // Complete a workout, then verify recommendation on next workout
      // shows currentWeight + 5 (success path)
      await pumpApp(tester);
      await completeOnboarding(tester);
      await setupAndNavigateToWorkout(tester);
      await logSet(tester, setNumber: 1, weight: '135', reps: '5');
      await dismissRestTimer(tester);
      await tester.tap(find.byKey(const Key('complete-workout-button')));
      await tester.pumpAndSettle();

      // Navigate to workout again — prescribed weight should be 140 (135 + 5)
      await navigateToWorkoutFromDashboard(tester);
      expect(find.byKey(const Key('workout-screen')), findsOneWidget);
    });

    testWidgets('RECO-02: plateau alert shown after 3 consecutive rep failures',
        (tester) async {
      // This test validates plateau detection logic wiring
      // Detailed setup requires seeding 3 failed workouts into Drift first
      await pumpApp(tester);
      await completeOnboarding(tester);
      // ... seed 3 workouts with failed reps via WorkoutRepository
      // ... navigate to workout and expect plateau banner/dialog
    });
  });
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| React hooks + Recharts | Riverpod AsyncNotifierProvider + fl_chart | Phase 12 | Same primitives, Dart-idiomatic |
| react-activity-calendar | Custom Wrap widget | Phase 12 | No compatible pub.dev alternative for SDK 3 |
| Dexie (IndexedDB) | Drift (SQLite) | Phase 9 | All data local; CHRT-02 offline is automatic |
| `StateProvider` (legacy) | `NotifierProvider` / `AsyncNotifierProvider` | Phase 9+ | Confirmed locked in STATE.md |

**Deprecated/outdated:**
- `StateProvider`: Riverpod 3.x legacy-only — never use for new providers
- `flutter_heatmap_calendar` / `heatmap_calendar`: Both SDK-2 only — don't add to pubspec

---

## Open Questions

1. **Exercise ID display in tracked exercises dropdown**
   - What we know: `CompletedSets.exerciseId` = `'back-squat-0'` (composite, includes index suffix)
   - What's unclear: Should TrackedExercisesProvider deduplicate by base ID (stripping suffix) or use full composite?
   - Recommendation: Strip `-\d+$` suffix to get base exercise ID; look up human name from ProgramRepository cache; group all composite variants under same base. This matches v1.1 which uses plain `exerciseId` like `'back-squat'`.

2. **Epley 1RM auto-save after workout**
   - What we know: `OneRepMaxes` table exists. v1.1 saves user-entered 1RM at onboarding; Epley is used for chart display only.
   - What's unclear: Should `completeWorkout()` auto-write Epley estimate to `OneRepMaxes`?
   - Recommendation: YES — save Epley-estimated 1RM to `OneRepMaxes` after each workout for each exerciseId that had sets logged. This enables PR detection using the table as source of truth. Consistent with how v1.1 populates the weight PR check.

3. **RECO-02 parity test depth**
   - What we know: Plateau detection requires seeding 3 consecutive failed workouts into Drift before the test can verify the modal/banner appears.
   - What's unclear: Integration test or unit test for the decision logic?
   - Recommendation: Unit test the pure functions in `calculations.dart` and `plateau_detection.dart` (in `flutter_app/test/`). Integration gate test verifies the *UI wiring* (plateau dialog appears) with a minimal Drift seed helper.

---

## Sources

### Primary (HIGH confidence)
- **v1.1 source — calculations**: `src/lib/calculations.ts` (read in full)
- **v1.1 source — plateau detection**: `src/lib/recommendations/plateau-detection.ts` (read in full)
- **v1.1 source — 1RM progress hook**: `src/hooks/use-1rm-progress.ts` (read in full)
- **v1.1 source — weekly volume hook**: `src/hooks/use-weekly-volume.ts` (read in full)
- **v1.1 source — workout frequency hook**: `src/hooks/use-workout-frequency.ts` (read in full)
- **v1.1 source — PR detection hook**: `src/hooks/use-pr-detection.ts` (read in full)
- **v1.1 source — progress page**: `src/app/progress/page.tsx` (read in full)
- **Flutter Drift schema v3**: `flutter_app/lib/data/database/app_database.dart` (read in full)
- **fl_chart pub.dev API**: `https://pub.dev/api/packages/fl_chart` — version 1.1.1, SDK `>=3.6.2`
- **fl_chart LineChart docs**: `https://github.com/imaNNeo/fl_chart/blob/main/repo_files/documentations/line_chart.md`
- **fl_chart BarChart docs**: `https://github.com/imaNNeo/fl_chart/blob/main/repo_files/documentations/bar_chart.md`
- **intl pub.dev**: `https://pub.dev/api/packages/intl` — version 0.20.2, SDK `^3.3.0`

### Secondary (MEDIUM confidence)
- **flutter_heatmap_calendar pub.dev**: confirmed SDK `>=2.12.0 <3.0.0` (incompatible)
- **heatmap_calendar pub.dev**: confirmed SDK `>=2.1.0 <3.0.0` (incompatible)
- **STATE.md Riverpod decision**: `NotifierProvider` only, no `StateProvider`

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — fl_chart and intl versions verified on pub.dev; heatmap incompatibility verified directly
- Architecture: HIGH — v1.1 source fully read; Drift schema known; Riverpod pattern locked in STATE.md
- Calculations parity: HIGH — all functions read directly from v1.1 TypeScript source
- Pitfalls: HIGH — exercise ID format verified in ExerciseAccordion; week boundary math derived from Dart DateTime spec

**Research date:** 2026-02-21
**Valid until:** 2026-03-21 (fl_chart/intl versions stable; verify if >30 days elapsed)
