# Conversational AI Coach Check-ins

## Overview
Transition the AI from a transactional "workout generator" to a continuous, conversational coach. Users will have a weekly interactive review session (text or voice) where the AI analyzes their past week's performance, gathers subjective feedback, and collaboratively plans the upcoming week.

## Core Value Proposition for Elite Tier
Provides the emotional and strategic support of a human coach. It creates accountability, ensures the program adapts to life events (stress, schedule changes), and deepens user engagement.

## Technical Implementation Strategy

### 1. Data Aggregation (The Context Window)
- Create `WeeklyReviewContextBuilder`.
- Gather data for the past 7 days:
  - Completed workouts (sets, reps, weights vs. prescribed).
  - Missed workouts.
  - Recorded RPEs (Rate of Perceived Exertion) and any notes left on sets.
  - Readiness scores and pain logs.
  - Upcoming schedule constraints (if inputted by the user).

### 2. LLM Integration (Gemini Pro)
- Use Gemini 1.5 Pro for its larger context window and advanced reasoning.
- **System Prompt:** Act as a supportive but analytical strength coach. Review the provided data, highlight wins, gently address misses, ask 1-2 targeted questions about recovery or form, and propose a strategy for next week.
- **Session State:** Maintain the conversation history for the duration of the check-in to allow back-and-forth iteration (e.g., User: "I have only 3 days to train next week." AI: "Understood, I'll condense your 4-day split into 3 full-body sessions.").

### 3. Actionable Outcomes
- The conversation must result in structured data output (JSON) alongside the text response.
- This structured data will directly feed into `CycleProgramGenerator` or `OfflineWorkoutGenerator` to modify the upcoming week's `ProgramSession`s.

### 4. UI/UX Updates
- **Check-in Interface:** A chat-like UI (similar to popular LLM interfaces) focused on the weekly review.
- **Trigger:** A prominent notification/card on Sunday or the user's designated "Rest/Planning" day.
- **Voice Option:** Integrate native iOS Speech-to-Text and Text-to-Speech to allow users to have a hands-free conversation while commuting or walking.

## Phased Rollout
1. **Phase 1 (Text-based Weekly Summary):** AI generates a static, one-way weekly review summary based on data.
2. **Phase 2 (Interactive Chat):** Implement the chat UI allowing users to respond to the summary and request tweaks for next week.
3. **Phase 3 (Voice Integration):** Add speech-to-text and text-to-speech for a true "coach call" experience.
