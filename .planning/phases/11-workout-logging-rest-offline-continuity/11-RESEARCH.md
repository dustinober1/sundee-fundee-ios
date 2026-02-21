# Phase 11 Research: Workout Logging + Rest Timer + Offline Continuity

**Phase Goal**: Users can complete the full workout logging loop in Flutter, including rest timing and offline continuity.

**Requirements**:
- WORK-01: User can log sets (reps/weight), complete workouts, and persist results with v1.1-equivalent semantics
- WORK-02: User can use rest-timer workflow behavior equivalent to v1.1 during active workouts
- WORK-03: User can continue workout logging offline and retain local workout state through reconnect

**Research Question**: What do I need to know to PLAN this phase well?

---

## 1. v1.1 Workout Logging Architecture (Reference Implementation)

### 1.1 Data Model

**v1.1 TypeScript Interfaces** (`src/types/workout.ts`):

```typescript
interface CompletedWorkout {
  id: string;
  userId: string;
  activeCycleId: string;
  programId: string;
  week: number;
  day?: number;
  sessionId?: string;
  completedAt: Date;
  duration?: number;
  notes?: string;
}

interface CompletedSet {
  id: string;
  workoutId: string;
  exerciseId: string;
  setNumber: number;
  prescribedWeight?: number;
  actualWeight: number;
  prescribedReps: number;
  actualReps: number;
  rpe?: number;
  restSeconds?: number;
  overrideReason?: WeightOverrideReason;
  createdAt: Date;
}

type WeightOverrideReason = 'injured' | 'fatigued' | 'just_because' | 'other';

interface OneRepMax {
  id: string;
  userId: string;
  exerciseId: string;
  weight: number;
  date: Date;
}

interface PersonalRecord {
  id: string;
  userId: string;
  exerciseId: string;
  type: 'weight' | 'volume';
  value: number;
  workoutId: string;
  date: Date;
}
```

**v1.1 Dexie Schema** (`src/lib/db/dexie.ts`):

```typescript
version(4).stores({
  completedWorkouts: 'id, userId, activeCycleId, sessionId, completedAt',
  completedSets: 'id, workoutId, exerciseId',
  oneRepMaxes: 'id, userId, exerciseId, date',
  personalRecords: 'id, userId, exerciseId, type, date'
});
```

**Key Observations**:
- Sets belong to a workout via `workoutId` (1:N relationship)
- Workouts belong to an active cycle via `activeCycleId` (1:N relationship)
- Both `prescribedWeight` and `actualWeight` are stored (supports weight override tracking)
- `overrideReason` is optional, only required when user changes recommended weight
- `restSeconds` stored per set (actual rest taken, not prescribed)
- PRs and 1RMs are separate tables, updated post-workout

### 1.2 Workout Session Flow (v1.1)

**From** `src/app/workout/[id]/page.tsx`:

```typescript
async function handleWorkoutComplete(data: { completed: boolean; sets: CollectedSetData[] }) {
  if (!data.completed || !user) return;

  // 1. Resolve active cycle (or create fallback ID)
  const activeCycles = await getActiveCycles(user.id);
  const activeCycleId = activeCycles[0]?.id ?? generateId();

  // 2. Save workout record
  const workoutId = generateId();
  await saveCompletedWorkout({
    id: workoutId,
    userId: user.id,
    activeCycleId,
    programId,
    week: currentWeek,
    sessionId: selectedSession?.sessionId,
    completedAt: new Date()
  });

  // 3. Save all set records
  for (const set of data.sets) {
    await saveCompletedSet({
      id: generateId(),
      workoutId,
      exerciseId: set.exerciseId,
      setNumber: set.setNumber,
      prescribedWeight: set.prescribedWeight,
      actualWeight: set.actualWeight,
      prescribedReps: set.prescribedReps,
      actualReps: set.actualReps,
      overrideReason: set.overrideReason,
      createdAt: new Date()
    });
  }

  // 4. Trigger sync (Supabase background sync)
  await syncAfterWorkout(workoutId);

  // 5. Navigate back
  router.back();
}
```

**Key Implementation Details**:
- Sets collected in-memory during workout session (`CollectedSetData[]`)
- All data saved atomically at workout completion (transactional batch)
- Sync triggered after local save (non-blocking)
- No intermediate persistence during workout (ephemeral state)

### 1.3 Set Input UI Pattern

**From** `src/components/program/workout-session-view.tsx`:

```typescript
interface CollectedSetData {
  exerciseId: string;
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: number;
  actualWeight: number;
  actualReps: number;
  overrideReason?: WeightOverrideReason;
}

// State management during workout
const [completedSets, setCompletedSets] = useState<Set<string>>(new Set());
const [setDataMap, setSetDataMap] = useState<Record<string, CollectedSetData>>({});

const handleSetChange = async (
  exerciseIndex: number,
  exerciseId: string,
  setNumber: number,
  data: { weight: number; reps: number; prescribedWeight: number; prescribedReps: number }
) => {
  const key = `${exerciseIndex}-${setNumber}`;

  const updatedSetData: CollectedSetData = {
    exerciseId,
    setNumber,
    prescribedWeight: data.prescribedWeight,
    prescribedReps: data.prescribedReps,
    actualWeight: data.weight,
    actualReps: data.reps,
  };

  setCompletedSets(previous => new Set(previous).add(key));
  setSetDataMap(previous => ({ ...previous, [key]: updatedSetData }));

  // PR detection runs inline (non-blocking)
  if (data.weight > 0) {
    const isWeightPR = await checkWeightPR(exerciseId, data.weight);
    const isVolumePR = await checkVolumePR(exerciseId, data.weight, data.reps);
    if (isWeightPR) setPrCelebration({ isVisible: true, prType: 'weight' });
    else if (isVolumePR) setPrCelebration({ isVisible: true, prType: 'volume' });
  }
};
```

