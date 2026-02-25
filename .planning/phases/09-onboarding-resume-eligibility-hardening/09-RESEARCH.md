# Phase 09: Onboarding Resume Eligibility Hardening - Research

**Researched:** 2026-02-25  
**Domain:** Auth bootstrap onboarding-eligibility decisions for current + legacy user profiles  
**Confidence:** HIGH

## Summary

Phase 09 should be implemented as a deterministic onboarding-eligibility decision pipeline inside auth bootstrap, not as additional UI branching. Current behavior already normalizes legacy profile shapes and supports resume/restart flows, but it still has a contradiction: users with required onboarding data (`name`) and `onboardingComplete == false` are routed to `resumeOnboarding` instead of being treated as complete and auto-healed.

The required Phase 09 behavior is achievable without new product dependencies. The existing Flutter + Riverpod + Firebase stack is sufficient if we add one explicit eligibility evaluator, bounded legacy evidence probes (workout/max history), non-blocking auto-heal writes, and fallback behavior that defaults to "Resume Onboarding" on profile bootstrap timeout/error.

**Primary recommendation:** replace ad-hoc status branching with a single `OnboardingEligibilityEvaluator` used by `AuthRepository.authStateChanges()`, with explicit legacy-history rules and timeout-safe fallback semantics.

## Locked Context From 09-CONTEXT.md

These decisions are fixed and this research assumes them as requirements:
- Required onboarding field for completeness is `name`.
- `onboardingComplete == true` always means complete.
- If required fields exist while `onboardingComplete == false`, treat as complete and auto-heal flag to `true`.
- If `name` is missing + completed workout history exists, show "Resume Onboarding."
- If `name` is missing + max-only history exists, bypass resume and treat as complete.
- If profile bootstrap errors or times out, default to showing "Resume Onboarding."
- Once onboarding completeness is satisfied, injury completion should gate before resume onboarding.
- Restart onboarding must also clear injury profiles and injury disclaimer acknowledgments.

## Current Codebase Findings

1. `UserModel.onboardingCompleteComputed` treats `onboardingComplete || namePresent` as complete (`flutter_app/lib/domain/models/user_model.dart`), but `AuthRepository` then forces `resumeOnboarding` whenever `onboardingComplete == false && namePresent` (`flutter_app/lib/features/auth/data/auth_repository.dart`), causing false resume prompts.
2. `AuthRepository.authStateChanges()` has no explicit timeout/error fallback to `resumeOnboarding`; upstream errors can bubble to router fallback (`unauthenticated`) instead of the required resume-default behavior.
3. No legacy-history probe exists in bootstrap for `workouts` vs max-history evidence (`maxLifts`, `oneRepMaxes`) before deciding onboarding status.
4. `restartOnboarding()` resets onboarding fields but does not clear `injuryProfiles` or `acknowledgedInjuryDisclaimerIds` (`flutter_app/lib/features/auth/data/auth_repository.dart`).
5. Resume decision UI exists and is test-covered (`flutter_app/lib/features/auth/presentation/onboarding_screen.dart`, `flutter_app/test/features/auth/presentation/onboarding_screen_test.dart`), so Phase 09 can focus on upstream status correctness.
6. Auth tests currently cover guest mode and resume screen rendering but do not cover contradictory legacy states or history-based eligibility decisions.

## Verification Baseline (Current)

Executed and passing on 2026-02-25:
- `cd flutter_app && flutter test test/features/auth/data/auth_repository_test.dart test/features/auth/presentation/onboarding_screen_test.dart test/features/auth/presentation/router_redirect_test.dart -r compact`
- `cd flutter_app && flutter test test/domain/models/user_model_test.dart test/features/profile/data/profile_repository_test.dart -r compact`

Coverage gap: no tests currently assert Phase 09 legacy heuristics (workout-history vs max-only-history) or timeout/error fallback to resume onboarding.

## Standard Stack

No new external libraries are required.

