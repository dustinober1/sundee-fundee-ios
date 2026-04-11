# Remote Content Management Design

**Date:** 2026-04-11
**Status:** Approved

## Problem

Programs, benchmarks, and exercises are hardcoded in the app. Adding or updating content requires an App Store submission. We need a way to manage this content remotely.

## Solution

Store program, benchmark, and exercise definitions in the existing Teenybase backend. A web admin dashboard (served by the Cloudflare Worker) allows content management. The app fetches published content on launch, overlaying it on bundled defaults.

## Architecture

```
Admin Dashboard (web)  →  Teenybase API  →  Cloudflare Worker
                                                    ↓
                    App Launch  →  ContentService  →  Teenybase API
                                        ↓
                                Cache locally (file)
                                        ↓
                                Merge with bundled defaults
                                        ↓
                                ViewModels consume merged content
```

## Backend Schema

### `exercises`

| Column | Type | Description |
|---|---|---|
| id | text (auto) | Primary key |
| name | text | Exercise name, e.g. "Back Squat" |
| category | text | compound/isolation/accessory/warmup/cooldown |
| bodyweight | boolean | Bodyweight-only exercise |
| equipment | text | JSON array, e.g. `["barbell", "rack"]` |
| movementTags | text | JSON array, e.g. `["squat", "legs"]` |
| status | text | draft/published |
| sortOrder | integer | Display order in app |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `programs`

| Column | Type | Description |
|---|---|---|
| id | text (auto) | Primary key |
| name | text | Program name, e.g. "Strength Builder" |
| templateKey | text | Maps to ProgramTemplate enum or new key |
| category | text | strength/hypertrophy/fullBody/etc |
| description | text | User-facing description |
| durationWeeks | integer | Program length |
| sessionsPerWeek | integer | Training frequency |
| difficulty | text | beginner/intermediate/advanced |
| phases | text | JSON array of phase definitions with exercises |
| status | text | draft/published |
| version | integer | Bumped on each edit |
| sortOrder | integer | Display order in app |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `benchmarks`

| Column | Type | Description |
|---|---|---|
| id | text (auto) | Primary key |
| name | text | Benchmark name, e.g. "Fran" |
| category | text | classic/strength/endurance/gymnastics/general/sundeeFundee |
| workoutDescription | text | Full WOD/workout description |
| scoringType | text | time/reps/roundsAndReps/weight/load |
| intensity | integer | 1-5 scale |
| movementTags | text | JSON array |
| equipment | text | JSON array |
| timeDomain | text | e.g. "5-10 min" |
| coachNotes | text | Coach tips for this benchmark |
| status | text | draft/published |
| sortOrder | integer | Display order in app |
| createdAt | timestamp | |
| updatedAt | timestamp | |

## App-Side Content Flow

### ContentService

A new `ContentService` (actor) handles fetching, caching, and merging.

**Fetch flow on app launch:**
1. `ContentService.fetchRemoteContent()` queries Teenybase for all published items
2. On success: decode JSON, merge with bundled defaults, save to local file cache
3. On failure: load from local file cache
4. If no cache: fall back to bundled defaults (current hardcoded data)

### Merging Strategy: Remote Overlay

- Bundled content remains in the app as baseline
- Remote items with matching IDs replace bundled items
- Remote items with new IDs are added alongside bundled ones
- Bundled items without remote counterparts stay unchanged
- Each content item has a `source` field: `bundled` or `remote`

### Protocol Design

```swift
protocol ContentClientProtocol: Sendable {
    func fetchExercises() async throws -> [ExerciseDefinition]
    func fetchPrograms() async throws -> [ProgramDefinition]
    func fetchBenchmarks() async throws -> [BenchmarkDefinition]
}
```

- `RemoteContentClient` — fetches from Teenybase, handles caching and fallback
- `BundledContentClient` — returns current hardcoded content (used as fallback)
- ViewModels use `ContentClientProtocol` instead of directly accessing `BenchmarkCatalog` or `ProgramTemplateGenerator`

### Caching

- Remote content cached to app's Documents directory as JSON files
- `exercises.json`, `programs.json`, `benchmarks.json`
- Cache refreshed on each successful fetch
- Stale cache served when offline or fetch fails

## Admin Dashboard

### Overview

Simple single-page admin tool served by the Cloudflare Worker at `/admin`. Protected by the same `ADMIN_SERVICE_TOKEN` already in `.dev.vars`.

### Pages

1. **Dashboard** — Content counts, recent changes
2. **Exercises** — CRUD table with inline editing
3. **Programs** — Form editor with JSON phase/exercise builder
4. **Benchmarks** — CRUD table with detail forms

### Features

- Draft/published toggle for each item
- Sort order field for display ordering
- Version tracking on programs (auto-bumped on save)
- Direct Teenybase API calls from browser (admin token auth)

### Tech Stack

- Static HTML/CSS/JS served from Cloudflare Worker
- Vanilla JS or lightweight framework (Alpine.js/Preact)
- No build step required
- Calls Teenybase REST API directly

## Content Types

### Exercises
- 59 weightlifting + 31 conditioning exercises currently hardcoded in `ExerciseCatalog`
- Remote exercises expand the catalog without app updates
- Used by both programs (exercise pools) and benchmarks

### Programs
- 6 templates currently: strength, hypertrophy, fullBody, linear, dup, block
- Remote programs define full phase/week/session/exercise structure in JSON
- App renders remote programs the same way as generated ones

### Benchmarks
- 30 benchmarks currently in `BenchmarkCatalog`
- Remote benchmarks include all metadata (scoring, equipment, coach notes)
- Cycle-aware readiness features work the same for remote benchmarks

## Constraints

- **No user auth on admin** — Single admin token, developer-only tool
- **No real-time sync** — Content fetched on app launch, not pushed
- **No content versioning in app** — App always uses latest published content
- **Backward compatibility** — Bundled content must work if backend is unreachable
- **Swift 6 strict concurrency** — ContentService is an actor
- **All models remain Codable + Sendable** — Required for JSON serialization

## Success Criteria

1. Can add a new benchmark via admin dashboard and see it in the app within one launch
2. Can edit an existing program's exercises without an App Store update
3. App works fully offline with bundled defaults
4. Admin dashboard is accessible at `/admin` with token auth
5. Draft content is invisible to app users
