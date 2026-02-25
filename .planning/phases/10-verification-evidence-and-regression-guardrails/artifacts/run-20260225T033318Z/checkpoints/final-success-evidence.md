# Checkpoint: Final Success

**Type:** automated-integration-test
**Test file:** `flutter_app/integration_test/critical_access_flow_test.dart`
**Test case:** "login -> dashboard -> programs -> workout start remains stable for canonical account"

## Assertions

```dart
await tester.tap(find.text('START SESSION'));
await tester.pumpAndSettle();

expect(find.textContaining('(W1:D1)'), findsOneWidget);
expect(find.text('Resume onboarding'), findsNothing);
expect(find.textContaining('permission-denied'), findsNothing);
```

## Outcome

PASSED — session entry confirmed with (W1:D1) label visible. No false onboarding prompt. No permission-denied error.

## Notes

Three assertions verify the final state:
1. `(W1:D1)` — confirms session is loaded at Week 1, Day 1 position
2. `Resume onboarding` absent — confirms no false onboarding prompt for returning users (ONB-04)
3. `permission-denied` absent — confirms no Firestore access failures in the flow (ACL-01 through ACL-04)
