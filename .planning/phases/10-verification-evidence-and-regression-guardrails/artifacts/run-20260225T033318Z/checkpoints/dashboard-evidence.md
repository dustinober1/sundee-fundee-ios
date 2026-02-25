# Checkpoint: Dashboard

**Type:** automated-integration-test
**Test file:** `flutter_app/integration_test/critical_access_flow_test.dart`
**Test case:** "login -> dashboard -> programs -> workout start remains stable for canonical account"

## Assertion

```dart
authController.add(
  const AuthSession(status: AuthStatus.authenticated),
);
await tester.pumpAndSettle();
await FirebaseEmulatorTestHarness.checkpoint(
  name: 'dashboard loaded',
  condition: find.text('Next Workout').evaluate().isNotEmpty,
);
```

## Outcome

PASSED — widget tree contains "Next Workout" card after authentication. No "Resume onboarding" prompt observed.

## Notes

Provider overrides supply authenticated auth session and active enrollment with program data.
Dashboard loads without Firestore access errors and renders the Next Workout card from the
overridden enrollment lifecycle state.