### Core
| Library/Tool | Version | Purpose | Why standard for this phase |
|---|---|---|---|
| `firebase_auth` | 6.1.4 | Auth identity/session stream | Existing session root for bootstrap gating |
| `cloud_firestore` | 6.1.2 | Profile + history evidence reads and profile heal writes | Existing persistence boundary |
| `flutter_riverpod` | 3.2.1 | App-wide auth/profile derived state | Existing state orchestration pattern |
| `go_router` | 17.1.0 | Route redirects from auth status | Existing route gate entrypoint |
| `rxdart` | 0.28.0 | Stream composition (`combineLatest`, `switchMap`) | Already used in `AuthRepository` |
| Firestore Security Rules | v2 | Owner-safe profile write contract | Ensures auto-heal/reset writes remain constrained |

### Supporting
| Library/Tool | Version | Purpose | When to use |
|---|---|---|---|
| `shared_preferences` | 2.5.4 | Optional ephemeral "one-time recovery notice shown" flag for current app run | If UI needs dedupe after re-renders/rebuilds |
| `fake_cloud_firestore` | 4.0.1 | Fast unit tests for eligibility probes | Required for deterministic Phase 09 tests |
| Firebase Emulator Suite | existing | Rules + behavior validation for profile write/reset paths | Run before deploy when rules or bootstrap writes change |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|---|---|---|
| Aggregate/limited history probes | Streaming whole history collections | Higher latency/read cost and more routing jitter risk |
| Repository-level fallback to resume on bootstrap failure | Router-level fallback remap | Router lacks enough domain context for history-based decisioning |

## Architecture Patterns

### Pattern 1: Central Onboarding Eligibility Evaluator
- Create one evaluator (`OnboardingEligibilityEvaluator`) that returns a typed decision (`authenticated`, `resumeOnboarding`, `needsOnboarding`, `needsInjuryProfile`) plus optional recovery metadata.
- Keep all completeness heuristics in this evaluator; UI and router only consume the resulting status.
- Use explicit reason codes for observability and tests (`name_missing_with_workouts`, `name_missing_max_only`, `flag_healed`).

### Pattern 2: Bounded Legacy Evidence Probe (Workout vs Max History)
- When `name` is missing and `onboardingComplete == false`, run one-shot evidence probes:
  - workout evidence count (`users/{uid}/workouts`)
  - max evidence count (`users/{uid}/maxLifts` and `users/{uid}/oneRepMaxes`)
- Run probes in parallel and under a timeout.
- Decision mapping:
  - workouts > 0 => `resumeOnboarding`
  - workouts == 0 and max evidence > 0 => treat complete + auto-heal
  - no evidence => `resumeOnboarding`
  - probe timeout/error => `resumeOnboarding`

### Pattern 3: Write-Behind Auto-Heal for Contradictory Complete States
- If decision is "complete but `onboardingComplete` false", issue non-blocking merge write:
  - `onboardingComplete: true`
  - `profileUpdatedAt: serverTimestamp`
  - `updatedAt: serverTimestamp`
- Do not block routing on write success.
- Keep behavior idempotent and safe under repeated sign-ins.

### Pattern 4: One-Time Recovery Notice Event (No Persistent Settings Marker)
- When bypassing resume through legacy recovery heuristics, emit a one-time bootstrap event consumed by Home/Dashboard shell for a single in-session notice.
- Keep this event ephemeral; do not add permanent profile marker fields.
- Use existing snackbar/banner patterns to surface message.

### Pattern 5: Atomic Restart Reset Including Injury Data
- Update `restartOnboarding()` to reset onboarding + injury-related profile state together:
  - clear `name`, `displayName`, onboarding fields
  - clear `injuryProfiles`
  - clear `acknowledgedInjuryDisclaimerIds`
- Use one Firestore write batch/merge update contract to avoid partial resets.

