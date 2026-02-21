# Phase 10: Onboarding + Program/Cycle Parity - Research

**Researched:** 2026-02-20
**Domain:** Flutter onboarding flows, local data persistence, program catalog, cycle tracking
**Confidence:** HIGH (v1.1 codebase analysis), MEDIUM (Flutter patterns from training knowledge)

---

## Summary

Phase 10 brings user onboarding and program/cycle management to Flutter with full behavioral parity to v1.1. The existing Next.js/React app has a 3-step onboarding wizard (name → experience → goal), local-first Dexie storage, JSON-based program catalog, and workout cycle tracking. Flutter must replicate this exact flow and persistence behavior across web, Android, and iOS.

The standard approach is: (1) Multi-step form using manual state management (setState) rather than PageView for simpler control flow and step validation, (2) Drift database with additional tables for ActiveCycle tracking, (3) JSON asset loading via `rootBundle.loadString()` for program data with in-memory caching, (4) Riverpod StateNotifierProvider for user and cycle state management, (5) `shared_preferences` for the "onboarding completed" flag to control initial routing, and (6) Integration tests that restart the app to verify persistence.

**Key architectural decisions:**
- Manual step state over PageView: Simpler validation, matches v1.1 behavior exactly
- Icon-based selection (Icons.radio_button_checked) not Radio<String>: Deprecated in Flutter 3.32+
- JSON assets committed to `flutter_app/assets/programs/` with pubspec declaration
- `if (mounted)` check before navigation in async gaps (not `if (context.mounted)`)
- Program data is immutable read-only: Users browse and start, but don't edit programs
- ActiveCycle table tracks training program progress separately from menstrual CycleSettings

**Primary recommendation:** Mirror v1.1's Dexie schema in Drift, load program JSON as assets, use Riverpod for user/cycle state, and write integration tests that kill/restart the app to verify persistence.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| drift | ^2.31.0 | SQLite database (already in Phase 9) | Proven cross-platform persistence, replaces Dexie |
| flutter_riverpod | ^3.2.1 | State management (already in Phase 9) | Official pattern for reactive data and DI |
| go_router | ^17.1.0 | Navigation (already in Phase 9) | Declarative routing with redirect logic |
| shared_preferences | ^2.5.4 | Simple key-value storage (already in Phase 9) | For onboarding completion flag |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| freezed | ^2.5.7 | Immutable data classes with JSON serialization | For ProgramV2, Phase, Session, ExerciseV2 models |
| json_serializable | ^6.9.2 | JSON ↔ Dart code generation | With freezed for loading program JSON |
| build_runner | ^2.11.1 | Code generation (already in Phase 9) | Run after defining freezed models |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JSON assets | Hardcode Dart lists | JSON is source of truth; easier to maintain and sync with Next.js app |
| Manual state | PageView | PageView adds complexity for simple linear flow; v1.1 uses manual state |
| freezed | Manual classes | freezed reduces boilerplate for immutable models with JSON; worth the dependency |
| shared_preferences | Drift for flag | Overkill to query DB for simple boolean; shared_preferences is lighter |

### Installation

Already installed from Phase 9:
- drift, drift_flutter, flutter_riverpod, go_router, shared_preferences, build_runner

New dependencies for Phase 10:
```bash
cd flutter_app
flutter pub add freezed_annotation json_annotation
flutter pub add --dev freezed json_serializable
```

---

## Architecture Patterns

### Recommended Project Structure

```
flutter_app/
├── assets/
│   └── programs/                    # JSON files (copy from src/data/programs/)
│       ├── back-squat-complete-cycle.json
│       └── ...
├── lib/
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart    # Add ActiveCycles table
│   │   │   └── tables/
│   │   │       ├── users.dart       # Already exists
│   │   │       └── active_cycles.dart # New
│   │   ├── models/
│   │   │   ├── program.dart         # ProgramV2 freezed model
│   │   │   ├── phase.dart
│   │   │   ├── session.dart
│   │   │   └── exercise_v2.dart
│   │   └── repositories/
│   │       ├── user_repository.dart     # Wrap DB calls
│   │       ├── program_repository.dart  # Load/cache JSON
│   │       └── cycle_repository.dart    # ActiveCycle CRUD
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── onboarding_screen.dart   # Already exists, needs enhancement
│   │   │   └── providers/
│   │   │       └── onboarding_provider.dart # Step state, validation
│   │   ├── programs/
│   │   │   ├── programs_screen.dart     # List view
│   │   │   ├── program_detail_screen.dart
│   │   │   └── providers/
│   │   │       └── program_provider.dart
│   │   └── cycles/
│   │       └── providers/
│   │           └── active_cycle_provider.dart
│   ├── shared/
│   │   └── providers/
│   │       ├── user_provider.dart       # Current user state
│   │       └── onboarding_status_provider.dart # Check shared_preferences
│   └── router/
│       └── router.dart                  # Add redirect logic for onboarding
```