**From** `src/components/program/set-input-v2.tsx`:

```typescript
// Pre-filled recommendation pattern
const initialWeight = recommendedWeight ?? prescribedWeight;
const [weight, setWeight] = useState(initialWeight);

// Override reason prompt (only if weight deviates from recommendation)
function handleWeightBlur() {
  if (recommendedWeight !== undefined && weight !== recommendedWeight && !hasOverridden) {
    setShowOverrideSelect(true);
  }
}
```

**Key UI/UX Patterns**:
- Weight pre-fills with recommendation (or fallback to prescribed)
- Override reason prompted on blur if weight changes from recommendation
- Sets tracked by composite key: `${exerciseIndex}-${setNumber}`
- PR detection triggers confetti celebration inline (non-blocking)

---

## 2. v1.1 Rest Timer Architecture

### 2.1 Rest Timer Hook (`src/hooks/useRestTimer.ts`)

**Timer State**:

```typescript
interface RestTimerState {
  status: 'idle' | 'running' | 'paused' | 'complete';
  durationSeconds: number;
  remainingSeconds: number;
  startedAt: number | null;
  isExpanded: boolean;
  exerciseName: string | null;
}

interface RestTimerSettings {
  notificationType: 'sound' | 'vibrate' | 'both' | 'none';
  defaultRestSeconds: number;  // Default: 180 (3 min)
  autoStartEnabled: boolean;
}
```

**Core API**:

```typescript
const {
  status, remainingSeconds, exerciseName,
  startRest,    // (durationSeconds: number, exerciseName?: string) => void
  pause,        // () => void
  resume,       // () => void
  addTime,      // (seconds: number) => void
  subtractTime, // (seconds: number) => void
  cancel,       // () => void (reset to idle)
  skip,         // () => void (jump to complete)
  settings,
  setSettings
} = useRestTimer();
```

**Implementation Details**:

1. **Countdown via setInterval** (1-second tick)
2. **Background handling**: Uses `visibilitychange` event to recalculate remaining time when app regains focus
3. **Timestamp-based accuracy**: `timestampRef` tracks start time; recalculates on foreground return to prevent drift
4. **Notification on complete**: Triggers sound, vibration, or web notification (user permission required)
5. **Settings persisted to localStorage**: `rest-timer-settings` key

**Visibility Handling**:

```typescript
useEffect(() => {
  const handleVisibilityChange = () => {
    if (document.hidden) {
      // Store remaining time when going to background
      remainingWhenHiddenRef.current = remainingSeconds;
      clearInterval(intervalRef.current);
    } else {
      // Recalculate when coming back to foreground
      if (status === 'running' && timestampRef.current) {
        const remaining = calculateRemainingFromTimestamp();
        setRemainingSeconds(remaining);
        if (remaining <= 0) {
          setStatus('complete');
          triggerNotification();
        } else {
          startInterval();
        }
      }
    }
  };
  document.addEventListener('visibilitychange', handleVisibilityChange);
  return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
}, [status, remainingSeconds, ...]);
```

### 2.2 Rest Timer UI Components

**Components** (`src/components/rest-timer/`):
- `RestTimerPill.tsx` — Collapsed footer pill (shows countdown, tap to expand)
- `RestTimerExpanded.tsx` — Full-screen overlay (circular progress, controls)
- `RestTimerSettings.tsx` — Settings modal (notification type, default duration, auto-start)

**Integration Pattern**:

```typescript
// RestTimerContext wraps the entire app
<RestTimerProvider>
  <App />
</RestTimerProvider>

// Workout session calls startRest after set completion
const { startRest } = useRestTimerContext();

function handleSetComplete() {
  const restDuration = exercise.restMinutes * 60; // Convert to seconds
  startRest(restDuration, exerciseName);
}
```

**Key Features**:
- **Auto-start option**: Automatically starts timer after set completion
- **Exercise-specific rest**: Duration pulled from program JSON (`restMinutes` field)
- **Add/subtract time**: ±15 second buttons in expanded view
- **Skip/cancel**: User can skip rest or cancel timer entirely
- **Persistent across navigation**: Timer continues running if user navigates away (global context)

---

## 3. Offline Continuity Pattern (v1.1)

### 3.1 Dexie Local-First Strategy

**Architecture**:
1. **All writes go to Dexie first** (IndexedDB)
2. **Sync queue for Supabase** (background, non-blocking)
3. **Read from Dexie** (IndexedDB is source of truth for UI)

**Sync Strategy** (`src/contexts/user-context.tsx`):

```typescript
async function syncAfterWorkout(workoutId: string) {
  if (!isOnline) {
    // Queue for later sync (not implemented in v1.1 — sync happens on next online event)
    return;
  }

  // Background sync to Supabase (non-blocking)
  try {
    const workout = await db.completedWorkouts.get(workoutId);
    const sets = await db.completedSets.where('workoutId').equals(workoutId).toArray();
    await supabase.from('completed_workouts').insert(workout);
    await supabase.from('completed_sets').insert(sets);
  } catch (error) {
    console.error('Sync failed, will retry on next online event', error);
  }
}
```

