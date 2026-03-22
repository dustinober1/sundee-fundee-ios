# Sundee Fundee Benchmarks — Design Spec

## Summary

Add admin-managed "Sundee Fundee Benchmarks" to the WOD Dashboard and iOS app. Benchmarks are created/edited in the dashboard, published to CloudKit Public DB, and displayed at the top of the app's Benchmarks tab. Bundled JSON provides offline fallback.

## Data Model

### BenchmarkDefinition (CloudKit Record Type)

| Field | Type | Notes |
|-------|------|-------|
| `id` | String | Unique ID, e.g. `sf-benchmark-fran` |
| `name` | String | Display name |
| `category` | String | Always `"Sundee Fundee"` for these |
| `workoutDescription` | String | Detailed instructions |
| `scoringTypeRaw` | String | One of: `time`, `reps`, `weight`, `distance`, `roundsAndReps` |
| `sortOrder` | Int | Controls display order within category |

These match the existing `BenchmarkDefinition` SwiftData model fields. Records published to CloudKit use `recordType: "BenchmarkDefinition"` and `recordName: <id>`.

## Dashboard Changes

### New Page: `/benchmarks`

Two-panel split-view (same pattern as WODs/Programs):

**Left Panel — Benchmark List**
- Search input (filters by name)
- "New Benchmark" button
- List items show: name, scoring type label, publish status dot
- Checkboxes for batch publish
- "Publish All" button for batch operations

**Right Panel — Benchmark Editor**
- Name (text input, required)
- Category (read-only, always "Sundee Fundee")
- Scoring Type (dropdown: Time, Reps, Weight, Distance, Rounds + Reps)
- Description (textarea)
- Sort Order (number input)
- Save / Delete / Publish buttons

### New Files

| File | Purpose |
|------|---------|
| `src/app/benchmarks/page.tsx` | Benchmarks page (list + editor) |
| `src/components/benchmark-list.tsx` | Left panel list component |
| `src/components/benchmark-editor.tsx` | Right panel editor form |

### Data Storage

- Local JSON: `SundeeFundee/Resources/Benchmarks/benchmarks.json`
- Dashboard reads/writes this file via API routes (same as `wods.json`/`programs.json`)
- Publish pushes records to CloudKit via existing S2S auth proxy

### API Routes

| Route | Method | Purpose |
|-------|--------|---------|
| `/api/benchmarks` | GET | Load benchmarks from JSON |
| `/api/benchmarks` | PATCH | Save benchmark to JSON |
| `/api/benchmarks?id=X` | DELETE | Delete benchmark from JSON |

Publish uses existing `/api/cloudkit/request` and `/api/cloudkit/publish` routes.

### Sidebar

Add "Benchmarks" nav item to the sidebar, between Programs and Settings.

## iOS App Changes

### CloudKit Fetch

Add `fetchSundeeFundeeBenchmarks()` to `BenchmarkDefinitionRepository`:
- Queries CloudKit Public DB for `recordType: "BenchmarkDefinition"`
- Converts records to `BenchmarkDefinition` model objects
- Sets `isPredefined = true`, `userID = ""`

### Bundled Fallback

- New file: `Resources/Benchmarks/benchmarks.json`
- Same format as dashboard JSON
- Loaded when CloudKit fetch fails or returns empty

### Category Ordering

Update `BenchmarkCatalog.categoryOrder` to include `"Sundee Fundee"` as the first entry. `BenchmarksViewModel.load()` merges in this order:

1. **Sundee Fundee benchmarks** (from CloudKit / bundled JSON)
2. **Existing catalog** (Classic WODs, Strength, etc.)
3. **User custom benchmarks**

### Shared Package

Add `BenchmarkDefinitionJSON` type to `SundeeFundeeShared` package so dashboard and app share the same serialization format (matching `Program`/`WOD` pattern).

## JSON Format

```json
[
  {
    "id": "sf-benchmark-fran",
    "name": "Fran",
    "category": "Sundee Fundee",
    "workoutDescription": "21-15-9 Thrusters and Pull-ups for time",
    "scoringTypeRaw": "time",
    "sortOrder": 1
  }
]
```

## Out of Scope

- BenchmarkResult logging from the dashboard (app-only)
- Editing existing hardcoded `BenchmarkCatalog` entries
- User-facing benchmark sharing or leaderboards