### Pattern 1: Multi-Step Wizard with Manual State

**What:** Use setState to control step index, validate each step before advancing
**When to use:** Linear wizard flows where steps must be completed in order
**Example:**
```dart
// Source: v1.1 onboarding-wizard.tsx pattern + Flutter best practices
class OnboardingScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  String? _selectedExperience;
  String? _selectedGoal;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return _nameController.text.trim().isNotEmpty;
      case 1: return _selectedExperience != null;
      case 2: return _selectedGoal != null;
      default: return false;
    }
  }

  Future<void> _handleNext() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Complete onboarding
      await ref.read(userRepositoryProvider).createUser(
        name: _nameController.text.trim(),
        experienceLevel: _selectedExperience!,
        primaryGoal: _selectedGoal!,
      );
      await ref.read(onboardingStatusProvider.notifier).markComplete();
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildStepContent(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canProceed() ? _handleNext : null,
                  child: Text(_currentStep == 2 ? 'Start Training' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _NameStep(controller: _nameController);
      case 1: return _ExperienceStep(
        selected: _selectedExperience,
        onSelect: (val) => setState(() => _selectedExperience = val),
      );
      case 2: return _GoalStep(
        selected: _selectedGoal,
        onSelect: (val) => setState(() => _selectedGoal = val),
      );
      default: return const SizedBox.shrink();
    }
  }
}
```

### Pattern 2: Icon-Based Selection (Not Radio<String>)

**What:** Use ListTile with Icons for radio-style selection instead of Radio widget
**When to use:** Radio<String> is deprecated in Flutter 3.32+; use Icons for visual selection
**Example:**
```dart
// Source: flutter_app/lib/features/onboarding/onboarding_screen.dart (Phase 9)
// This pattern already used in existing onboarding screen
class _ExperienceStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ExperienceStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Select experience level', style: TextStyle(fontSize: 24)),
        const SizedBox(height: 16),
        ListTile(
          key: const Key('experience-beginner'),
          title: const Text('Beginner (0-1 years)'),
          leading: Icon(
            selected == 'beginner'
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected == 'beginner' ? Colors.blue : Colors.grey,
          ),
          onTap: () => onSelect('beginner'),
        ),
        ListTile(
          key: const Key('experience-intermediate'),
          title: const Text('Intermediate (1-3 years)'),
          leading: Icon(
            selected == 'intermediate'
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected == 'intermediate' ? Colors.blue : Colors.grey,
          ),
          onTap: () => onSelect('intermediate'),
        ),
        ListTile(
          key: const Key('experience-advanced'),
          title: const Text('Advanced (3+ years)'),
          leading: Icon(
            selected == 'advanced'
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected == 'advanced' ? Colors.blue : Colors.grey,
          ),
          onTap: () => onSelect('advanced'),
        ),
      ],
    );
  }
}
```

### Pattern 3: JSON Asset Loading with Caching

**What:** Load JSON assets once at startup, cache in memory via Riverpod provider
**When to use:** Read-only reference data (programs, exercises) that doesn't change per user
**Example:**
```dart
// Source: Flutter rootBundle pattern + Riverpod caching
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class ProgramRepository {
  final Map<String, ProgramV2> _cache = {};
  
  Future<List<ProgramV2>> getAllPrograms() async {
    if (_cache.isEmpty) {
      await _loadPrograms();
    }
    return _cache.values.toList();
  }

  Future<ProgramV2?> getProgramById(String id) async {
    if (_cache.isEmpty) {
      await _loadPrograms();
    }
    return _cache[id];
  }

  Future<void> _loadPrograms() async {
    // Load back-squat-complete-cycle.json
    final jsonString = await rootBundle.loadString(
      'assets/programs/back-squat-complete-cycle.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final program = ProgramV2.fromJson(json);
    _cache[program.id] = program;
    
    // Load other programs as they're added
  }
}

// Riverpod provider
final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository();
});

final programsProvider = FutureProvider<List<ProgramV2>>((ref) async {
  return ref.read(programRepositoryProvider).getAllPrograms();
});
```

