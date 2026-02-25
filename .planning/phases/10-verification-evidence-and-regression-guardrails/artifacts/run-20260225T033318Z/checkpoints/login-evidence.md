# Checkpoint: Login

**Type:** automated-integration-test
**Test file:** `flutter_app/integration_test/critical_access_flow_test.dart`
**Test case:** "login -> dashboard -> programs -> workout start remains stable for canonical account"

## Assertion

```dart
authController.add(
  const AuthSession(status: AuthStatus.unauthenticated),
);
await tester.pumpAndSettle();
await FirebaseEmulatorTestHarness.checkpoint(
  name: 'login screen',
  condition: find.text('Sign In').evaluate().isNotEmpty,
);
```

## Outcome

PASSED — widget tree renders Sign In screen. No permission-denied text present.

## Notes

Provider overrides supply unauthenticated session initially. The app routes to the auth screen
and renders the Sign In button. The `unauthenticated guard` companion test separately verifies
that unauthenticated users cannot reach /, /workout, or /onboarding routes.
