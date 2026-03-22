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
    ↓ push
CloudKit Public DB
```

API routes read/write the bundled JSON files directly on disk and proxy AI generation requests to the Cloudflare worker. CloudKit push is triggered explicitly via a "Publish" action.

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
- **Exercise list** with inline editing:
  - Exercise name (autocomplete from catalog, free-text allowed)
  - Variant, sets, reps (fixed/AMRAP/range/text), percent1RM, rest, notes, bodyweightOnly toggle
- Add/remove/reorder exercises via drag
- Validation mirrors `WODValidator` rules (reimplemented in TS):
  - ID, title, date required
  - Date must be `yyyy-MM-dd` format
  - At least one exercise, no empty exercise names
- Save writes to `wods.json`, preserving other entries
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
  - Name, ID required; ID must be valid slug
  - durationWeeks must match weeks array length
  - All phase references valid
  - No empty sessions or exercise names
  - percent1RM between 0.0 and 1.5
- Save writes to `programs.json`. "Publish" pushes to CloudKit.

### Program Generator

- **Free-text prompt** (e.g., "12-week squat peaking program, 3x/week, intermediate")
- **Optional structured parameters:** category, duration, sessions/week, difficulty, goal
- "Generate" proxies to Cloudflare worker, returns full program JSON
- Loads into editor for review/refinement before save

## API Routes

| Route | Method | Purpose |
|---|---|---|
| `/api/wods` | GET | Read `wods.json` |
| `/api/wods` | PUT | Write to `wods.json` |
| `/api/programs` | GET | Read `programs.json` |
| `/api/programs` | PUT | Write to `programs.json` |
| `/api/generate/wod` | POST | Proxy to Cloudflare worker for WOD generation |
| `/api/generate/program` | POST | Proxy to Cloudflare worker for program generation |
| `/api/cloudkit/publish` | POST | Push WOD or program record to CloudKit Public DB |

## CloudKit Integration

- Publish uses CloudKit JS SDK with the API token from `.env.local`
- Record types map to `WODCKRecord` and `ProgramCKRecord` field schemas
- Status indicator on list views updates after successful publish
- Publishing is always explicit (never automatic)

## File I/O

- API routes resolve paths to `SundeeFundee/Resources/WODs/wods.json` and `SundeeFundee/Resources/Programs/programs.json` relative to the project root
- Reads parse the full JSON array; writes serialize back with pretty-printing
- Concurrent write protection via simple file lock

## UI Design

- Art Deco theme matching the iOS app
- Desktop-only layout (no mobile responsiveness needed)
- Inline validation errors (red border + message)
- Toast notifications for success/error states
- Loading state with cancel for AI generation
- Exercise autocomplete grouped by category (weightlifting + conditioning), with free-text fallback

## Exercise Catalog Reference

Read-only view of:
- **Weightlifting:** 29 exercises across 6 categories (Squat, Hip Hinge, Press, Pull, Carry, Olympic)
- **Conditioning:** 21 exercises (reps-based and time-based)

Useful as a quick reference while editing WODs/programs.
