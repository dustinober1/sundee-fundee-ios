# "Travel Mode" & Multi-Gym Equipment Profiles

## Overview
Allow users to create and save multiple "Equipment Profiles" representing different locations (e.g., "Home Garage", "Commercial Gym", "Hotel", "CrossFit Box"). Users can toggle "Travel Mode" to instantly recalculate and adapt their current program or AI-generated workouts to fit the available equipment at their current location.

## Core Value Proposition for Elite Tier
Eliminates the friction of staying on track while traveling or switching gyms. Users no longer have to manually figure out how to replace a barbell back squat when all they have are 50lb dumbbells.

## Technical Implementation Strategy

### 1. Equipment Profile Data Model
- Create `EquipmentProfile` model in SwiftData.
- Properties: `name` (String), `isDefault` (Bool), `availableEquipment` (Set<EquipmentType> or detailed list including max dumbbell weight, specific machines, etc.).
- `EquipmentType` enum needs to be robust (Barbell, Dumbbells, Kettlebells, Cable Machine, Pull-up Bar, etc.).

### 2. Adaptation Engine (`TravelModeAdapter`)
- Extend the AI generation logic or create a local fallback mapping system.
- **The Challenge:** Swapping exercises while maintaining the same movement pattern and intended stimulus (e.g., substituting Barbell Bench Press with Dumbbell Floor Press or Deficit Push-ups if no bench is available).
- **Gemini Integration:** Pass the target workout and the new `EquipmentProfile` to Gemini with a prompt like: "Adapt this workout to maintain the exact same volume and muscle group focus, using ONLY the following equipment: [List]."

### 3. Load Translation
- If switching from a barbell exercise to a dumbbell exercise, the prescribed weight needs intelligent translation (e.g., 200lb barbell squat does not equal 100lb dumbbells per hand; it requires a complex adjustment or a shift to Bulgarian Split Squats).
- Leverage `WeightCalculations` and potentially AI to estimate the equivalent relative intensity.

### 4. UI/UX Updates
- **Settings/Profile:** A dedicated section to manage Equipment Profiles.
- **Dashboard/Workout View:** A quick-toggle "Location" or "Travel Mode" button at the top of the screen.
- **On-the-fly Swap:** When toggled, show a diff of the workout changes before applying them (e.g., "Swapping Barbell Squat -> Goblet Squat").

## Phased Rollout
1. **Phase 1 (Profile Creation & Basic Filtering):** Users can define their home gym equipment, and the standard AI generation respects it (improving the baseline experience).
2. **Phase 2 (Manual Travel Swap):** Users can define a second profile and manually request an AI re-generation of today's workout based on the new constraints.
3. **Phase 3 (Instant Adaptation):** Seamless, one-tap "Travel Mode" that intelligently maps and translates the existing program without needing a full prompt regeneration, using cached mappings where possible to save API costs.