**Key Observations**:
- v1.1 does **not** persist sync queue (in-memory only)
- If sync fails, user must trigger manually or wait for next online event
- Workout data **always persists locally** regardless of online status
- No workout-in-progress persistence (ephemeral state until completion)

### 3.2 connectivity_plus Integration (Flutter)

**Current Flutter Setup** (`flutter_app/lib/core/connectivity/`):

```dart
// Riverpod provider streams connectivity status
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// UI reads connectivity state
final connectivityAsync = ref.watch(connectivityProvider);
final isOffline = connectivityAsync.when(
  data: (results) => results.every((r) => r == ConnectivityResult.none),
  loading: () => false,
  error: (_, __) => false,
);
```

**Offline Banner** (`flutter_app/lib/main.dart`):

```dart
if (isOffline)
  const MaterialBanner(
    key: Key('offline-banner'),
    content: Text('You are offline'),
    actions: [SizedBox.shrink()],
  )
```

**Existing Parity Gate** (`integration_test/parity_gates/offline_parity_test.dart`):

```dart
testWidgets('app functions offline — Drift persists locally', (tester) async {
  fakeConnectivity.goOffline();
  await pumpApp(tester);
  await completeOnboarding(tester);

  // Verify Drift persistence
  final db = container.read(databaseProvider);
  final users = await db.select(db.users).get();
  expect(users, isNotEmpty);
  expect(users.first.name, 'Test User');
});
```

**Key Takeaways**:
- Flutter already has `connectivity_plus` installed (^7.0.0)
- Offline detection works (tested in parity gate)
- Drift (SQLite) persists locally (no network dependency)
- **Need to add**: Workout-while-offline scenario to parity gate

---

## 4. Flutter Drift Schema Extension Requirements

### 4.1 Current Drift Schema (v2)

```dart
class Users extends Table { ... }
class ActiveCycles extends Table { ... }

@DriftDatabase(tables: [Users, ActiveCycles])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;
}
```

### 4.2 Required New Tables (v3)

**CompletedWorkouts Table**:

```dart
class CompletedWorkouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get activeCycleId => integer().references(ActiveCycles, #id)();
  TextColumn get programId => text()();
  IntColumn get week => integer()();
  IntColumn get day => integer().nullable()();
  TextColumn get sessionId => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get duration => integer().nullable()();  // seconds
  TextColumn get notes => text().nullable()();
}
```

**CompletedSets Table**:

```dart
class CompletedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(CompletedWorkouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  IntColumn get setNumber => integer()();
  RealColumn get prescribedWeight => real().nullable()();
  RealColumn get actualWeight => real()();
  IntColumn get prescribedReps => integer()();
  IntColumn get actualReps => integer()();
  IntColumn get rpe => integer().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  TextColumn get overrideReason => text().nullable()();  // enum: injured, fatigued, just_because, other
  DateTimeColumn get createdAt => dateTime()();
}
```

**OneRepMaxes Table**:

```dart
class OneRepMaxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get exerciseId => text()();
  RealColumn get weight => real()();
  DateTimeColumn get date => dateTime()();
}
```

**PersonalRecords Table**:

```dart
class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get exerciseId => text()();
  TextColumn get type => text()();  // 'weight' or 'volume'
  RealColumn get value => real()();
  IntColumn get workoutId => integer().references(CompletedWorkouts, #id)();
  DateTimeColumn get date => dateTime()();
}
```

**Migration Strategy**:

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      await m.createTable(activeCycles);
    }
    if (from < 3) {
      await m.createTable(completedWorkouts);
      await m.createTable(completedSets);
      await m.createTable(oneRepMaxes);
      await m.createTable(personalRecords);
    }
  },
);
```

**Index Requirements** (for query performance):

```dart
// In table definitions:
@override
List<Set<Column>> get uniqueKeys => [
  {userId, exerciseId, date},  // OneRepMaxes: one 1RM per exercise per day
];

// Drift auto-creates indexes for foreign keys (workoutId, userId, activeCycleId)
```

---

## 5. Riverpod State Architecture for Workout Session

### 5.1 Prior Decision Context

**From Phase 10 decisions**:
- Use `NotifierProvider` (NOT `StateProvider`) for mutable state
- Expose mutations via methods on `Notifier` (not direct state assignment)
- Use `if (mounted)` for async gaps in `ConsumerState` (NOT `if (context.mounted)`)

### 5.2 Workout Session State Requirements

**Ephemeral State** (in-memory during workout):
- Current session (programId, week, sessionId)
- Collected set data (exerciseId, setNumber, weights, reps)
- Completed set tracker (Set<String> of completed set keys)
- Rest timer state (status, remaining time, current exercise)
- Workout start time (for duration calculation)

**Persistent State** (Drift):
- Completed workouts (post-submission)
- Completed sets (post-submission)
- Active cycle progress (currentWeek, currentSessionId)

**Recommended Provider Structure**:

```dart
// Workout session state (ephemeral, NotifierProvider)
class WorkoutSessionState {
  final String programId;
  final int week;
  final String sessionId;
  final Map<String, SetData> setDataMap;
  final Set<String> completedSets;
  final DateTime startTime;

  WorkoutSessionState({...});

  WorkoutSessionState copyWith({...}) => ...;
}

