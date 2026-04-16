# Phase 1: Recovery Score Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 01-recovery-score-foundation
**Areas discussed:** Score card design, Breakdown screen, Trend chart style, Graceful degradation

---

## Score Card Design

### Q1: How should the recovery score be displayed on the dashboard?

| Option | Description | Selected |
|--------|-------------|----------|
| Circular ring | Filled ring/arc around score number, color shifts green/yellow/red. Similar to Apple Activity Rings. | ✓ |
| Gauge arc | Semi-circular gauge with needle. Analog/speedometer feel. | |
| Bold number card | Large JetBrains Mono number with color-coded background strip. Minimal. | |

**User's choice:** Circular ring
**Notes:** None

### Q2: Should the score card also show a "Push Day" / "Rest Day" label?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, push/rest label | Shows actionable guidance right on the card — aligns with core value. | ✓ |
| Score number only | Minimal — just the number and "Recovery". | |

**User's choice:** Yes, push/rest label
**Notes:** None

### Q3: Where should the recovery score card sit on the dashboard?

| Option | Description | Selected |
|--------|-------------|----------|
| Top of dashboard | First thing the user sees — hero element. Existing content shifts down. | ✓ |
| Inline with other cards | Same visual weight as other dashboard cards. | |

**User's choice:** Top of dashboard
**Notes:** None

---

## Breakdown Screen

### Q4: How should the 5-input breakdown be displayed?

| Option | Description | Selected |
|--------|-------------|----------|
| Horizontal bars | Each input as a labeled horizontal bar showing contribution. Color-coded independently. | ✓ |
| Radar/spider chart | Pentagon chart with 5 axes. Visual at a glance but harder to read exact values. | |
| Stacked list with icons | Each input as a row with icon, label, sub-score, and explanation line. | |

**User's choice:** Horizontal bars
**Notes:** None

### Q5: Should each bar show a short explanation line?

| Option | Description | Selected |
|--------|-------------|----------|
| Label + number + explanation | More informative — user understands WHY each sub-score is what it is. | ✓ |
| Label + number only | Minimal — bars speak for themselves. | |

**User's choice:** Label + number + explanation
**Notes:** None

---

## Trend Chart Style

### Q6: How should the 30-day recovery trend chart look?

| Option | Description | Selected |
|--------|-------------|----------|
| Line chart with cycle bands | Smooth line over 30 days. Vertical color bands mark cycle phases. | ✓ |
| Area chart with bands | Filled area under line. Score dips feel more dramatic. | |
| Bar chart with bands | Daily bars, each colored by score. More discrete feel. | |

**User's choice:** Line chart with cycle bands
**Notes:** None

### Q7: Should the trend chart live on the breakdown screen or separately?

| Option | Description | Selected |
|--------|-------------|----------|
| On breakdown screen | Scroll down from bars to see trend. One tap from dashboard. | ✓ |
| Separate Analytics tab | Add to existing Analytics view. Keeps breakdown focused on today. | |

**User's choice:** On breakdown screen
**Notes:** None

---

## Graceful Degradation

### Q8: How should the score behave when HealthKit is denied or Watch absent?

| Option | Description | Selected |
|--------|-------------|----------|
| Partial score + missing badge | Compute from available inputs, redistribute weights. Show "3/5 inputs" badge. Grayed-out bars for missing inputs. | ✓ |
| Full score, no indicator | Redistribute silently. No indication of missing inputs. | |
| Dash/empty until all inputs | Show "--" until all 5 inputs available. Forces permissions. | |

**User's choice:** Partial score + missing badge
**Notes:** None

### Q9: Should recovery score work for guest users?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, works for guests | Guest users see score from local data (training load + pain). | |
| Score requires sign-in | Recovery score only for signed-in users. Guest sees placeholder. | ✓ |

**User's choice:** Score requires sign-in
**Notes:** Simplifies data persistence — all score history goes to CloudKit only.

---

## Claude's Discretion

- Score weight distribution formula across the 5 inputs
- Sleep deduplication algorithm
- Exact color values for cycle phase bands
- Animation/transition style for ring fill
- Internal data model field naming

## Deferred Ideas

None — discussion stayed within phase scope
