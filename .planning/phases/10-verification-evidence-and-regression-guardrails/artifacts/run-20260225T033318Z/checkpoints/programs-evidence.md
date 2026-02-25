# Checkpoint: Programs

**Type:** automated-integration-test
**Test file:** `flutter_app/integration_test/critical_access_flow_test.dart`
**Test case:** "login -> dashboard -> programs -> workout start remains stable for canonical account"

## Assertion

```dart
await tester.tap(_navigationLabel('Programs'));
await tester.pumpAndSettle();
await FirebaseEmulatorTestHarness.checkpoint(
  name: 'programs loaded',
  condition: find.text(program.name).evaluate().isNotEmpty,
);
```

## Outcome

PASSED — widget tree contains program name ("Canonical Verification Program") after navigating to Programs tab. No permission-denied surface rendered.

## Notes

Provider overrides supply program list via `programsProvider` and active enrollment via
`enrollmentLifecycleStateProvider`. The Programs tab renders without Firestore access errors.
`program.name` resolves to "Canonical Verification Program".