### Pattern 4: Onboarding Completion Guard

**What:** Check shared_preferences flag in go_router redirect to enforce onboarding
**When to use:** First-run experience that must complete before accessing main app
**Example:**
```dart
// Source: go_router redirect pattern
final router = GoRouter(
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    
    final isOnboardingRoute = state.uri.path == '/onboarding';
    
    if (!onboardingComplete && !isOnboardingRoute) {
      return '/onboarding';
    }
    
    if (onboardingComplete && isOnboardingRoute) {
      return '/dashboard';
    }
    
    return null; // No redirect
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    // ...
  ],
);

// Set flag after onboarding completion
class OnboardingStatusNotifier extends StateNotifier<bool> {
  OnboardingStatusNotifier() : super(false);

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    state = true;
  }
}

final onboardingStatusProvider = 
    StateNotifierProvider<OnboardingStatusNotifier, bool>((ref) {
  return OnboardingStatusNotifier();
});
```

### Pattern 5: Drift Schema for ActiveCycles

**What:** Add ActiveCycles table to Drift database matching v1.1 schema
**When to use:** Tracking user progress through training programs
**Example:**
```dart
// Source: src/lib/db/dexie.ts ActiveCycle schema
// flutter_app/lib/data/database/tables/active_cycles.dart
import 'package:drift/drift.dart';

class ActiveCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get programId => text()();
  TextColumn get cycleName => text()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get currentWeek => integer()();
  TextColumn get currentSessionId => text().nullable()();
  TextColumn get currentPhase => text().nullable()();
  TextColumn get status => text()(); // 'active', 'completed', 'paused'
}

// Add to app_database.dart:
@DriftDatabase(tables: [Users, ActiveCycles])
class AppDatabase extends _$AppDatabase {
  // ...
  
  @override
  int get schemaVersion => 2; // Increment from Phase 9's version 1
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(activeCycles);
      }
    },
  );
}
```

### Pattern 6: Riverpod User State Provider

**What:** StateNotifierProvider that loads user from DB and exposes current user state
**When to use:** Global user context needed across app (profile, 1RMs, etc.)
**Example:**
```dart
// Source: src/contexts/user-context.tsx pattern
class UserState {
  final User? user;
  final List<OneRepMax> oneRepMaxes;
  
  UserState({this.user, this.oneRepMaxes = const []});
  
  UserState copyWith({User? user, List<OneRepMax>? oneRepMaxes}) {
    return UserState(
      user: user ?? this.user,
      oneRepMaxes: oneRepMaxes ?? this.oneRepMaxes,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final AppDatabase _db;
  
  UserNotifier(this._db) : super(UserState()) {
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    final users = await _db.select(_db.users).get();
    if (users.isNotEmpty) {
      final user = users.first;
      // Load 1RMs if needed
      state = UserState(user: user);
    }
  }
  
  Future<void> updateProfile(UsersCompanion updates) async {
    if (state.user == null) return;
    
    await (_db.update(_db.users)
      ..where((t) => t.id.equals(state.user!.id)))
      .write(updates);
    
    await _loadUser();
  }
  
  Future<void> refresh() async {
    await _loadUser();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final db = ref.watch(databaseProvider);
  return UserNotifier(db);
});
```

### Anti-Patterns to Avoid

- **Using PageView for linear wizards:** Adds complexity; manual state is clearer for step validation
- **Querying DB on every widget rebuild:** Cache user/program data in Riverpod providers
- **Not checking `mounted` before navigation:** Async gaps can cause disposed widget navigation
- **Using Radio<String> widget:** Deprecated in Flutter 3.32+; use Icon-based selection
- **Hardcoding program data in Dart:** JSON assets maintain single source of truth
- **Storing onboarding flag in Drift:** Overkill for simple boolean; use shared_preferences

---

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Immutable models + JSON | Manual toJson/fromJson | freezed + json_serializable | Handles copyWith, equality, JSON serialization; proven pattern |
| Form validation | Custom validation logic | Built-in TextFormField + validator | Flutter's form validation is sufficient for this use case |
| Step progress indicator | Custom widget | Stepper widget or simple Text | Built-in widgets handle common patterns |
| Database migrations | Manual SQL in onUpgrade | Drift's Migrator class | Type-safe migrations, generates schema changes |

