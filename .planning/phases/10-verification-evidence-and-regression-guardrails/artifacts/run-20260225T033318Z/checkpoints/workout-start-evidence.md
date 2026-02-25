# Checkpoint: Workout Start

**Type:** automated-integration-test
**Test file:** `flutter_app/integration_test/critical_access_flow_test.dart`
**Test case:** "login -> dashboard -> programs -> workout start remains stable for canonical account"

## Assertion

```dart
await tester.tap(_navigationLabel('Workout'));
await tester.pumpAndSettle();
await FirebaseEmulatorTestHarness.checkpoint(
  name: 'workout landing loaded',
  condition: find.text('START SESSION').evaluate().isNotEmpty,
);
```

## Outcome

PASSED — widget tree contains "START SESSION" button after navigating to Workout tab. Session is ready to begin.

## Notes

Provider overrides supply active enrollment at week 1, day 1 with a startable session.
The Workout tab renders the session landing with START SESSION button without access errors.