class WorkoutSessionNotifier extends Notifier<WorkoutSessionState?> {
  @override
  WorkoutSessionState? build() => null;

  void startSession(String programId, int week, String sessionId) {
    state = WorkoutSessionState(
      programId: programId,
      week: week,
      sessionId: sessionId,
      setDataMap: {},
      completedSets: {},
      startTime: DateTime.now(),
    );
  }

  void logSet(String exerciseId, int setNumber, SetData data) {
    if (state == null) return;
    final key = '$exerciseId-$setNumber';
    state = state!.copyWith(
      setDataMap: {...state!.setDataMap, key: data},
      completedSets: {...state!.completedSets, key},
    );
  }

  Future<void> completeWorkout(int userId, int activeCycleId) async {
    if (state == null) return;

    final db = ref.read(databaseProvider);
    final workoutRepo = WorkoutRepository(db);

    // Transactional save
    await workoutRepo.saveWorkout(
      userId: userId,
      activeCycleId: activeCycleId,
      programId: state!.programId,
      week: state!.week,
      sessionId: state!.sessionId,
      sets: state!.setDataMap.values.toList(),
      completedAt: DateTime.now(),
      duration: DateTime.now().difference(state!.startTime).inSeconds,
    );

    // Clear session state
    state = null;
  }

  void cancelWorkout() {
    state = null;
  }
}

final workoutSessionProvider = NotifierProvider<WorkoutSessionNotifier, WorkoutSessionState?>(
  () => WorkoutSessionNotifier(),
);
```

### 5.3 Rest Timer State (Flutter)

**Option A: Port `useRestTimer` hook to Riverpod Notifier**

```dart
class RestTimerState {
  final String status;  // 'idle', 'running', 'paused', 'complete'
  final int durationSeconds;
  final int remainingSeconds;
  final DateTime? startedAt;
  final bool isExpanded;
  final String? exerciseName;