**Key insight:** Flutter has mature patterns for forms, navigation, and state management. Use the framework's built-in solutions unless there's a specific need to deviate.

---

## Common Pitfalls

### Pitfall 1: Async Navigation Without `mounted` Check

**What goes wrong:** Navigating after async operation (DB write, etc.) when widget is disposed causes crash
**Why it happens:** User backs out during async operation; context becomes invalid
**How to avoid:** Always check `if (mounted)` before calling `context.go()` or `Navigator`
**Warning signs:** "Don't use BuildContexts across async gaps" lint warning
**Example:**
```dart
// BAD: No mounted check
Future<void> _completeOnboarding() async {
  await saveUser();
  context.go('/dashboard'); // CRASH if widget disposed during saveUser
}

// GOOD: Check mounted
Future<void> _completeOnboarding() async {
  await saveUser();
  if (mounted) {
    context.go('/dashboard');
  }
}
```

### Pitfall 2: Not Declaring JSON Assets in pubspec.yaml

**What goes wrong:** `rootBundle.loadString()` throws "Unable to load asset" error
**Why it happens:** Flutter doesn't include assets unless declared in pubspec.yaml
**How to avoid:** Always declare asset directories in pubspec.yaml flutter section
**Warning signs:** Runtime asset loading error, works in code but fails in release build
**Example:**
```yaml
# pubspec.yaml
flutter:
  uses-material-design: true
  assets:
    - assets/programs/  # Trailing slash includes all files in directory
```

### Pitfall 3: Not Incrementing schemaVersion After Schema Changes

**What goes wrong:** New tables/columns don't exist; app crashes on query
**Why it happens:** Drift caches old schema; `schemaVersion` triggers migration
**How to avoid:** Increment `schemaVersion` every time you change table definitions
**Warning signs:** "No such table" or "No such column" SQL errors
**Example:**
```dart
@DriftDatabase(tables: [Users, ActiveCycles]) // Added ActiveCycles
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // MUST increment from 1 to 2
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(activeCycles); // Create new table
      }
    },
  );
}
```

### Pitfall 4: Forgetting to Run `build_runner` After Schema Changes

**What goes wrong:** Compilation errors, missing generated files (*.g.dart)
**Why it happens:** Drift generates code from table definitions; must regenerate after changes
**How to avoid:** Run `flutter pub run build_runner build` after every schema change
**Warning signs:** Import errors for generated files, "undefined class _$AppDatabase"
**Example:**
```bash
# After adding ActiveCycles table:
cd flutter_app
flutter pub run build_runner build --delete-conflicting-outputs
```

### Pitfall 5: Testing Persistence Without App Restart

**What goes wrong:** Tests pass but data doesn't survive real app restart
**Why it happens:** In-memory cache masking persistence failures
**How to avoid:** Write integration tests that explicitly restart the app using `flutter_driver`
**Warning signs:** Data available in same session but lost after device restart
**Example:**
```dart
// integration_test/onboarding_persistence_test.dart
testWidgets('Profile data persists after app restart', (tester) async {
  // First run: Complete onboarding
  await tester.pumpWidget(const MyApp());
  await tester.enterText(find.byKey(Key('name-input')), 'Test User');
  await tester.tap(find.byKey(Key('complete-button')));
  await tester.pumpAndSettle();
  
  // Restart app (simulates device restart)
  await tester.restartAndRestore();
  
  // Verify user data still exists
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getBool('onboarding_complete'), true);
  
  // Verify DB has user
  final db = AppDatabase.defaults();
  final users = await db.select(db.users).get();
  expect(users, isNotEmpty);
  expect(users.first.name, 'Test User');
});
```

### Pitfall 6: Not Handling Null User State

**What goes wrong:** Null pointer exceptions when accessing `user.name` before user loaded
**Why it happens:** Riverpod provider loads asynchronously; initial state is null
**How to avoid:** Always null-check or use AsyncValue pattern for initial load
**Warning signs:** "Null check operator used on null value" in user-dependent widgets
**Example:**
```dart
// BAD: Assumes user is loaded
final user = ref.watch(userProvider).user;
Text(user.name); // CRASH if user is null

// GOOD: Handle null case
final userState = ref.watch(userProvider);
if (userState.user == null) {
  return const CircularProgressIndicator();
}
Text(userState.user!.name);
```

---

## Code Examples

Verified patterns from v1.1 and Flutter best practices:

### Complete Onboarding Flow
```dart
// Source: src/app/onboarding/page.tsx + Flutter patterns
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  String? _selectedExperience;
  String? _selectedGoal;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return _nameController.text.trim().isNotEmpty;
      case 1: return _selectedExperience != null;
      case 2: return _selectedGoal != null;
      default: return false;
    }
  }

  Future<void> _handleNext() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Complete onboarding - matches v1.1 behavior
      final db = ref.read(databaseProvider);
      await db.into(db.users).insert(
        UsersCompanion.insert(
          name: _nameController.text.trim(),
          experienceLevel: _selectedExperience!,
          goal: _selectedGoal!,
        ),
      );
      
      // Set completion flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('onboarding-screen'),
      appBar: AppBar(
        title: const Text('Welcome to Sundee Fundee'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              Text(
                'Step ${_currentStep + 1} of 3',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              
              // Step content
              Expanded(child: _buildStepContent()),
              
              // Navigation buttons
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('onboarding-back-button'),
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('onboarding-next-button'),
                      onPressed: _canProceed() ? _handleNext : null,
                      child: Text(
                        _currentStep == 2 ? 'Start Training' : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's your name?",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('onboarding-name-input'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}), // Trigger validation
            ),
          ],
        );
      
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training experience',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              key: const Key('experience-beginner'),
              title: const Text('Beginner'),
              subtitle: const Text('0-1 years'),
              leading: Icon(
                _selectedExperience == 'beginner'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => setState(() => _selectedExperience = 'beginner'),
            ),
            ListTile(
              key: const Key('experience-intermediate'),
              title: const Text('Intermediate'),
              subtitle: const Text('1-3 years'),
              leading: Icon(
                _selectedExperience == 'intermediate'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => setState(() => _selectedExperience = 'intermediate'),
            ),
            ListTile(
              key: const Key('experience-advanced'),
              title: const Text('Advanced'),
              subtitle: const Text('3+ years'),
              leading: Icon(
                _selectedExperience == 'advanced'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => setState(() => _selectedExperience = 'advanced'),
            ),
          ],
        );
      
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your goals',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              key: const Key('goal-strength'),
              title: const Text('Build Strength'),
              leading: Icon(
                _selectedGoal == 'strength'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => setState(() => _selectedGoal = 'strength'),
            ),
            ListTile(
              key: const Key('goal-hypertrophy'),
              title: const Text('Muscle Growth'),
              leading: Icon(
                _selectedGoal == 'hypertrophy'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => setState(() => _selectedGoal = 'hypertrophy'),
            ),
            ListTile(
              key: const Key('goal-explosiveness'),
              title: const Text('Power & Speed'),
              leading: Icon(
                _selectedGoal == 'explosiveness'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => setState(() => _selectedGoal = 'explosiveness'),
            ),
          ],
        );
      
      default:
        return const SizedBox.shrink();
    }
  }
}
```

### Program Catalog List View
```dart
// Source: src/app/programs/page.tsx pattern
class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Programs')),
      body: programsAsync.when(
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(
              child: Text('No programs available'),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () => context.go('/programs/${program.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                program.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Chip(
                              label: Text(program.difficulty),
                              backgroundColor: _difficultyColor(program.difficulty),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          program.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${program.durationWeeks} weeks · ${program.sessionsPerWeek} sessions/week',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading programs: $error'),
        ),
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return Colors.green.shade100;
      case 'intermediate': return Colors.orange.shade100;
      case 'advanced': return Colors.red.shade100;
      default: return Colors.grey.shade100;
    }
  }
}
```

