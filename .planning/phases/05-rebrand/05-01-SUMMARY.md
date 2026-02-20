---
phase: 05
plan: 01
subsystem: branding
tags: [rebrand, metadata, text-replacement, onboarding]

dependency-graph:
  requires: []
  provides:
    - "Sundee-Fundee brand name in all UI metadata and copy"
    - "Updated package.json, README.md, CLAUDE.md"
  affects:
    - "Phase 6 (PWA) — manifest.ts will also need Sundee-Fundee brand applied"
    - "Phase 7 (Icons) — no impact"

tech-stack:
  added: []
  patterns:
    - "Text-only rebrand — no constants file, direct edits to 5 files"

key-files:
  created: []
  modified:
    - src/app/layout.tsx
    - src/components/onboarding/onboarding-wizard.tsx
    - package.json
    - README.md
    - CLAUDE.md

decisions:
  - id: D1
    choice: "Direct text edits (no brand.ts constants file)"
    rationale: "Scope is exactly 5 files / 6 replacements; a constants file would add indirection with no benefit at this scale"
    alternatives: ["Create src/lib/constants/brand.ts and import everywhere"]
    impact: "Phase 6 manifest.ts will need its own direct edit — acceptable"

metrics:
  duration: "72 seconds"
  completed: "2026-02-20"
---

# Phase 5 Plan 01: Rebrand Brand Name References Summary

**One-liner:** Surgical 6-string text replacement rebranding "Strength" → "Sundee-Fundee" across metadata, onboarding copy, and config files with zero E2E regression.

## What Was Built

Replaced all UI-visible brand-name occurrences of "Strength" with "Sundee-Fundee" across exactly 5 files. No packages added, no structural changes, no test modifications.

### Changes Made

| File | Line | Old | New |
|------|------|-----|-----|
| `src/app/layout.tsx` | 18 | `title: "Strength - Workout Tracker"` | `title: "Sundee-Fundee"` |
| `src/app/layout.tsx` | 19 | `description: "Track your workouts, build strength"` | `description: "Track your workouts and fitness goals"` |
| `src/components/onboarding/onboarding-wizard.tsx` | 60 | `'Welcome to Strength'` | `'Welcome to Sundee-Fundee'` |
| `package.json` | 2 | `"name": "strength"` | `"name": "sundee-fundee"` |
| `README.md` | 1 | `# Strength - Workout Tracking App` | `# Sundee-Fundee - Workout Tracking App` |
| `CLAUDE.md` | 7 | `**Strength** is a mobile-first` | `**Sundee-Fundee** is a mobile-first` |

## Verification Results

### Brand Audit (`grep -r "Strength" src/`)
All remaining `Strength` occurrences in `src/` are frozen domain identifiers:
- `StrengthApp` / `StrengthDatabase` — Dexie.js DB name/class (permanently frozen — changing destroys user data)
- `PhaseStrengthProfile`, `analyzeStrengthPatterns`, `predictStrengthWindow` — domain function/type names
- `<SelectItem value="strength">Build Strength</SelectItem>` — fitness term, not brand name
- `"Bench Press: Strength Builder"`, `"Positional Strength"` — workout program content

### E2E Suite
- **11/11 tests passed** — exit code 0
- No test files were modified
- Duration: 13.8 seconds

## Decisions Made

### D1: Direct text edits vs. brand.ts constants file
**Choice:** Direct edits to 5 files  
**Rationale:** The scope is exactly 6 string replacements across 5 files. A shared `brand.ts` constants module would add indirection without benefit at this scale. Research considered this approach but recommended against it for the rebrand-only phase.  
**Impact:** Phase 6 manifest.ts will need its own direct brand edit.

## Deviations from Plan

None — plan executed exactly as written. All 6 replacements made in sequence, E2E suite confirmed zero regression.

## Next Phase Readiness

**Phase 6 (PWA):** `manifest.ts` will need `name: "Sundee-Fundee"` and `short_name` (≤12 chars — "Sundee-Fundee" is 13 chars, needs decision). The `super('StrengthApp')` in `dexie.ts` remains permanently frozen.

**Open question carried from STATE.md:** Confirm `short_name` for manifest (≤12 chars constraint — "Sundee-Fundee" is 13).
