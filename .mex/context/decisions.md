---
name: decisions
description: Key architectural and technical decisions with reasoning. Load when making design choices or understanding why something is built a certain way.
triggers:
  - "why do we"
  - "why is it"
  - "decision"
  - "alternative"
  - "we chose"
edges:
  - target: context/architecture.md
    condition: when a decision relates to system structure
  - target: context/stack.md
    condition: when a decision relates to technology choice
  - target: context/data-layer.md
    condition: when a decision relates to persistence or data client architecture
  - target: context/conventions.md
    condition: when a decision shaped a coding convention
last_updated: 2026-04-11
---

# Decisions

## Decision Log

### Zero third-party Swift dependencies
**Date:** Project inception
**Status:** Active
**Decision:** The Swift package has zero external dependencies — all Apple-native frameworks only.
**Reasoning:** Eliminates supply chain risk, version conflicts, and build complexity. Apple frameworks are stable and sufficient for this app's needs.
**Alternatives considered:** Alamofire for networking (rejected — URLSession is sufficient), Realm for persistence (rejected — CloudKit provides native sync), SwiftyJSON (rejected — Codable is standard).
**Consequences:** More boilerplate for some operations (e.g., JSON↔CKRecord bridging), but full control and no dependency management overhead.

### App is free with no paywalls
**Date:** 2026-03-12 (based on commit c789f188)
**Status:** Active
**Decision:** All features are available to all users with no in-app purchases or subscription gating.
**Reasoning:** Removed subscription tiers to simplify the app and focus on user experience over monetization.
**Alternatives considered:** Three-tier subscription model (Free/Plus/Premium) was originally planned and partially built (StoreKit 2 infrastructure exists). Rejected to reduce complexity and App Store review friction.
**Consequences:** StoreKit 2 subscription code exists but is inactive. Do not introduce paywalls, purchase flows, or tier gating. The README still references subscription tiers — this is outdated documentation.

### Protocol-based data layer with factory switching
**Date:** Project inception
**Status:** Active
**Decision:** All persistence goes through `DataClientProtocol`. Active client is swapped at auth time via `DataClientFactory` singleton.
**Reasoning:** Guest users store data locally (UserDefaults via `LocalDataClient`), signed-in users use CloudKit (`CloudKitClient`). The factory pattern lets ViewModels be agnostic to the backing store.
**Alternatives considered:** Single CloudKit client with offline cache (rejected — guest mode needs to work without any Apple ID), Core Data + CloudKit (rejected — too heavyweight for the data model).
**Consequences:** ViewModels must always use `DataClientFactory.shared.client` as default, never instantiate a specific client directly.

### ObservableObject over @Observable macro
**Date:** Project inception
**Status:** Active
**Decision:** All ViewModels use `@MainActor ObservableObject` with `@Published`, not the `@Observable` macro.
**Reasoning:** Established pattern before @Observable was available. Consistent across the entire codebase.
**Alternatives considered:** @Observable macro (would reduce boilerplate but requires migrating all ViewModels simultaneously).
**Consequences:** All ViewModels follow the same pattern: `@MainActor public class FooViewModel: ObservableObject` with `@Published` properties. Do not mix patterns — either all migrate or none do.

### Domain logic as pure enums with static methods
**Date:** Project inception
**Status:** Active
**Decision:** Domain layer uses enums with static methods, not classes or structs with instance state.
**Reasoning:** Enforces purity — enums with no cases cannot be instantiated, so all functions are guaranteed stateless. Makes testing trivial: call static method, assert on return value.
**Alternatives considered:** Service classes with dependency injection (rejected — unnecessary complexity for pure functions), free functions (rejected — enums provide better namespace grouping).
**Consequences:** Domain types like `WeeklyLoadAnalyzer`, `PlateauDetector`, `CyclePhaseHelper` are all enums. New domain logic must follow this pattern.

### Apple Sign-In only, name cached in Keychain
**Date:** Project inception
**Status:** Active
**Decision:** Authentication uses Apple Sign-In exclusively. User's `givenName` is cached to Keychain and CloudKit because Apple only provides the full name on first sign-in.
**Reasoning:** Apple Sign-In is the simplest auth flow for iOS-only apps. No backend auth server needed.
**Alternatives considered:** Firebase Auth (rejected — adds third-party dependency and server component), no auth (rejected — CloudKit requires user identity).
**Consequences:** `fullName` is nil on subsequent sign-ins (including after account deletion). Always read name from Keychain/CloudKit, never rely on the ASAuthorizationCredential name field after first sign-in.

### Remote content via Teenybase backend
**Date:** 2026-04 (based on recent commits)
**Status:** Active
**Decision:** Exercises, programs, and benchmarks are served from a Teenybase backend (Cloudflare Workers + D1) with bundled JSON fallback.
**Reasoning:** Allows updating content catalog without app updates. `RemoteContentClient` fetches from backend, caches locally, falls back to `BundledContentProvider` if offline or backend unavailable.
**Alternatives considered:** Bundled-only content (rejected — requires app update for every content change), CloudKit public database (rejected — Teenybase is simpler for read-only content).
**Consequences:** `ContentClientProtocol` abstracts the source. Backend lives in `SundeeFundeeApp/backend/`. Content changes deploy via Wrangler to Cloudflare.
