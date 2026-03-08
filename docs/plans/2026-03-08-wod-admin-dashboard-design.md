# WOD Admin Dashboard Design

## Overview

A web dashboard for coaches to author, schedule, and publish daily workouts (WODs) to the Sundee Fundee iOS app. Supports natural language input, AI-assisted generation, and template-based editing.

## Architecture

```
Next.js (Vercel, free tier)
    ↓
Two authoring modes:
  1. Natural language parser (client-side, no API)
  2. AI generation → Cloudflare AI Gateway → Gemini
    ↓
Structured WOD (editable form)
    ↓
CloudKit Web Services → CloudKit Public DB
    ↓
iOS App (existing CloudKitWODRepository)
```

No new backend or database. The dashboard writes directly to the existing CloudKit Public DB that the iOS app already reads from.

## Workout Authoring

### Mode 1: Natural Language Parser

Client-side parser that converts coach-speak into structured WODs. Auto-detects template type.

Examples:
- `"5x5 back squat 75%, 3x10 RDL 60%, finish with 3x60s plank"` → Strength
- `"AMRAP 12 min: 10 KB swings, 15 box jumps, 200m run"` → AMRAP
- `"EMOM 20: odd min 5 power cleans, even min 10 burpees"` → EMOM

### Mode 2: AI Workout Generator

Prompt-based generation via Cloudflare AI Gateway → Gemini.

Examples:
- `"Heavy lower body day, 45 minutes, intermediate lifters"`
- `"Active recovery Friday, bodyweight only"`
- `"Competition prep peaking week, day 3 of 4"`

Both modes output the same structured WOD format into an editable template form.

## Workout Templates

| Template | Key Fields |
|----------|-----------|
| **Strength** | Exercise, sets, reps, %1RM, rest, notes |
| **AMRAP** | Time cap (min), list of exercises with reps |
| **EMOM** | Duration (min), interval (1/2/3 min), exercises per interval |
| **For Time** | Exercise list with reps, optional time cap |
| **Circuit/Superset** | Groups of exercises, rounds, rest between groups |

## CloudKit Record Changes

Extend the existing `WOD` record type with three new fields:

| Field | Type | Purpose |
|-------|------|---------|
| `templateType` | String | `"strength"`, `"amrap"`, `"emom"`, `"forTime"`, `"circuit"` |
| `publishDate` | String | Date the WOD becomes visible (yyyy-MM-dd) |
| `status` | String | `"draft"` or `"published"` |

The existing `exercisesJSON` field stays. Each template structures exercises differently within the same JSON blob.

## Scheduling

- Dashboard sets `publishDate` on each WOD
- iOS app filters: `publishDate <= today AND status == "published"`
- No cron jobs or cloud functions — client-side filtering handles it

## Web Dashboard Pages

1. **Login** — Sign in with Apple (web). Checks `AdminUser` record in CloudKit.
2. **WOD Calendar** — Month view showing scheduled WODs by date. Click a date to create/edit.
3. **WOD Editor** — Main authoring screen:
   - Text input area (natural language or AI prompt)
   - Template type auto-detected or manually selected
   - Editable structured form with template-specific fields
   - Exercise search from existing catalog
   - Title and description auto-generated but editable
   - Preview of in-app appearance
   - Save as draft or publish
4. **Admin Management** — List of admin users. Add by Apple ID, remove.

## Draft vs Published

- **Draft** — `status: "draft"`. Saved to CloudKit, not visible to app users.
- **Published** — `status: "published"`. Visible on or after `publishDate`.
- Coaches can edit published WODs (updates in place).

## iOS App Changes

### WOD Model
- Add `templateType: String` field
- Extend exercise decoding for template-specific fields (timeCap, interval, grouping)

### CloudKitWODRepository
- Filter query: `publishDate <= today AND status == "published"`

### WOD Execution View
- Template-aware rendering:
  - **Strength** — Current behavior (unchanged)
  - **AMRAP/For Time** — Running timer, round counter
  - **EMOM** — Interval timer with audio cue
  - **Circuit** — Group headers, "next group" transitions

### Bundled Fallback
- `wods.json` stays as emergency fallback
- Less important once dashboard is primary authoring tool

## Admin Access

Role-based via `AdminUser` record type in CloudKit Public DB. Fields: `appleUserID`, `role` (`"owner"`, `"coach"`). Owner seeds initial admin, admins can invite others.

## Tech Stack

| Component | Tech | Cost |
|-----------|------|------|
| Dashboard | Next.js + Vercel | Free |
| Auth | Sign in with Apple (web) | Free |
| AI Generation | Cloudflare AI Gateway → Gemini | Existing setup |
| Database | CloudKit Public DB (existing) | Free |
| iOS changes | Extend WOD model + template views + timers | N/A |

## Risk: CloudKit Web Services

Apple's CloudKit JS documentation is sparse and the DX is rougher than Firebase/Supabase. This is the main trade-off for zero infrastructure cost. If it proves too painful during implementation, Firebase (already configured) is the fallback.

## Not In Scope

- No new backend/API server
- No new database
- No push notifications (WODs appear on app open)
- No user-facing web app (dashboard is admin-only)