### Pattern 6: Timeout/Error Fallback Inside Auth Bootstrap
- Catch profile stream/probe errors at repository level and map to `resumeOnboarding` when user is authenticated but profile eligibility cannot be resolved reliably.
- Add explicit timeout around eligibility probe to satisfy the phase requirement of conservative resume fallback.
- Avoid routing oscillation by emitting stable fallback status until next successful profile evaluation.

### Pattern 7: Deterministic Gate Order (Completeness Before Injury Gating)
- Evaluate onboarding completeness first.
- If complete, evaluate injury completion requirement next.
- Only show `resumeOnboarding` when onboarding is incomplete by the Phase 09 rules.

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| Legacy-history inference | Full history hydration pipeline at login | Aggregate count or `limit(1)` evidence probes | Lower latency and lower read amplification |
| Onboarding truth in UI widgets | Per-screen ad-hoc completeness checks | Repository-level evaluator with typed output | Prevents inconsistent routing decisions |
| Blocking reconciliation | "Wait for heal write before route" flow | Non-blocking write-behind auto-heal | Removes login friction and avoids deadlocks |
| Permanent recovery flags | New persistent profile setting for notice state | Ephemeral in-session recovery event | Matches requirement: no persistent marker |
| Timeout handling in router | Router-only workaround logic | Repository-level timeout fallback | Router should not own domain decision policy |

## Common Pitfalls

### Pitfall 1: Double-meaning completeness logic
- **What goes wrong:** One layer treats user as complete (`name` present), another forces resume (`onboardingComplete == false`).
- **Why it happens:** Split logic across model getter and repository branching.
- **How to avoid:** Consolidate into one evaluator and remove contradictory branch paths.

### Pitfall 2: Missing differentiation between workout-history and max-only legacy records
- **What goes wrong:** Users get false onboarding prompts because all missing-name profiles are treated alike.
- **Why it happens:** No legacy evidence probe.
- **How to avoid:** Probe workouts and max collections separately and apply fixed mapping rules.

### Pitfall 3: Bootstrap race/timeout route flapping
- **What goes wrong:** App can bounce across auth/onboarding states under slow profile reads.
- **Why it happens:** No bounded decision deadline and fallback semantics.
- **How to avoid:** Apply timeout + stable fallback status (`resumeOnboarding`) until successful reevaluation.

### Pitfall 4: Restart reset leaves stale injury state
- **What goes wrong:** Restart onboarding but old injury profiles/disclaimer acknowledgments persist.
- **Why it happens:** Partial reset payload.
- **How to avoid:** Reset onboarding and injury-related fields together in a single write contract.

### Pitfall 5: Missing regression tests for contradictory legacy states
- **What goes wrong:** Future refactors reintroduce false resume prompts.
- **Why it happens:** Current tests don't cover the failing state matrix.
- **How to avoid:** Add matrix tests for complete/partial + history evidence + timeout/error fallback.

## Code Examples

### 1) Eligibility evaluator contract
```dart
enum OnboardingDecision {
  needsOnboarding,
  resumeOnboarding,
  needsInjuryProfile,
  authenticated,
}

class OnboardingEligibilityResult {
  const OnboardingEligibilityResult({
    required this.decision,
    this.shouldAutoHeal = false,
    this.recoveryNotice = false,
    this.reason = '',
  });

  final OnboardingDecision decision;
  final bool shouldAutoHeal;
  final bool recoveryNotice;
  final String reason;
}
```

### 2) Legacy evidence probe with aggregate counts and timeout
```dart
Future<(int workouts, int maxes)> loadLegacyEvidence(String userId) async {
  final CollectionReference<Map<String, dynamic>> user =
      _usersCollection.doc(userId);

  Future<int> count(CollectionReference<Map<String, dynamic>> col) async {
    final AggregateQuerySnapshot snap =
        await col.count().get(const AggregateSource.serverAndCache);
    return snap.count;
  }

  return Future.wait<int>(<Future<int>>[
    count(user.collection('workouts')),
    Future.wait<int>(<Future<int>>[
      count(user.collection('maxLifts')),
      count(user.collection('oneRepMaxes')),
    ]).then((List<int> values) => values.fold(0, (a, b) => a + b)),
  ]).then((List<int> values) => (values[0], values[1]))
    .timeout(const Duration(seconds: 3));
}
```

