---
name: architecture
description: How the major pieces of this project connect and flow. Load when working on system design, integrations, or understanding how components interact.
triggers:
  - "architecture"
  - "system design"
  - "how does X connect to Y"
  - "integration"
  - "flow"
edges:
  - target: context/stack.md
    condition: when specific technology details are needed
  - target: context/decisions.md
    condition: when understanding why the architecture is structured this way
  - target: context/data-layer.md
    condition: when working on persistence, CloudKit, offline sync, or data client switching
  - target: patterns/add-view-feature.md
    condition: when adding a new UI feature with ViewModel and View
last_updated: 2026-04-11
---

# Architecture

## System Overview

User launches app → `SundeeFundeeMain` (@main) creates `AuthViewModel` + `ThemeViewModel` as `@StateObject` →
`AuthViewModel.checkExistingSession()` reads Keychain for stored credentials →
If guest (`userID == "guest_local"`): switches `DataClientFactory.shared.client` to `LocalDataClient` →
If signed-in: keeps default `CloudKitClient(containerIdentifier: "iCloud.com.sundeefundee.app")` →
Auth state drives navigation: `AuthView` → `OnboardingView` → `MainTabView` →
ViewModels receive injected `DataClientProtocol` (default: `DataClientFactory.shared.client`) →
ViewModels call async methods on data client → data client persists to CloudKit or UserDefaults →
`SyncQueue` wraps data client for offline-first: queues failed mutations, replays when connectivity returns →
Domain layer provides pure business logic (cycle calculations, workout generation, analytics) with zero framework dependencies.

## Key Components

- **SundeeFundeeKit** (Swift Package) — all business logic, data layer, and ViewModels. The Xcode app target imports this.
- **DomainLayer/** — pure Swift enums with static methods. Zero dependencies. Covers: cycle adaptation, injury models, benchmark catalog, AI workout types, intelligence (plateau detection, load analysis, schedule reshuffling, substitution ranking), program templates, coach logic, analytics, celebrations.
- **DataClientProtocol** — generic async interface (`fetch<T>`, `save<T>`, `delete`) with `Codable & Sendable` constraints. Three implementations: `CloudKitClient`, `LocalDataClient`, `MockCloudKitClient`.
- **DataClientFactory** — NSLock-based singleton that holds the active `DataClientProtocol`. Switched at auth time.
- **SyncQueue** — actor wrapping any data client. Catches `DataError.networkError`, enqueues `PendingMutation` to UserDefaults, replays via `NetworkMonitor` (NWPathMonitor) when connectivity returns. Max 10 retries.
- **ContentClientProtocol** — fetches exercises, programs, benchmarks from bundled JSON or remote Teenybase backend. `RemoteContentClient` with cache + fallback to `BundledContentProvider`.
- **AuthViewModel** — Apple Sign-In + Keychain session + guest mode. Drives data client switching and navigation state.
- **ViewModels** — all `@MainActor ObservableObject` with `@Published` properties. Constructor dependency injection with defaults from factories.

## External Dependencies

- **CloudKit** (iCloud private database) — persistence for signed-in users. Container: `iCloud.com.sundeefundee.app`. All access via `CloudKitClient` actor only.
- **HealthKit** — menstrual cycle data and health metrics. Accessed via `HealthClientProtocol` / `HealthClientFactory`.
- **Apple Sign-In** (AuthenticationServices) — sole authentication method. Name only provided on first sign-in; `givenName` cached in Keychain and CloudKit.
- **Teenybase backend** (`SundeeFundeeApp/backend/`) — Cloudflare Workers + D1 SQLite serving exercises, programs, and benchmarks as remote content. Accessed via `RemoteContentClient`.
- **ActivityKit** — Live Activity widget for active workout sessions (iOS 16.1+).
- **App Group** (`group.com.sundeefundee.shared`) — shared data between main app and widget extension.

## What Does NOT Exist Here

- No third-party Swift package dependencies — zero external packages in Package.swift
- No Firebase or third-party auth — Apple Sign-In only, session in Keychain
- No subscription paywalls — the app is free, all features available to all users
- No server-side business logic — domain logic is entirely client-side in pure Swift
- No background job processing — SyncQueue replays are triggered by connectivity events, not scheduled tasks
