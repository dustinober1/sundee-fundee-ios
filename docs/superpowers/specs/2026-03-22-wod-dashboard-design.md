# WOD Dashboard Design Spec

**Date:** 2026-03-22
**Status:** Approved

## Overview

A local-only admin dashboard for creating, editing, and publishing WODs (Workouts of the Day) and training Programs for the Sundee Fundee iOS app. Supports both AI-assisted generation (via Cloudflare worker / Gemini) and manual editing, with output to bundled JSON files and CloudKit Public DB.

## Tech Stack

- **Framework:** Next.js (App Router)
- **Styling:** Tailwind CSS, Art Deco theme (cream #F4F0DF, navy #0D1A40, orange #F2731A)
- **AI Generation:** Cloudflare worker at `workout-proxy.sundeefundee.workers.dev/generate-workout`
- **Data Storage:** Direct read/write of `SundeeFundee/Resources/WODs/wods.json` and `SundeeFundee/Resources/Programs/programs.json`
- **Publishing:** CloudKit Public DB via CloudKit JS SDK

## Architecture

```
Browser UI
    ↓ fetch/save
Next.js API Routes (/api/wods, /api/programs, /api/generate)
    ↓ read/write              ↓ proxy
wods.json / programs.json    Cloudflare Worker (Gemini)
    ↓ push (admin auth)
CloudKit Public DB
```

API routes read/write the bundled JSON files directly on disk and proxy AI generation requests to the Cloudflare worker. CloudKit push is triggered explicitly via a "Publish" action after admin authentication.

## Navigation

Sidebar-based layout with four sections:

1. **WODs** — list, edit, generate daily workouts
2. **Programs** — list, edit, generate multi-week training programs
3. **Exercise Catalog** — read-only reference of weightlifting + conditioning exercises
4. **Settings** — Cloudflare worker URL, CloudKit config

## WOD Manager

### List View

- Table: date, title, exercise count, status (local only / published to CloudKit)
- Default sort: newest first
- Filter by date range
- Bulk select for batch publishing to CloudKit

### WOD Editor

- **Fields:** date (picker), title, description
- ID is auto-generated from date as `wod-{date}` (e.g., `wod-2026-03-22`)
- **Exercise list** with inline editing:
  - Exercise name (autocomplete from catalog, free-text allowed)
  - Variant, sets, reps (fixed/AMRAP/range/text), percent1RM, restMinutes, notes, bodyweightOnly toggle
- Add/remove/reorder exercises via drag
- Duplicate-date warning when creating a WOD for a date that already has one
- Validation mirrors `WODValidator` rules (reimplemented in TS):
  - ID, title, date required
  - Date must be `yyyy-MM-dd` format
  - At least one exercise, no empty exercise names
- Save writes to `wods.json`
- "Publish" button pushes to CloudKit

### WOD Generator

- **Parameters:** date (or date range for batch), focus area (squat/hinge/press/pull/full body), difficulty, exercise count, equipment constraints, custom notes
- "Generate" calls Cloudflare worker, returns WOD(s)
- Results load into editor for review/tweaking before save
- Batch mode: one WOD per date in range, each individually editable

## Program Manager

### List View

- Table: name, category, difficulty, duration (weeks), sessions/week, status (local / published)
- "Generate Program" button at top

### Program Editor

- **Header:** id (auto-slugified from name), name, category, description, difficulty, durationWeeks, sessionsPerWeek
- **Phases:** add/remove/reorder. Each has: name, goal, weekRange
- **Weeks:** accordion or tab-per-week. Each week shows:
  - phaseId (dropdown from defined phases)
  - isTestWeek toggle
  - Sessions list
- **Session editor:** sessionName, sessionType, focus, exercise list (same inline editor as WODs)
- **Cycle Adjustment Profile** (optional): fallbackPhase, lowConfidenceScale, per-phase multipliers (load/sets/reps)
- Validation mirrors `ProgramValidator` rules:
  - Name, ID required; ID must be valid slug (`/^[a-z0-9]+(-[a-z0-9]+)*$/`)
  - durationWeeks must match weeks array length
  - All phase references valid
  - No empty sessions or exercise names
  - percent1RM between 0.0 and 1.5
- Save writes to `programs.json`. "Publish" pushes to CloudKit.

### Program Generator

- **Free-text prompt** (e.g., "12-week squat peaking program, 3x/week, intermediate")
- **Optional structured parameters:** category, duration, sessions/week, difficulty, goal
- "Generate" proxies to Cloudflare worker, returns full program JSON
- AI response is validated before loading into editor; retry on malformed output
- Loads into editor for review/refinement before save

## API Routes

| Route | Method | Purpose |
|---|---|---|
| `/api/wods` | GET | Read all WODs from `wods.json` |
| `/api/wods` | PUT | Replace entire `wods.json` array |
| `/api/wods` | PATCH | Upsert a single WOD by ID |
| `/api/wods` | DELETE | Remove a WOD by ID (query param `?id=wod-2026-03-22`) |
| `/api/programs` | GET | Read all programs from `programs.json` |
| `/api/programs` | PUT | Replace entire `programs.json` array |
| `/api/programs` | PATCH | Upsert a single program by ID |
| `/api/programs` | DELETE | Remove a program by ID (query param `?id=slug`) |
| `/api/generate/wod` | POST | Proxy to Cloudflare worker for WOD generation |
| `/api/generate/program` | POST | Proxy to Cloudflare worker for program generation |
| `/api/cloudkit/publish` | POST | Push WOD or program record to CloudKit Public DB |
| `/api/cloudkit/publish` | DELETE | Delete a record from CloudKit Public DB (unpublish) |

- **PUT** sends the full array (used for batch operations, reordering)
- **PATCH** sends a single record object (used by the editor on save)
- **DELETE** removes by ID from the JSON file or CloudKit

## JSON Key Mappings

Swift property names differ from JSON keys in some cases. The dashboard must use the JSON keys:

| Swift Property | JSON Key |
|---|---|
| `ProgramWeek.phaseID` | `phaseId` |
| `ProgramSession.sessionID` | `sessionId` |

## ExerciseValue Encoding

`ExerciseValue` is polymorphic in JSON. The dashboard must produce these exact encodings:

| Variant | Swift Case | JSON Encoding | Example |
|---|---|---|---|
| Fixed integer | `.fixed(4)` | `4` (number) | `"sets": 4` |
| AMRAP | `.amrap` | `"AMRAP"` (string) | `"reps": "AMRAP"` |
| Range | `.range(8, 12)` | `[8, 12]` (array) | `"reps": [8, 12]` |
| Text | `.text("60s")` | `"60s"` (string) | `"reps": "60s"` |

The decoder also accepts: doubles (truncated to int), string integers (e.g., `"4"` → fixed 4), and hyphenated ranges (e.g., `"8-12"` → range). But the encoder should always produce the canonical forms above.

## CloudKit Integration

### Authentication

The CloudKit JS API token provides **read-only** access to the Public database. Writing requires an authenticated admin session. The dashboard uses CloudKit JS `setUpAuth()` to sign in with an Apple ID in the browser. The admin user must have write permissions to the Public database (configured in CloudKit Dashboard).

Auth flow:
1. On first visit to a page that needs publish, prompt to "Sign in with Apple ID"
2. CloudKit JS handles the OAuth flow
3. Session persists in browser until expiry
4. All publish operations use the authenticated session

### Environment Variables

Required in `.env.local`:

```
NEXT_PUBLIC_CLOUDKIT_CONTAINER=iCloud.com.sundeefundee.app
NEXT_PUBLIC_CLOUDKIT_API_TOKEN=<token>
NEXT_PUBLIC_CLOUDKIT_ENV=production
```

### Record Schema

**WOD record type (`WOD`):**

| Field | Type | Notes |
|---|---|---|
| `id` | String | e.g., `wod-2026-03-22` |
| `date` | String | `yyyy-MM-dd` |
| `title` | String | |
| `description` | String | |
| `exercisesJSON` | String | JSON-encoded `[ProgramExercise]` |

**Program record type (`Program`):**

| Field | Type | Notes |
|---|---|---|
| `id` | String | slug |
| `name` | String | |
| `category` | String | |
| `description` | String | |
| `durationWeeks` | Int64 | |
| `sessionsPerWeek` | Int64 | |
| `difficulty` | String | |
| `phasesJSON` | String | JSON-encoded `[ProgramPhase]` |
| `weeksJSON` | String | JSON-encoded `[ProgramWeek]` |
| `cycleAdjustmentProfileJSON` | String | JSON-encoded `ProgramCycleAdjustmentProfile?` (null if absent) |

### Publish Status Tracking

Publish status is tracked in `wod-dashboard/publish-status.json`:

```json
{
  "wods": {
    "wod-2026-03-22": { "publishedAt": "2026-03-22T10:00:00Z" }
  },
  "programs": {
    "squad-squat-12-week-peak": { "publishedAt": "2026-03-20T14:30:00Z" }
  }
}
```

Updated on successful publish/unpublish. The list views read this to show status indicators.

## File I/O

- API routes resolve paths to `SundeeFundee/Resources/WODs/wods.json` and `SundeeFundee/Resources/Programs/programs.json` relative to the project root
- Reads parse the full JSON array; writes serialize back with pretty-printing (2-space indent)
- Before each write, a `.bak` copy is saved (e.g., `wods.json.bak`). Git history also serves as backup.
- Concurrent write protection via in-memory mutex (sufficient for single-user local tool)

## UI Design

- Art Deco theme matching the iOS app
- Desktop-only layout (no mobile responsiveness needed)
- Inline validation errors (red border + message)
- Toast notifications for success/error states
- Loading state with cancel for AI generation
- Exercise autocomplete grouped by category (weightlifting + conditioning), with free-text fallback

## Exercise Catalog Reference

Read-only view of:
- **Weightlifting:** 39 exercises across 6 categories (Squat, Hip Hinge, Press, Pull, Carry, Olympic)
- **Conditioning:** 21 exercises (reps-based and time-based)

Useful as a quick reference while editing WODs/programs.
