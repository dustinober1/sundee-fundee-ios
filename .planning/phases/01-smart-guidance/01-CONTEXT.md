# Phase 1: Smart Guidance - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement weight recommendations, plateau detection, and PR celebrations to enhance the core workout loop. This phase focuses on actionable guidance during training, not long-term progress visualization (Phase 2).

</domain>

<decisions>
## Implementation Decisions

### Recommendation UI
- **Appearance**: Pre-filled in the weight input field (editable).
- **Acceptance**: Auto-filled (passive acceptance), user just confirms or edits.
- **Explanation**: Small tooltip or 'i' icon explaining the calculation source.
- **Override**: If user changes the value, ask for a reason (e.g., "Injured", "Fatigued", "Just because").

### Plateau Alerts
- **Timing**: Pre-workout modal or banner when opening the workout screen.
- **Trigger**: 3 consecutive failed sessions (unable to complete prescribed reps/weight).
- **Content**: Prescriptive advice (e.g., "Stalled for 3 sessions. Recommended deload: -10%").
- **Action**: Auto-adjust the recommended weight downwards based on the prescription.

### PR Celebrations
- **Intensity**: Full-screen confetti takeover.
- **Trigger**: Immediately upon checking off the set that achieved the PR.
- **Criteria**: New Weight PR (max weight lifted) OR Volume PR (total volume for exercise).
- **Feedback**: Visual (confetti) + Sound effect + Haptic vibration.

### Logic Tuning
- **Rounding**: Round all recommendations to the nearest 5 lbs.
- **Base Calculation**: Fixed percentage of current 1RM (e.g., 70% of 1RM).
- **Success Progression**: Linear increase (+5 lbs) after successful completion of all sets.
- **Failure Handling**: Decrease weight slightly for the next session if reps are missed.

### Claude's Discretion
- **Exact specific wording** of the plateau messages.
- **Design of the tooltip** for recommendation explanation.
- **Animation timing** for the confetti (duration, density).
- **Specific decrease amount** for failure (e.g., -10% vs -5lbs).

</decisions>

<specifics>
## Specific Ideas

- "I want the PR celebration to feel rewarding immediately, not just at the end."
- "Plateau handling should be proactive—fix it for me (auto-adjust) but tell me why."

</specifics>

<deferred>
## Deferred Ideas

- **History/Trends**: Visualizing 1RM history or volume over time (Phase 2).
- **Syncing**: Backing up PRs to the cloud (Phase 3).
- **Social**: Sharing PRs with friends (Future/Backlog).

</deferred>

---

*Phase: 01-smart-guidance*
*Context gathered: 2026-02-17*
