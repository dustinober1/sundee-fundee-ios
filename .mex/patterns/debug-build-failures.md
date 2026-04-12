---
name: debug-build-failures
description: Diagnosing build failures, SourceKit false positives, and Swift 6 concurrency errors. Use when xcodebuild or swift test fails.
triggers:
  - "build failure"
  - "build error"
  - "cannot find type"
  - "Sendable"
  - "concurrency"
  - "SourceKit"
  - "swift test fails"
  - "xcodebuild fails"
edges:
  - target: context/setup.md
    condition: when the issue might be environment-related
  - target: context/conventions.md
    condition: when the fix involves following a coding convention
  - target: context/stack.md
    condition: when the error relates to Swift 6 concurrency or framework constraints
last_updated: 2026-04-11
---

# Debug Build Failures

## Context

This project uses Swift 6 strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`). The most common build failures are concurrency-related. SourceKit in Xcode also produces false positives for cross-module types.

## Triage Steps

### 1. Determine if the error is real

**SourceKit false positive:** "Cannot find type in scope" for types like `KeychainHelper`, `DataClientFactory`, `AppTheme`, etc.
- **Test:** Run `xcodebuild build` from the command line. If it succeeds, the error is a SourceKit false positive.
- **Fix:** Ignore it. Do not add unnecessary imports or type aliases.

**Real build error:** `xcodebuild` fails.
- Continue to step 2.

### 2. Identify the error category

**Sendable conformance:**
- Error: `Type 'X' does not conform to protocol 'Sendable'`
- Fix: Add `Sendable` conformance. For structs with all Sendable properties, just add `: Sendable`. For classes, consider making it an actor or `@unchecked Sendable` with explicit synchronization.

**Main actor isolation:**
- Error: `Call to main actor-isolated... from nonisolated context`
- Fix: Ensure ViewModels are `@MainActor`. Async functions called from ViewModels should use `await`.

**Missing module:**
- Error: `No such module 'SundeeFundeeKit'`
- Fix: Run `xcodegen generate` in `SundeeFundeeApp/` to regenerate the project.

**File not found in project:**
- Error: New files not compiling
- Fix: Re-run `xcodegen generate`. Check that the file is in a directory included by `project.yml`.

### 3. Common swift test failures

**Date-dependent tests:**
- Tests using `Date()` or `Calendar.current` can fail across timezones.
- Fix: Use factory helpers with deterministic dates, e.g., `makeDate(daysAgo: 7)`.

**Floating-point comparison:**
- Fix: Use `XCTAssertEqual(a, b, accuracy: 0.001)` instead of exact equality.

**Async test timeout:**
- Tests with `await` may hang if the data client mock deadlocks.
- Fix: Check that `MockCloudKitClient`'s serial DispatchQueue isn't being re-entered.

## Verify

After fixing:
- [ ] `cd SundeeFundee && swift test` passes
- [ ] `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` succeeds

## Update Scaffold
- [ ] Update `.mex/ROUTER.md` "Current Project State" if what's working/not built has changed
- [ ] Update any `.mex/context/` files that are now out of date
- [ ] If this is a new task type without a pattern, create one in `.mex/patterns/` and add to `INDEX.md`
