# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sundee Fundee is a strength training app with hormonal-cycle-aware training recommendations.

**Active codebase:** `SundeeFundeeRN/` — React Native + Expo (TypeScript), targeting iOS, Android, and Web.
**Legacy codebase:** Root `SundeeFundee/` directory — Swift 6 + SwiftUI, iOS 17.0+ (no longer under active development).

## MCP Tools

Use these MCP servers for development tasks instead of manual CLI commands where possible:

### Expo MCP (`mcp__expo-mcp__*`)
- **`search_documentation` / `read_documentation`** — Look up Expo SDK docs before implementing features
- **`learn`** — Get guidance on Expo concepts (e.g., `expo-notifications`, `expo-router`)
- **`add_library`** — Add Expo/RN packages (handles native module configuration)
- **`build_run` / `build_list` / `build_logs`** — Trigger and monitor EAS builds
- **`workflow_create` / `workflow_run`** — Manage EAS workflows

### Firebase MCP (`mcp__plugin_firebase_firebase__*`)
- **`firestore_*`** — Query, add, update, delete Firestore documents and collections; manage indexes
- **`auth_get_users` / `auth_update_user`** — Inspect and manage Firebase Auth users
- **`firebase_get_project` / `firebase_get_sdk_config`** — Get project info and SDK configuration
- **`firebase_get_security_rules` / `firebase_validate_security_rules`** — Read and validate Firestore security rules
- **`functions_list_functions` / `functions_get_logs`** — Inspect Cloud Functions and their logs
- **`crashlytics_*`** — View crash reports, issues, and events
- **`firebase_get_environment` / `firebase_update_environment`** — Manage Firebase environment variables

### iOS Simulator MCP (`mcp__ios-simulator__*`)
- **`list_simulators` / `boot_simulator`** — Manage simulator devices
- **`screenshot` / `get_ui_hierarchy`** — Capture screenshots and inspect UI tree
- **`tap` / `swipe` / `type_text`** — Automate UI interactions for verification
- **`launch_app` / `terminate_app`** — App lifecycle control

### Context7 MCP (`mcp__plugin_context7_context7__*`)
- **`resolve-library-id` / `query-docs`** — Look up latest docs for any library (React Native, Firebase, etc.)

## React Native App (`SundeeFundeeRN/`)

### Commands

```bash
# Install dependencies
cd SundeeFundeeRN && npm install

# Run tests
cd SundeeFundeeRN && npx jest --passWithNoTests

# Start Expo dev server
cd SundeeFundeeRN && npx expo start

# Start on specific platform
cd SundeeFundeeRN && npx expo start --ios
cd SundeeFundeeRN && npx expo start --android
cd SundeeFundeeRN && npx expo start --web

# EAS builds (prefer Expo MCP `build_run` tool)
cd SundeeFundeeRN && eas build --platform ios --profile development
cd SundeeFundeeRN && eas build --platform android --profile development
```

### Deploy
- **EAS Build** for iOS/Android binaries (use Expo MCP `build_run`)
- **EAS Submit** for App Store / Play Store submission
- **EAS Update** for OTA updates (no new binary needed)

### Architecture (React Native)

```
Expo Router (file-based routing)
    ↓
React Components + Hooks
    ↓
Repository layer (src/repos/) — protocol-like abstractions
    ↓
Firebase (Firestore + Auth + Cloud Functions)
    ↓
Domain/ (src/domain/) — pure TypeScript, zero dependencies
```

### Key Directories (`SundeeFundeeRN/`)

