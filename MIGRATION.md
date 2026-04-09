# Migration: Multi-Platform to iOS-Only

**Date:** 2026-04-08
**Type:** Platform consolidation

## Why the Web App Was Retired

The Sundee Fundee web app (Next.js PWA) was retired in favor of the native iOS app. The native app provides:

- Better performance and responsiveness via SwiftUI
- Native Apple Sign-In with Keychain session storage
- CloudKit integration for seamless iCloud sync
- StoreKit 2 for subscription management
- HealthKit integration for health and fitness data
- Superior offline support with local data storage
- Access to native iOS features (widgets, activity rings, notifications)

## What Was Removed

### Directories

| Directory | Purpose | Files |
|-----------|---------|-------|
| `web-app/` | Next.js 16 PWA — main web application | 211 |
| `firebase/` | Cloud Functions for AI workout generation | 14 |
| `backend/` | Cloudflare Workers + teenybase wrappers | 3 |
| `scripts/` | Python marketing screenshot generators | 2 |
| `docs/` | Screenshots, app store copy, superpowers docs | 51 |
| `plans/` | Historical planning documents | 28 |
| `.agents/` | Agent skill configurations (25 ASC skills) | 29 |

### Root Files

| File | Purpose |
|------|---------|
| `package.json` / `package-lock.json` | Node.js dependencies |
| `firebase.json` / `firestore.indexes.json` / `.firebaserc` | Firebase project config |
| `.dev.vars` / `wrangler.toml` | Cloudflare Workers config |
| `teenybase.ts` | Teenybase type definitions |
| `opencode.json` | OpenCode configuration |
| `skills-lock.json` | Agent skills lockfile |
| `backlog.md` | Backlog tracking |

## Archive Location

All removed code is preserved in:

```
sundee-fundee-archive-2026-04-08.zip
```

This archive (4.1 MB, 335 files) contains the complete state of the multi-platform codebase before cleanup. It includes all directories and root files listed above.

## What Remains

The repository now contains only the iOS-native codebase:

- **`SundeeFundee/`** — Swift Package (`SundeeFundeeKit`): domain logic, views, viewmodels, auth, CloudKit, StoreKit 2
- **`SundeeFundeeApp/`** — Xcode project that imports the package
- **`CLAUDE.md`** — Updated project instructions for iOS-only development
- **`readme.md`** — Updated project overview
- **`.gitignore`** — Updated for iOS/Xcode patterns
- **`.mcp.json`** — MCP server configuration (XcodeBuildMCP)
- **`Logo.jpeg`** — App logo image

## Domain Logic Migration

The pure business logic (cycle calculations, weight calculations, injury adaptation, benchmark catalog, subscription tiers, AI workout math) was originally implemented in TypeScript (`web-app/src/lib/domain/`) and has been faithfully ported to Swift in `SundeeFundee/Sources/SundeeFundeeKit/DomainLayer/`. The Swift implementation maintains identical algorithms and business rules.