  RestTimerState({...});
}

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;

  @override
  RestTimerState build() => RestTimerState(
    status: 'idle',
    durationSeconds: 0,
    remainingSeconds: 0,
    startedAt: null,
    isExpanded: false,
    exerciseName: null,
  );

  void startRest(int durationSeconds, [String? exerciseName]) {
    _timer?.cancel();
    state = RestTimerState(
      status: 'running',
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      startedAt: DateTime.now(),
      isExpanded: true,
      exerciseName: exerciseName,
    );
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(status: 'complete', remainingSeconds: 0);
        _triggerNotification();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: 'paused');
  }

  void resume() {
    state = state.copyWith(status: 'running');
    _startCountdown();
  }

  void cancel() {
    _timer?.cancel();
    state = build();  // Reset to idle
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(status: 'complete', remainingSeconds: 0);
  }

  void _triggerNotification() {
    // TODO: Implement vibration/sound/notification (platform-specific)
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  () => RestTimerNotifier(),
);
```

**Option B: Use `flutter_timer` package (third-party)**

- Pros: Handles lifecycle, background state, notifications
- Cons: Additional dependency, may conflict with GSD conventions

**Recommendation**: Port to Riverpod Notifier (Option A) for full control and parity with v1.1

---

## 6. Background Timer Handling (Flutter)

### 6.1 Challenge: Timer Drift on App Backgrounding

**Problem**: Flutter's `Timer` pauses when app goes to background on iOS/Android.

**v1.1 Solution** (Web): Uses `visibilitychange` event + timestamp-based recalculation

**Flutter Solution**: Use `WidgetsBindingObserver` to detect app lifecycle changes

```dart
class RestTimerNotifier extends Notifier<RestTimerState> with WidgetsBindingObserver {
  @override
  RestTimerState build() {
    WidgetsBinding.instance.addObserver(this);
    return RestTimerState(...);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalculateRemainingTime();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  void _recalculateRemainingTime() {
    if (this.state.status != 'running' || this.state.startedAt == null) return;

    final elapsed = DateTime.now().difference(this.state.startedAt!).inSeconds;
    final remaining = this.state.durationSeconds - elapsed;

    if (remaining <= 0) {
      this.state = this.state.copyWith(status: 'complete', remainingSeconds: 0);
      _triggerNotification();
    } else {
      this.state = this.state.copyWith(remainingSeconds: remaining);
      _startCountdown();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
```

**Testing Strategy**:
- Unit test: `_recalculateRemainingTime()` logic with mock timestamps
- Widget test: Simulate `didChangeAppLifecycleState` callbacks
- Integration test: Manual verification (hard to automate app backgrounding)

---

## 7. Notification/Vibration on Timer Completion

### 7.1 Platform Requirements

**iOS**: Requires `local_notifications` package + `Info.plist` permissions
**Android**: Requires notification channel setup + foreground service (for background timers)
**Web**: Uses Web Notifications API (already implemented in v1.1)

### 7.2 Minimal Viable Implementation (Phase 11)

**Vibration Only** (simplest cross-platform):

```yaml
# pubspec.yaml
dependencies:
  vibration: ^2.0.0  # Cross-platform vibration
```

```dart
import 'package:vibration/vibration.dart';

void _triggerNotification() {
  // Check if device supports vibration
  Vibration.hasVibrator().then((hasVibrator) {
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 500);  // 500ms buzz
    }
  });

  // TODO Phase 12: Add sound and push notifications
}
```

**Defer to Phase 12**:
- Sound playback (`audioplayers` package)
- Push notifications (`flutter_local_notifications` package)
- Notification settings UI (sound/vibrate/both/none)

**Parity Gate**: Test vibration triggers on timer complete (manual verification)

---

## 8. Workout Repository Pattern

### 8.1 Transactional Save Pattern

**Challenge**: Save workout + all sets as atomic transaction (rollback on failure)

**Drift Solution**: Use `transaction()` method

```dart
class WorkoutRepository {
  final AppDatabase _db;

  WorkoutRepository(this._db);

  Future<int> saveWorkout({
    required int userId,
    required int activeCycleId,
    required String programId,
    required int week,
    required String sessionId,
    required List<SetData> sets,
    required DateTime completedAt,
    int? duration,
  }) async {
    return await _db.transaction(() async {
      // 1. Insert workout
      final workoutId = await _db.into(_db.completedWorkouts).insert(
        CompletedWorksCompanion.insert(
          userId: userId,
          activeCycleId: activeCycleId,
          programId: programId,
          week: week,
          sessionId: Value(sessionId),
          completedAt: completedAt,
          duration: Value(duration),
        ),
      );

      // 2. Insert all sets
      for (final set in sets) {
        await _db.into(_db.completedSets).insert(
          CompletedSetsCompanion.insert(
            workoutId: workoutId,
            exerciseId: set.exerciseId,
            setNumber: set.setNumber,
            prescribedWeight: Value(set.prescribedWeight),
            actualWeight: set.actualWeight,
            prescribedReps: set.prescribedReps,
            actualReps: set.actualReps,
            overrideReason: Value(set.overrideReason),
            createdAt: completedAt,
          ),
        );
      }

      return workoutId;
    });
  }

  Future<List<CompletedWorkout>> getWorkoutHistory(int userId) async {
    return await (_db.select(_db.completedWorkouts)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Future<List<CompletedSet>> getSetsForWorkout(int workoutId) async {
    return await (_db.select(_db.completedSets)
          ..where((t) => t.workoutId.equals(workoutId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .get();
  }
}
```

**Repository Riverpod Provider**:

```dart
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});
```

---

## 9. Parity Gate Test Requirements

### 9.1 Update Existing Parity Gate

**File**: `integration_test/parity_gates/workout_parity_test.dart`

**Current State**: Only tests navigation to workout screen

**Required Updates**:

```dart
testWidgets('logs sets and completes workout with persistence', (tester) async {
  await pumpApp(tester);
  await completeOnboarding(tester);

  // Navigate to workout
  await tester.tap(find.byKey(const Key('nav-programs')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('program-back-squat-complete-cycle')));
  await tester.pumpAndSettle();

  // Log first set (find weight/reps input fields)
  await tester.enterText(find.byKey(const Key('set-1-weight-input')), '135');
  await tester.enterText(find.byKey(const Key('set-1-reps-input')), '5');
  await tester.tap(find.byKey(const Key('set-1-log-button')));
  await tester.pumpAndSettle();

  // Complete workout
  await tester.tap(find.byKey(const Key('complete-workout-button')));
  await tester.pumpAndSettle();

  // Verify persistence: query DB for workout and sets
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const Key('dashboard-screen'))),
  );
  final db = container.read(databaseProvider);
  final workouts = await db.select(db.completedWorkouts).get();
  expect(workouts, hasLength(1));
  expect(workouts.first.programId, 'back-squat-complete-cycle');

  final sets = await (db.select(db.completedSets)
        ..where((t) => t.workoutId.equals(workouts.first.id)))
      .get();
  expect(sets, hasLength(1));
  expect(sets.first.actualWeight, 135);
  expect(sets.first.actualReps, 5);
});

testWidgets('rest timer starts after set completion', (tester) async {
  await pumpApp(tester);
  await completeOnboarding(tester);

  // Navigate to workout
  await tester.tap(find.byKey(const Key('nav-programs')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('program-back-squat-complete-cycle')));
  await tester.pumpAndSettle();

  // Log first set
  await tester.enterText(find.byKey(const Key('set-1-weight-input')), '135');
  await tester.enterText(find.byKey(const Key('set-1-reps-input')), '5');
  await tester.tap(find.byKey(const Key('set-1-log-button')));
  await tester.pumpAndSettle();

  // Verify rest timer appears (pill or expanded view)
  expect(find.byKey(const Key('rest-timer-pill')), findsOneWidget);
  expect(find.textContaining('3:00'), findsOneWidget);  // 3-minute rest

  // Wait 2 seconds and verify countdown
  await tester.pump(const Duration(seconds: 2));
  expect(find.textContaining('2:58'), findsOneWidget);
});
```

### 9.2 Offline Continuity Parity Gate

**File**: `integration_test/parity_gates/offline_parity_test.dart`

**Add Test**:

```dart
testWidgets('completes workout while offline and persists locally', (tester) async {
  fakeConnectivity.goOffline();
  await pumpApp(tester);
  await completeOnboarding(tester);

  // Navigate to workout
  await tester.tap(find.byKey(const Key('nav-programs')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('program-back-squat-complete-cycle')));
  await tester.pumpAndSettle();

  // Log set while offline
  await tester.enterText(find.byKey(const Key('set-1-weight-input')), '135');
  await tester.enterText(find.byKey(const Key('set-1-reps-input')), '5');
  await tester.tap(find.byKey(const Key('set-1-log-button')));
  await tester.pumpAndSettle();

  // Complete workout
  await tester.tap(find.byKey(const Key('complete-workout-button')));
  await tester.pumpAndSettle();

  // Verify Drift persistence (offline)
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const Key('dashboard-screen'))),
  );
  final db = container.read(databaseProvider);
  final workouts = await db.select(db.completedWorkouts).get();
  expect(workouts, hasLength(1));

