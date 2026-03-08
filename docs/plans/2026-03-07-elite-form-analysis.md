# Advanced Bar Path & Form Analysis

## Overview
Utilize on-device computer vision and cloud-based LLM analysis to track barbell movement during a set, provide immediate visual feedback (bar path overlay), and deliver actionable AI coaching cues to correct form breakdown.

## Core Value Proposition for Elite Tier
Provides the closest experience possible to having a human coach watching your sets. Helps prevent injuries, identifies technical inefficiencies, and justifies a premium price point through highly visible, "cool factor" technology.

## Technical Implementation Strategy

### 1. On-Device Vision Tracking (The "Fast" Layer)
- **Framework:** Apple Vision (`VNDetectHumanBodyPoseRequest` and/or object tracking for the barbell plates).
- **Implementation:** Create `FormAnalysisService`.
- **Functionality:** 
  - Process video frames locally in real-time or immediately post-set.
  - Track the (X, Y) coordinates of the barbell or key joints (hip, knee, shoulder).
  - Draw a visible "bar path" line overlaid on the video.
  - Calculate basic metrics: bar velocity, depth (e.g., hip crease vs. knee), and gross deviations from vertical.

### 2. AI Coaching Analysis (The "Smart" Layer)
- **Framework:** Gemini 1.5 Pro/Flash (Multimodal Vision capabilities).
- **Implementation:** 
  - When a user requests a "Form Check," extract keyframes (e.g., bottom of the squat, sticking point) or send a compressed short clip to the Gemini API.
  - **Prompting:** Provide context ("This is a 1RM Deadlift attempt from the side angle"). Ask the AI to identify specific technical faults (e.g., back rounding, hips rising early, soft lockout).
- **Output:** Concise, actionable cues (e.g., "Your hips shot up early on the ascent. Cue: 'Leg press the floor away' before pulling.").

### 3. Integration with App Data
- Link form breakdown to `InjuryProfile` and `PainLog`. (e.g., If the AI sees knee valgus and the user reports knee pain, suggest a modification).
- Store bar velocity data to feed into Predictive PR Forecasting.

### 4. UI/UX Updates
- **Workout Execution:** Add a "Record Set" camera mode with alignment guides (e.g., "Place phone at hip height, side profile").
- **Post-Set Review:** A video player showing the set with the drawn bar path. A button to "Get AI Coach Feedback" (which triggers the API call).
- **Cost Control:** Limit "AI Form Checks" to X per month for Elite users, or only on heavy working sets, to manage API costs. The local "Bar Path" drawing can be unlimited.

## Phased Rollout
1. **Phase 1 (Video Capture & Local Playback):** Allow users to record and save sets within the app for their own review.
2. **Phase 2 (Local Bar Path Tracking):** Implement the Vision framework to draw the line on the video. No AI interpretation yet.
3. **Phase 3 (Multimodal AI Feedback):** Integrate Gemini Vision to provide text-based coaching cues on the recorded videos.
