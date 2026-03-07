---
name: test
description: "Run the iOS test suite. Optionally pass a test class name to run a single class."
arguments:
  - name: class
    description: "Optional test class name (e.g., BusinessLogicTests)"
    required: false
---

# Test Runner

Run the Sundee Fundee test suite.

## Instructions

If a `class` argument is provided, run only that test class:

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests/{class} \
  2>&1 | xcpretty
```

Otherwise run all tests:

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:SundeeFundeTests \
  2>&1 | xcpretty
```

After the run, report:
- Total tests passed / failed
- Names of any failing tests
- If failures exist, read the failing test file and diagnose the issue
