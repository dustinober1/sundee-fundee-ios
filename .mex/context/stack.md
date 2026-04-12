---
name: stack
description: Technology stack, library choices, and the reasoning behind them. Load when working with specific technologies or making decisions about libraries and tools.
triggers:
  - "library"
  - "package"
  - "dependency"
  - "which tool"
  - "technology"
edges:
  - target: context/decisions.md
    condition: when the reasoning behind a tech choice is needed
  - target: context/conventions.md
    condition: when understanding how to use a technology in this codebase
  - target: context/setup.md
    condition: when setting up or running the project
last_updated: 2026-04-11
---

# Stack

## Core Technologies

- **Swift 6.0** — primary language, strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY: complete`)
- **SwiftUI** — all UI, iOS 18.0+ deployment target
- **Swift Package Manager** — manages the `SundeeFundeeKit` library package
- **XcodeGen** — generates `SundeeFundee.xcodeproj` from `project.yml`
- **Xcode 16.0+** — required IDE and build system
- **CloudKit** — iCloud private database for signed-in user persistence
- **Teenybase** (Cloudflare Workers + D1) — lightweight backend for remote content (exercises, programs, benchmarks)

## Key Libraries

All Apple frameworks, zero third-party packages:

- **CloudKit** (not Core Data, not Firebase) — async record-based persistence via `CloudKitClient` actor
- **AuthenticationServices** (not Firebase Auth) — Apple Sign-In only, credentials in Keychain
- **HealthKit** — menstrual cycle data via `HealthClientProtocol`
- **StoreKit 2** — subscription infrastructure exists but app is currently free (no paywalls)
- **ActivityKit** — Live Activity for active workout sessions (iOS 16.1+, conditionally compiled)
- **Network** (NWPathMonitor) — connectivity detection for SyncQueue offline replay
- **XCTest + Swift Testing** — dual test frameworks (`import Testing`, `@Test` functions alongside XCTest)

## What We Deliberately Do NOT Use

- No third-party Swift packages — zero external dependencies in Package.swift
- No Firebase — Apple-native stack only (CloudKit, Sign-In, HealthKit)
- No Core Data — CloudKit accessed directly via CKRecord/CKQuery, JSON bridge
- No Combine pipelines — async/await throughout, Combine only for `ObservableObject` conformance
- No `@Observable` macro — all ViewModels use `ObservableObject` with `@Published`
- No class-based inheritance for domain types — pure enums with static methods, structs for data
- No subscription paywalls — do not introduce purchase flows or tier gating

## Version Constraints

- Swift 6.0 strict concurrency — all types crossing concurrency boundaries must be `Sendable`
- iOS 18.0+ minimum deployment — can use latest SwiftUI APIs
- ActivityKit conditionally compiled (`#if canImport(Network)`) for platform support
- XcodeGen (`project.yml`) must be re-run after adding new files or targets to regenerate xcodeproj
