# Custom Program Builder Design

**Date:** 2026-03-28
**Status:** Approved
**Tier:** Plus ($4.99/mo)

## Purpose

Allow Plus/Premium users to create custom multi-week training programs using a hybrid guided builder: pick a template, customize duration/frequency, then drill down to edit individual sessions and exercises.

## User Flow

1. **Choose Template** — ProgramListView → "Create Program" button (gated behind `.programBuilder`). User picks from 3 templates: Strength, Hypertrophy, Full Body. Templates stack vertically on iPhone with icon + name + description.

2. **Customize Basics** — User names the program, selects duration (3/4/6/8 weeks), sessions per week (3/4/5), and optional description. Tapping "Generate Program" creates the full structure from the template.

3. **Edit Week/Session Overview** — Scrollable list of weeks, each showing its sessions. Tap a session to drill into the exercise editor. Save button in toolbar.

4. **Session Exercise Editor** — List of exercises with sets/reps/percent1RM/rest. Tap to edit an exercise, drag to reorder, swipe to delete, "+ Add Exercise" at bottom.

## Data Model

### CustomProgramRecord (new SwiftData @Model)

```
id: String (UUID)
userID: String
name: String (denormalized for list display)
programJSON: String (full Program struct serialized as JSON)
createdAt: Date
updatedAt: Date
```

Reuses the existing `Program` Codable struct — same type that powers bundled/CloudKit programs. Custom programs use `category: "custom"` to distinguish them in lists. The JSON wrapper pattern matches `GeneratedWorkoutRecord`.

### CustomProgramRepository (new protocol + SwiftData implementation)

```
save(_ record: CustomProgramRecord) throws
fetchAll(userID: String) throws -> [CustomProgramRecord]
fetch(id: String) throws -> CustomProgramRecord?
update(_ record: CustomProgramRecord) throws
delete(_ record: CustomProgramRecord) throws
```

## Template Generation

### ProgramTemplateGenerator (new Domain type, pure Swift)

`static func generate(template:name:durationWeeks:sessionsPerWeek:) -> Program`

Three templates:

| Template | Default | Session Focus Pattern | Rep Ranges | Progression |
|----------|---------|----------------------|------------|-------------|
| Strength | 4wk, 3x/wk | Squat / Bench / Deadlift | 3-5 reps, 78-85% | +2% per week |
| Hypertrophy | 6wk, 4x/wk | Upper / Lower / Push / Pull | 8-12 reps, 60-70% | +1 rep or +2% per week |
| Full Body | 4wk, 3x/wk | Full Body A / B / C | 6-10 reps, 65-75% | +2% per week |

Exercises sourced from `WeightliftingExerciseCatalog` when possible. Each session gets 4-6 exercises with appropriate sets/reps/rest for the template type. Progressive overload is baked in via slight percent1RM increases week-over-week.

## Navigation

- "Create Program" button in `ProgramListView` toolbar — gated via `.requiresSubscription(.programBuilder)`
- Pushes `CreateProgramView` (template picker + customize basics)
- On generate, pushes `ProgramEditorView` (week/session overview with Save)
- Tapping a session pushes `SessionEditorView` (exercise list with add/edit/reorder/delete)
- Tapping an exercise presents `ExerciseEditorSheet` (modal sheet for sets/reps/rest/percent1RM)
- Custom programs appear in `ProgramListView` alongside bundled programs with a "Custom" badge
- Users can enroll in custom programs using the existing `EnrolledProgram` flow
- Editing requires canceling active enrollment first

## File Structure

```
New files:
  SundeeFundee/Models/CustomProgramRecord.swift
  SundeeFundee/Repositories/SwiftData/SwiftDataCustomProgramRepository.swift
  SundeeFundee/Domain/ProgramTemplateGenerator.swift
  SundeeFundee/Features/Programs/CreateProgramView.swift
  SundeeFundee/Features/Programs/CreateProgramViewModel.swift
  SundeeFundee/Features/Programs/ProgramEditorView.swift
  SundeeFundee/Features/Programs/SessionEditorView.swift
  SundeeFundee/Features/Programs/ExerciseEditorSheet.swift

Modified files:
  SundeeFundee/Features/Programs/ProgramListView.swift (add Create button + custom program display)
  SundeeFundee/Features/Programs/ProgramListViewModel.swift (load custom programs)
  SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift (add CustomProgramRepository protocol)
  SundeeFundee/App/AppModelContainer.swift (add CustomProgramRecord to allModels)
```

## Testing Strategy

- **ProgramTemplateGenerator tests** — Pure domain: each template produces valid programs with correct counts and progressive overload. Validated via ProgramValidator.
- **CustomProgramRepository tests** — CRUD: save, fetch, update, delete. Program JSON round-trips correctly.
- **CreateProgramViewModel tests** — Static helpers: template selection, validation (name required, duration/frequency bounds), save logic.
- **ProgramListViewModel tests** — Custom programs appear alongside bundled, "Custom" badge logic, delete.

## Out of Scope

- Duplicating/forking bundled programs into custom
- Sharing custom programs with other users
- AI-assisted program generation
- Periodization templates (separate Plus feature)
- Auto-deload scheduling (separate Plus feature)
- Editing custom program after enrollment started (must cancel first)