  // Reconnect and verify sync (if sync is implemented)
  fakeConnectivity.goOnline();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  // TODO: Verify Supabase sync (Phase 12)
});
```

---

## 10. Key Decisions & Constraints

### 10.1 Technical Constraints

| Constraint | Source | Impact |
|------------|--------|--------|
| Flutter Riverpod 3.x | Prior decision | Use `NotifierProvider` pattern (not StateProvider) |
| Drift ^2.31.0 | Prior decision | SQLite persistence, schema migrations |
| go_router ^17.1.0 | Prior decision | Navigation stack management |
| connectivity_plus ^7.0.0 | Prior decision | Offline detection |
| No freezed for models | Prior decision | Use plain Dart fromJson (avoid build_runner conflicts) |
| Key-only selectors in tests | Prior decision | Platform-agnostic test keys |

### 10.2 Implementation Priorities

**Phase 11 Scope** (v1.1 parity):
1. ✅ Workout logging (set input, save to Drift)
2. ✅ Rest timer (countdown, pause/resume, skip)
3. ✅ Offline continuity (Drift persistence, offline banner)
4. ❌ Supabase sync (defer to Phase 12)
5. ❌ Sound notifications (defer to Phase 12)
6. ❌ PR detection/celebration (defer to Phase 12)
7. ❌ Weight recommendations (defer to Phase 12)

**Minimal Viable Timer** (Phase 11):
- Countdown display (MM:SS format)
- Pause/resume/skip controls
- Vibration on completion
- Background recalculation (via `WidgetsBindingObserver`)
- **No sound, no push notifications** (Phase 12)

**Minimal Viable Set Input** (Phase 11):
- Weight and reps inputs (text fields)
- Prescribed vs actual tracking
- Override reason (optional select)
- **No weight recommendations** (requires calculation logic from Phase 12)

### 10.3 Schema Version Progression

| Version | Tables Added | Migration Complexity |
|---------|--------------|----------------------|
| v1 | Users | Initial schema |
| v2 | ActiveCycles | Simple table addition |
| v3 | CompletedWorkouts, CompletedSets, OneRepMaxes, PersonalRecords | Complex (4 tables, foreign keys) |

**Migration Testing**:
- Create v2 database with test data
- Run migration to v3
- Verify data integrity and foreign key constraints

---

## 11. UI/UX Parity Checklist

### 11.1 Workout Session Screen

**v1.1 Features**:
- [x] Session header (phase name, week, session name)
- [x] Exercise list (expandable cards)
- [x] Set input rows (weight, reps per set)
- [x] Set completion checkmarks
- [x] Complete workout button (enabled when all sets logged)
- [ ] Weight recommendations (deferred to Phase 12)
- [ ] Plateau detection modal (deferred to Phase 12)
- [ ] PR celebration confetti (deferred to Phase 12)

**Flutter Parity Targets** (Phase 11):
- [x] Session header with program/phase/week metadata
- [x] Exercise accordion (one exercise expanded at a time)
- [x] Set input fields (weight, reps) with prescribed values shown
- [x] Set completion visual indicator (checkmark or color change)
- [x] Complete workout button (bottom action bar)
- [x] Navigation back to dashboard on completion

### 11.2 Rest Timer UI

**v1.1 Features**:
- [x] Collapsed pill (footer, shows countdown and exercise name)
- [x] Expanded view (full-screen overlay, circular progress)
- [x] Pause/resume buttons
- [x] Add time (+15s), subtract time (-15s)
- [x] Skip rest button
- [x] Cancel timer (X button)
- [x] Settings modal (notification type, default duration)

**Flutter Parity Targets** (Phase 11):
- [x] Bottom sheet or modal (not footer pill — Flutter UX pattern)
- [x] Countdown display (MM:SS, centered)
- [x] Pause/resume button
- [x] Skip button
- [x] Cancel button (dismiss sheet)
- [ ] Add/subtract time buttons (nice-to-have, can defer)
- [ ] Settings sheet (defer to Phase 12)

**Recommendation**: Use Flutter `showModalBottomSheet` with draggable handle (simpler than footer pill)

---

## 12. Risk Assessment

### 12.1 High-Risk Areas

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Timer drift on backgrounding | High | High | Use timestamp-based recalculation + `WidgetsBindingObserver` |
| Schema migration breaks existing data | Medium | Critical | Thorough migration tests with v2 → v3 upgrade path |
| Transaction rollback fails | Low | High | Wrap all saves in `_db.transaction()`, test rollback scenarios |
| Set input state loss on hot reload | Medium | Low | Use `RestorationMixin` or auto-save to ephemeral provider |
| Key collisions in set tracking | Low | Medium | Use composite key: `$exerciseId-$setNumber` (not just `$exerciseIndex-$setNumber`) |

### 12.2 Testing Gaps

**Known Gaps** (acceptable for Phase 11):
1. **Background timer accuracy**: Hard to automate (requires manual verification)
2. **Vibration testing**: Manual device testing only (no emulator support)
3. **Transaction rollback**: Unit test with mock failures, but full integration test challenging
4. **Large set volumes**: Stress test with 50+ sets (performance validation)

**Mitigation**:
- Add manual test checklist (e.g., "Background app for 60s, verify timer recalculates")
- Document known gaps in `11-VERIFICATION.md`

---

## 13. Phase 11 Success Criteria Mapping

**WORK-01**: User can log sets (reps/weight), complete workouts, and persist results with v1.1-equivalent semantics.

✅ **Implementation Requirements**:
- Drift schema v3 with `CompletedWorkouts` and `CompletedSets` tables
- Workout repository with transactional save
- Workout session provider (Riverpod NotifierProvider)
- Set input UI with weight/reps fields
- Parity gate test: Log sets, complete workout, verify DB persistence

**WORK-02**: User can use rest-timer workflow behavior equivalent to v1.1 during active workouts.

✅ **Implementation Requirements**:
- Rest timer provider (Riverpod NotifierProvider)
- Timer UI (modal bottom sheet with countdown)
- Background recalculation (WidgetsBindingObserver)
- Vibration on timer complete
- Parity gate test: Timer starts after set, countdown visible, skip/cancel work

**WORK-03**: User can continue workout logging offline and retain local workout state through reconnect.

✅ **Implementation Requirements**:
- Drift persistence (no Supabase dependency)
- Offline banner (already exists from Phase 10)
- Parity gate test: Complete workout while offline, verify local persistence

---

## 14. Dependencies & Sequencing

### 14.1 Internal Dependencies

**Phase 11 depends on Phase 10**:
- ✅ Drift database initialized (v2 schema)
- ✅ User provider (for userId lookup)
- ✅ Cycle provider (for activeCycleId lookup)
- ✅ Connectivity provider (for offline detection)
- ✅ Program provider (for session metadata)
- ✅ Parity gate infrastructure (FakeConnectivityPlatform, app_helper.dart)

### 14.2 External Dependencies (New Packages)

**Required for Phase 11**:
```yaml
dependencies:
  vibration: ^2.0.0  # Cross-platform vibration