### Start Training Cycle
```dart
// Source: v1.1 ActiveCycle creation pattern
class CycleRepository {
  final AppDatabase _db;

  CycleRepository(this._db);

  Future<int> startCycle({
    required int userId,
    required String programId,
    required String cycleName,
  }) async {
    final companion = ActiveCyclesCompanion.insert(
      userId: userId,
      programId: programId,
      cycleName: cycleName,
      startDate: DateTime.now(),
      currentWeek: 1,
      status: const Value('active'),
    );

    return await _db.into(_db.activeCycles).insert(companion);
  }

  Future<ActiveCycle?> getActiveCycleByUser(int userId) async {
    final query = _db.select(_db.activeCycles)
      ..where((t) => t.userId.equals(userId) & t.status.equals('active'));
    
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  Future<void> updateCycleProgress({
    required int cycleId,
    required int week,
    String? sessionId,
  }) async {
    final update = ActiveCyclesCompanion(
      currentWeek: Value(week),
      currentSessionId: Value(sessionId),
    );

    await (_db.update(_db.activeCycles)
      ..where((t) => t.id.equals(cycleId)))
      .write(update);
  }
}

// Riverpod provider
final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CycleRepository(db);
});

final activeCycleProvider = FutureProvider.family<ActiveCycle?, int>((ref, userId) async {
  return ref.read(cycleRepositoryProvider).getActiveCycleByUser(userId);
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Radio<String> widget | Icon-based selection | Flutter 3.32+ | Radio<String> deprecated; use Icons.radio_button_checked/unchecked |
| context.mounted | if (mounted) | Flutter 3.7+ | Both work; `mounted` is ConsumerState property, clearer |
| Manual JSON parsing | freezed + json_serializable | Current standard | Reduces boilerplate, type-safe serialization |
| PageController for wizards | Manual state with setState | Current best practice | Simpler for linear validation flows |

**Deprecated/outdated:**
- Radio<String>: Use Icon-based selection instead (Flutter 3.32+)
- context.go() without mounted check: Causes crashes in async scenarios
- Storing simple flags in SQLite: Use shared_preferences for booleans

---

## Open Questions

Things that couldn't be fully resolved:

1. **freezed vs Manual Models**
   - What we know: freezed adds ~1MB to app size, generates significant code
   - What's unclear: Is the productivity gain worth the dependency for this project scale?
   - Recommendation: Start with freezed for ProgramV2 models; they're complex enough to justify it

2. **Program JSON Migration Strategy**
   - What we know: Next.js app has programs in src/data/programs/*.json
   - What's unclear: Should these be symlinked, copied, or generate Dart from single source?
   - Recommendation: Copy JSON to flutter_app/assets/programs/ for now; investigate code generation in later phase if programs grow significantly

3. **Integration Test Restart Mechanism**
   - What we know: Need to test persistence across app restarts
   - What's unclear: Best way to restart app in integration_test without flutter_driver
   - Recommendation: Use `tester.restartAndRestore()` if available in flutter_test 3.7+; otherwise use patrol for native restart

4. **Cycle Completion Logic**
   - What we know: v1.1 has ActiveCycle table with status field
   - What's unclear: Exact logic for when a cycle transitions from 'active' to 'completed'
   - Recommendation: Implement in Phase 11 (Workout Session); Phase 10 just needs cycle creation

---

## Sources

### Primary (HIGH confidence)
- v1.1 Next.js codebase analysis:
  - src/contexts/user-context.tsx (User state management pattern)
  - src/app/onboarding/page.tsx (3-step wizard implementation)
  - src/lib/db/dexie.ts (Database schema: Users, ActiveCycles, OneRepMaxes)
  - src/data/programs/back-squat-complete-cycle.json (ProgramV2 structure)
  - src/types/*.ts (TypeScript type definitions)
- Phase 9 Flutter foundation:
  - flutter_app/lib/data/database/app_database.dart (Drift setup)
  - flutter_app/lib/features/onboarding/onboarding_screen.dart (Basic wizard)
  - flutter_app/pubspec.yaml (Dependency versions)
  - .planning/phases/09-cross-platform-foundation-parity-gates/09-RESEARCH.md

### Secondary (MEDIUM confidence)
- Flutter documentation patterns (from training knowledge):
  - Multi-step forms with setState
  - Icon-based selection (Radio<String> deprecation)
  - rootBundle.loadString() for JSON assets
  - Riverpod StateNotifierProvider patterns
  - Drift database migrations with Migrator
  - go_router redirect logic for onboarding guards

### Tertiary (LOW confidence - needs verification in implementation)
- `tester.restartAndRestore()` API for integration test restarts (verify in flutter_test 3.7+)
- freezed package overhead (~1MB claim - verify with actual build size comparison)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages already in use from Phase 9 or well-documented
- Architecture: HIGH - v1.1 codebase provides concrete reference implementation
- Pitfalls: HIGH - Common Flutter gotchas from framework knowledge and STATE.md decisions

**Research date:** 2026-02-20
**Valid until:** 2026-03-22 (30 days - stable domain)

**Key dependencies on Phase 9:**
- Drift database with Users table
- Riverpod providers for database access
- go_router configuration
- shared_preferences for flags
- Basic onboarding screen structure

**Enables Phase 11:**
- User profile available for workout logging
- Active cycles ready to track workout sessions
- Program catalog browsable for session selection
