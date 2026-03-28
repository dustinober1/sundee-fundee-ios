# Periodization Templates Design

**Date:** 2026-03-28
**Status:** Approved
**Tier:** Plus ($4.99/mo)

## Purpose

Add 3 periodization templates (Linear, Daily Undulating, Block) to the existing program builder template picker. Each generates a program with proper phase structures and periodization-specific progression patterns.

## Scope

Extension of existing code only — no new views or models. Adds 3 new `ProgramTemplate` cases and corresponding exercise generation logic in `ProgramTemplateGenerator`.

## Template Definitions

| Template | Default | Phases | Progression | Sessions |
|----------|---------|--------|-------------|----------|
| Linear | 6wk, 3x/wk | Single phase | Reps decrease (10→3), %1RM increases (60→85%) each week | Squat/Bench/Deadlift focus rotation |
| DUP | 4wk, 3x/wk | Single phase | Heavy day (3-5 reps), Moderate day (6-8), Volume day (10-12) within each week | Same exercises, different rep/intensity per day |
| Block | 9wk, 3x/wk | 3 phases (3wk each) | Accumulation (4x10 @ 60-65%), Intensification (4x5 @ 75-80%), Peaking (5x2 @ 85-90%) | Same exercise pattern, phase dictates rep scheme |

### Linear Periodization

Classic beginner-intermediate approach. Weekly progression from high volume/low intensity to low volume/high intensity:
- Week 1: 4×10 @ 60%
- Week 2: 4×8 @ 65%
- Week 3: 4×6 @ 72%
- Week 4: 4×5 @ 78%
- Week 5: 4×3 @ 83%
- Week 6: 4×2 @ 88%

Sessions rotate Squat/Bench/Deadlift focus with appropriate accessory work.

### Daily Undulating Periodization (DUP)

Varies rep scheme within each week for the same exercises:
- Day 1 (Heavy): 5×3 @ 85%, 3 min rest
- Day 2 (Moderate): 4×6 @ 72%, 2 min rest
- Day 3 (Volume): 3×12 @ 60%, 90 sec rest

Each week applies +1-2% across all days. Full body each day with compound focus.

### Block Periodization

Three distinct 3-week phases using `ProgramPhase` structures:
- **Accumulation** (weeks 1-3): 4×10 @ 60-65%, high volume, moderate intensity
- **Intensification** (weeks 4-6): 4×5 @ 75-80%, moderate volume, high intensity
- **Peaking** (weeks 7-9): 5×2 @ 85-90%, low volume, max intensity

Same exercise selection across phases — only rep scheme and intensity change.

## Changes

### Modified Files

1. **`SundeeFundee/Domain/ProgramTemplateGenerator.swift`**
   - Add `.linear`, `.dup`, `.block` cases to `ProgramTemplate` enum with display names, icons, subtitles, descriptions, default durations/frequencies
   - Add `linearExercises(focus:week:totalWeeks:)` method — computes reps/percent1RM based on week position
   - Add `dupExercises(focus:day:week:)` method — selects rep scheme based on day number
   - Add `blockExercises(focus:week:)` method — selects rep scheme based on phase (week 1-3, 4-6, 7-9)
   - Block template generates `ProgramPhase` structures (Accumulation, Intensification, Peaking)

2. **`SundeeFundee/Features/Programs/CreateProgramView.swift`**
   - Split template picker into "Basic" section (Strength, Hypertrophy, Full Body) and "Periodization" section (Linear, DUP, Block)
   - Periodization section gated behind `.periodizationTemplates` feature entitlement

## Testing

- Each new template produces correct week counts and session counts
- Linear: reps decrease and %1RM increases week-over-week
- DUP: 3 different rep schemes within same week
- Block: 3 ProgramPhase structures with correct week ranges
- All 6 templates produce valid program IDs and non-empty exercises
- Display info (names, icons, subtitles) for new templates

## Out of Scope

- Custom periodization parameters (phase lengths, rep ranges)
- Combining periodization with basic templates
- Auto-deload integration (separate feature)