```

**Deferred to Phase 12**:
```yaml
dependencies:
  audioplayers: ^x.x.x          # Sound playback
  flutter_local_notifications: ^x.x.x  # Push notifications
```

### 14.3 Task Sequencing

**Recommended Execution Order**:

1. **Schema Migration** (blocking all else)
   - Add 4 new tables to Drift schema
   - Write migration from v2 → v3
   - Test migration with existing v2 data

2. **Workout Repository** (blocking UI work)
   - Implement `saveWorkout()` transactional save
   - Implement `getWorkoutHistory()`, `getSetsForWorkout()`
   - Unit tests for repository methods

3. **Workout Session Provider** (blocking UI work)
   - Implement `WorkoutSessionNotifier` (Riverpod)
   - Methods: `startSession()`, `logSet()`, `completeWorkout()`
   - Unit tests for provider state transitions

4. **Rest Timer Provider** (blocking timer UI)
   - Implement `RestTimerNotifier` (Riverpod)
   - Background handling with `WidgetsBindingObserver`
   - Vibration on completion
   - Unit tests for timer logic

5. **Workout Session UI** (depends on session provider)
   - Session header (phase, week, session name)
   - Exercise accordion (collapsible)
   - Set input rows (weight, reps)
   - Complete workout button
   - Widget tests for set logging flow

6. **Rest Timer UI** (depends on timer provider)
   - Modal bottom sheet
   - Countdown display (MM:SS)
   - Pause/resume/skip/cancel controls
   - Widget tests for timer controls

7. **Parity Gate Tests** (integration validation)
   - Update `workout_parity_test.dart` (set logging, persistence)
   - Update `offline_parity_test.dart` (workout while offline)
   - Run full parity gate suite

8. **Manual Verification** (final validation)
   - Background timer accuracy (device testing)
   - Vibration triggers (device testing)
   - Large set volumes (stress test)

---

## 15. Open Questions for Planning Phase

### 15.1 Set Input UX

**Question**: Should set input auto-advance to next set after logging?

**v1.1 Behavior**: Manual navigation (user scrolls to next set)

**Options**:
- A) Auto-scroll to next set (smoother UX, but loses context)
- B) Manual scroll (v1.1 parity, preserves context)

**Recommendation**: **B** (manual scroll) — maintains v1.1 parity, less surprising

---

### 15.2 Rest Timer Auto-Start

**Question**: Should rest timer auto-start after set completion?

**v1.1 Behavior**: Optional (user setting: `autoStartEnabled`)

**Options**:
- A) Always auto-start (simpler, fewer settings)
- B) Make it optional (v1.1 parity, more flexible)

**Recommendation**: **A** (always auto-start) for Phase 11, defer settings to Phase 12

---

### 15.3 Workout Cancellation

**Question**: What happens if user navigates away mid-workout (without completing)?

**v1.1 Behavior**: Ephemeral state lost (no auto-save)

**Options**:
- A) Discard workout on navigation (v1.1 parity)
- B) Persist draft workout to Drift (better UX, but more complex)
- C) Show confirmation dialog ("Discard workout?")

**Recommendation**: **C** (confirmation dialog) — prevents accidental data loss, better than v1.1

---

### 15.4 Set Ordering

**Question**: Should sets be numbered per exercise (1, 2, 3) or globally (1, 2, ..., 25)?

**v1.1 Behavior**: Per exercise (each exercise resets to set 1)

**Recommendation**: Per exercise (v1.1 parity) — matches program JSON structure

---

## 16. File Structure Forecast

```
flutter_app/lib/
├── data/
│   ├── database/
│   │   └── app_database.dart         ← UPDATE (add 4 tables, migration to v3)
│   ├── models/
│   │   ├── set_data.dart             ← NEW (CollectedSetData model)
│   │   └── workout_session.dart      ← NEW (WorkoutSessionState model)
│   └── repositories/
│       └── workout_repository.dart   ← NEW (saveWorkout, getWorkoutHistory)
├── features/
│   └── workout/
│       ├── workout_screen.dart       ← UPDATE (session UI, set inputs)
│       ├── set_input_widget.dart     ← NEW (weight/reps input row)
│       ├── rest_timer_sheet.dart     ← NEW (modal bottom sheet)
│       └── exercise_accordion.dart   ← NEW (collapsible exercise list)
└── shared/providers/
    ├── workout_session_provider.dart ← NEW (NotifierProvider)
    └── rest_timer_provider.dart      ← NEW (NotifierProvider)