- **`app/`** — Expo Router file-based routing (tabs, auth, onboarding)
- **`src/domain/`** — Pure TypeScript business logic (weight calc, cycle adaptation, injury engine)
- **`src/repos/`** — Data access layer (Firestore, AsyncStorage)
- **`src/components/`** — Reusable UI components
- **`src/hooks/`** — Custom React hooks
- **`src/theme/`** — Art Deco design tokens: cream (#F4F0DF), navy (#0D1A40), orange (#F2731A)
- **`src/export/`** — CSV/ZIP data export
- **`__mocks__/`** — Jest mocks for native modules

---

## Legacy iOS App (Reference Only)

> The Swift/SwiftUI codebase below is no longer under active development. Kept for reference during the React Native rewrite.

### Legacy Commands

```bash
# Regenerate Xcode project after modifying project.yml
xcodegen generate
```

```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests
```

### Legacy Deploy
TestFlight builds were deployed via **Xcode Cloud** (manual trigger only).

### Legacy Architecture

```
SwiftUI Views → @Observable ViewModels → Repository Protocols → SwiftData ←→ CloudKit → Domain/
```

### Auth & Routing (React Native)

Expo Router file-based routing with auth guard:
- `app/(auth)/` — Sign-in, sign-up screens
- `app/(app)/` — Authenticated app (tabs: Dashboard, Programs, History, Workouts, Cycle, Maxes, Settings)
- Guest mode: local AsyncStorage only, no Firestore sync
- Authenticated mode: full Firestore sync enabled

### Programs (React Native)

Programs delivered via bundled `resources/programs.json` (always available) + Firestore (for remote updates).
WODs delivered via bundled `resources/wods.json`, matched by date. Admin dashboard writes to Firestore.

### WOD Admin Dashboard

Next.js dashboard at `wod-dashboard/` — writes WODs to Firestore. Run locally with `cd wod-dashboard && npm run dev`.

### Cloudflare Worker Proxy

`workout-proxy.sundeefundee.workers.dev/generate-workout` proxies Gemini API calls. Uses native Gemini format (`contents`, `systemInstruction`, `generationConfig`), NOT OpenAI-compatible format. Will be replaced by Firebase Cloud Functions.

### Testing (React Native)

- Run tests: `cd SundeeFundeeRN && npx jest --passWithNoTests`
- 71 test suites / 1327+ tests
- `src/domain/` tested in isolation — pure TypeScript, no mocking needed
- `__mocks__/` contains Jest mocks for native modules (expo-audio, expo-haptics, etc.)
- **Never ignore pre-existing failures.** Investigate and resolve all issues — do not dismiss as "pre-existing."

### Coding Conventions (React Native)

- **Repositories use async/await** — All Firestore calls return Promises, handle errors with try/catch
- **AsyncStorage for local-first** — Guest mode persists all data locally; authenticated mode syncs to Firestore
- **`formatWeight(weight, unit)`** — Always thread weightUnit from settings; never hardcode "lbs"
- **Disable buttons for invalid input** — Use `disabled` prop, not silent failures
- **Domain layer is pure TypeScript** — No React, no Firebase imports. Fully unit tested.
- **Benchmark `roundsAndReps` scoring** encodes as `rounds * 10000 + reps` in a single number. Decode: `rounds = Math.floor(value / 10000)`, `reps = value % 10000`.

### Firebase Operations

Use the Firebase MCP tools (`mcp__plugin_firebase_firebase__*`) for:
- **Inspecting Firestore data** — `firestore_get_document`, `firestore_query_collection` instead of manual console checks
- **Managing auth users** — `auth_get_users` to look up test accounts
- **Reading security rules** — `firebase_get_security_rules` before deploying changes
- **Checking Cloud Functions** — `functions_list_functions`, `functions_get_logs` for debugging
- **Crash investigation** — `crashlytics_list_events`, `crashlytics_get_issue` for production issues

### Legacy iOS Conventions (Reference)

- Enum properties on `@Model` types stored as `String` raw values (CloudKit requirement)
- Custom `init(from decoder:)` requires `encode(to:)` (prevents auto-synthesis)
- Xcode project generated from `project.yml` via XcodeGen — never edit `.xcodeproj` directly
- `SundeeFundee/Packages/` showing as untracked in `git status` is expected (git submodule)
