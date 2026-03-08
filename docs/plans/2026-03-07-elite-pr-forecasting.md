# Predictive PR Forecasting & Advanced Analytics

## Overview
Move beyond simple charts of past performance. Use historical workout data, bar velocity (if integrated), and machine learning models to forecast future performance, predict 1RM (One Rep Max) trends, and visually highlight muscle fatigue accumulation.

## Core Value Proposition for Elite Tier
Appeals to serious athletes and data nerds who want to optimize their training. Knowing exactly when they are primed to hit a PR, or seeing visual proof that their current program is working, is highly motivating and sticky.

## Technical Implementation Strategy

### 1. Advanced 1RM Estimation Models
- Upgrade current max calculations (`WeightCalculations`) from basic formulas (Epley/Brzycki) to a more dynamic model.
- Factor in RPE (Rate of Perceived Exertion) and bar velocity (if available from the Form Analysis feature) to calculate an "Estimated Daily 1RM" (e1RM) even on sub-maximal sets.

### 2. Peaking and Forecasting Engine
- Create `PerformanceForecastingService`.
- Analyze the trend line of the user's e1RM over the current cycle.
- **Predictive Peaking:** Calculate the trajectory to estimate what their actual 1RM will be at the end of the program block. 
- Alert the user: "Based on your velocity and volume over the last 4 weeks, you are on track for a 200kg Deadlift PR in Week 8. Let's start tapering."

### 3. Muscle Fatigue Heatmap
- Map every exercise in the `BenchmarkCatalog` and generated workouts to specific muscle groups and central nervous system (CNS) load.
- Calculate accumulated volume (Sets x Reps x Weight) per muscle group over a rolling 7-14 day window.
- Compare this against estimated Maximum Recoverable Volume (MRV) thresholds.

### 4. UI/UX Updates
- **Dashboard Analytics:** A dedicated "Insights" or "Analytics" tab.
- **The Heatmap:** A visual representation of a human body. Muscles colored green (recovered), yellow (stimulated), or red (highly fatigued/overreaching).
- **PR Forecast Chart:** A graph showing historical 1RM, current e1RM trend line, and a projected target zone for the end of the cycle.

## Phased Rollout
1. **Phase 1 (Robust e1RM Tracking):** Implement RPE tracking on working sets and calculate daily e1RM to show a smoother trend line of progress.
2. **Phase 2 (Muscle Volume Tracking):** Build the data mapping to track volume per muscle group and display simple bar charts of "Weekly Volume by Muscle."
3. **Phase 3 (Heatmap & Forecasting):** Build the visual body heatmap and implement the trajectory algorithms to predict future PR dates and values.