flutter_app/test/
└── unit/
    ├── repositories/
    │   └── workout_repository_test.dart   ← NEW
    └── providers/
        ├── workout_session_provider_test.dart ← NEW
        └── rest_timer_provider_test.dart      ← NEW

flutter_app/integration_test/
└── parity_gates/
    ├── workout_parity_test.dart      ← UPDATE (add set logging tests)
    └── offline_parity_test.dart      ← UPDATE (add workout-while-offline test)
```

**New Files**: 12
**Updated Files**: 4
**Total LOC Estimate**: ~1,500 lines (schema + repos + providers + UI + tests)

---

## 17. Summary: Critical Path to Planning

### 17.1 What Planner Needs to Know

**Schema Design**:
- 4 new tables (CompletedWorkouts, CompletedSets, OneRepMaxes, PersonalRecords)
- Foreign key relationships (cascade deletes for sets)
- Migration path from v2 → v3

**State Management**:
- Two NotifierProviders (workout session, rest timer)
- Ephemeral state in session provider, persistent state in Drift
- Background timer handling with `WidgetsBindingObserver`

**UI Components**:
- Workout session screen (exercise accordion, set inputs, complete button)
- Rest timer modal (bottom sheet, countdown, controls)
- Set input widget (weight/reps fields, override reason select)

**Testing Strategy**:
- Unit tests: Repository methods, provider state transitions, timer logic
- Widget tests: Set input flow, timer controls
- Integration tests: Parity gates (workout persistence, offline continuity)
- Manual tests: Background timer, vibration, stress testing

### 17.2 Risks to Call Out in Planning

1. **Schema migration complexity**: 4 tables + foreign keys in one migration (test thoroughly)
2. **Timer background accuracy**: Requires `WidgetsBindingObserver` + timestamp recalculation (test on device)
3. **Transaction rollback edge cases**: Ensure Drift transactions roll back on failure
4. **Set input state loss**: Hot reload may clear ephemeral state (document or mitigate)

### 17.3 Decisions for Planner to Make

- [ ] Set input auto-advance (yes/no)?
- [ ] Rest timer auto-start (always/optional)?
- [ ] Workout cancellation (discard/confirm/draft-save)?
- [ ] Rest timer UI (modal/bottom sheet/pill)?
- [ ] Override reason (required/optional)?

### 17.4 Out-of-Scope for Phase 11 (Explicitly Deferred)

- ❌ Supabase sync (Phase 12)
- ❌ Sound notifications (Phase 12)
- ❌ Weight recommendations (Phase 12)
- ❌ PR detection/celebration (Phase 12)
- ❌ Plateau detection (Phase 12)
- ❌ Rest timer settings UI (Phase 12)
- ❌ Workout duration tracking (Phase 12)
- ❌ 1RM auto-updates (Phase 12)

---

## 18. References

### 18.1 v1.1 Source Files

- `src/types/workout.ts` — Data model interfaces
- `src/lib/db/dexie.ts` — Dexie schema
- `src/app/workout/[id]/page.tsx` — Workout session logic
- `src/components/program/workout-session-view.tsx` — Set collection UI
- `src/components/program/set-input-v2.tsx` — Set input widget
- `src/hooks/useRestTimer.ts` — Rest timer hook
- `src/components/rest-timer/` — Timer UI components

### 18.2 Flutter Prior Work

- `flutter_app/lib/data/database/app_database.dart` — Drift schema v2
- `flutter_app/lib/data/repositories/cycle_repository.dart` — Repository pattern
- `flutter_app/lib/shared/providers/` — Riverpod provider examples
- `integration_test/parity_gates/workout_parity_test.dart` — Existing workout test
- `integration_test/parity_gates/offline_parity_test.dart` — Existing offline test

### 18.3 Flutter Packages

- [drift ^2.31.0](https://pub.dev/packages/drift) — SQLite persistence
- [flutter_riverpod ^3.2.1](https://pub.dev/packages/flutter_riverpod) — State management
- [connectivity_plus ^7.0.0](https://pub.dev/packages/connectivity_plus) — Offline detection
- [vibration ^2.0.0](https://pub.dev/packages/vibration) — Vibration API

---

**END OF RESEARCH DOCUMENT**

**Next Step**: Planner uses this research to create `11-PLAN.md` with:
- Task breakdown (schema, repos, providers, UI, tests)
- Dependency graph
- Test plan
- Risk mitigation strategies
- Success criteria validation
