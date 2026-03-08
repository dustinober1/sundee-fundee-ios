# Hyper-Personalized Readiness & Auto-Regulation

## Overview
Integrate with Apple HealthKit to pull daily recovery metrics (Sleep, HRV, Resting Heart Rate) and combine them with internal workout data (recent volume, logged pain) to generate a daily "Readiness Score." This score will automatically down-regulate or up-regulate the prescribed workout volume and intensity.

## Core Value Proposition for Elite Tier
Replaces the guesswork of "how hard should I push today?" by acting like a professional coach who adjusts the session based on the athlete's actual physiological state, preventing overtraining and injury.

## Technical Implementation Strategy

### 1. HealthKit Integration
- **Service:** Create `HealthKitReadinessService`.
- **Permissions:** Request read access for Sleep Analysis, Heart Rate Variability (HRV), Resting Heart Rate, and Active Energy Burned.
- **Data Fetching:** Background task or on-app-open fetch to pull the last 24-72 hours of data.

### 2. Readiness Scoring Algorithm
- Create `ReadinessEngine` to calculate a score (0-100).
- **Inputs:**
  - HealthKit metrics (weighted heavily on Sleep and HRV trends vs. baseline).
  - Internal metrics: Time since last workout, localized muscle fatigue (from recent WODs/Programs), and entries in `PainLog`.
- **Output:** Categorized readiness (e.g., "Prime", "Normal", "Fatigued", "Recovery Required").

### 3. Auto-Regulation (The "Smart" Part)
- Integrate with `WorkoutGenerationContext` and `CycleProgramGenerator`.
- **If Fatigued:**
  - Automatically drop prescribed 1RM percentages by 5-10%.
  - Reduce total working sets.
  - Swap high-CNS taxing exercises (e.g., heavy deadlifts) for variations (e.g., RDLs) or machines.
- **If Recovery Required:**
  - Suggest a skip day or generate a custom "Active Recovery / Mobility" session focusing on tight areas (informed by previous workouts).

### 4. UI/UX Updates
- **Dashboard:** Add a prominent "Daily Readiness" widget at the top of the dashboard.
- **Workout Preview:** Show an "AI Adjustment" banner explaining *why* the workout was changed (e.g., "Volume reduced by 10% due to low HRV and poor sleep last night.").

## Phased Rollout
1. **Phase 1 (Data Gathering & Display):** Implement HealthKit read access, calculate the Readiness Score, and display it to the user. No auto-regulation yet.
2. **Phase 2 (Basic Regulation):** Add manual "Apply Readiness Adjustment" button to workouts.
3. **Phase 3 (Full Auto-Regulation):** AI automatically scales the workout upon generation or preview.