### 3) Non-blocking auto-heal after complete decision
```dart
void scheduleOnboardingAutoHeal(String userId) {
  unawaited(
    _usersCollection.doc(userId).set(<String, dynamic>{
      'onboardingComplete': true,
      'profileUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((Object _) {}),
  );
}
```

### 4) Restart onboarding reset payload (including injury state)
```dart
Future<void> restartOnboarding() async {
  await _usersCollection.doc(userId).set(<String, dynamic>{
    'displayName': '',
    'name': '',
    'genderRaw': Gender.preferNotToSay.name,
    'cycleTrackingEnabled': false,
    'onboardingComplete': false,
    'injuryProfiles': <Map<String, dynamic>>[],
    'acknowledgedInjuryDisclaimerIds': <String, dynamic>{},
    'profileUpdatedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

## ONB Traceability (Phase 09)

| Requirement | Current gap | Research-backed direction |
|---|---|---|
| ONB-04 complete users skip resume | Contradictory branch forces resume when `name` exists but flag false | Evaluator treats as complete + auto-heal |
| ONB-05 resume only for incomplete required fields | No history-based differentiation for missing-name legacy users | Add bounded workout/max evidence probe + explicit fallback mapping |

## Open Questions

1. Should max-history evidence use both `maxLifts` and `oneRepMaxes`, or just one canonical collection?
2. What timeout value should classify bootstrap as "timed out" (context leaves value to implementation discretion)?
3. Where should the one-time recovery notice be surfaced first (dashboard banner vs snackbar) for least disruption?

## Sources

### Primary codebase sources
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/09-onboarding-resume-eligibility-hardening/09-CONTEXT.md`
- `flutter_app/lib/domain/models/user_model.dart`
- `flutter_app/lib/features/auth/data/auth_repository.dart`
- `flutter_app/lib/features/auth/presentation/onboarding_screen.dart`
- `flutter_app/lib/features/auth/domain/auth_state.dart`
- `flutter_app/lib/app/router.dart`
- `flutter_app/lib/features/profile/data/profile_repository.dart`
- `flutter_app/lib/features/repositories/data/firestore_repositories.dart`
- `flutter_app/test/features/auth/data/auth_repository_test.dart`
- `flutter_app/test/features/auth/presentation/onboarding_screen_test.dart`
- `flutter_app/test/features/auth/presentation/router_redirect_test.dart`
- `flutter_app/test/domain/models/user_model_test.dart`
- `flutter_app/test/features/profile/data/profile_repository_test.dart`

### Official documentation (validated)
- Firestore security rules query semantics ("rules are not filters"): https://firebase.google.com/docs/firestore/security/rules-query
- Firestore transactions and batched writes (batched writes execute offline): https://firebase.google.com/docs/firestore/manage-data/transactions
- Firestore aggregation queries (`count()`): https://firebase.google.com/docs/firestore/query-data/aggregation-queries
- Firestore listeners and metadata (`includeMetadataChanges`, cache/pending-write metadata): https://firebase.google.com/docs/firestore/query-data/listen
- FlutterFire `Query` API (`count`, aggregate source options): https://pub.dev/documentation/cloud_firestore/latest/cloud_firestore/Query-class.html
- `go_router` redirection model (`FutureOr<String?> redirect`): https://pub.dev/documentation/go_router/latest/topics/Redirection-topic.html

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (current project dependency lock + stable Firebase/Flutter patterns)
- Architecture patterns: HIGH (directly grounded in existing code paths and locked phase decisions)
- Pitfalls/regression risks: HIGH (verified by current branching logic and test coverage gaps)

**Research date:** 2026-02-25  
**Valid until:** 2026-03-27 (refresh if auth bootstrap logic or Firestore profile schema changes)
