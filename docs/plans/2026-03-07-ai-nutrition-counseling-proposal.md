# AI-Driven Nutrition Counseling & Elite Tier Proposal

## Overview
Introduce a new "Elite" tier ($19.99 - $29.99/mo) that transforms Sundee Fundee from a workout generator into a comprehensive AI Athletic Coach. The centerpiece of this tier is **Customized AI Nutrition Counseling**, which dynamically synchronizes with the user's training load and goals.

## Core Value Proposition
While workout programs are valuable, nutrition is often the missing piece for users seeking strength, hypertrophy, or weight loss. By automating nutrition guidance using Gemini, we provide the value of a professional nutrition coach at a fraction of the cost.

## Key Features

### 1. Dynamic Macro Planning
- AI calculates daily protein, carb, and fat targets.
- **Training-Aware Scaling:** Macros adjust based on the day's prescribed training volume (e.g., "Refeed" days for heavy sessions, "Low Carb" for rest days).
- **Goal Alignment:** Macro splits shift based on whether the user is in a "Strength/Bulk" phase vs. "Endurance/Cut" phase.

### 2. Conversational Meal Ideas & Shopping Lists
- Users can ask the AI Coach: "What should I eat for dinner given I have 40g protein and 60g carbs left?"
- AI provides recipes or meal ideas based on the user's dietary preferences (e.g., "Dairy-free", "High-protein vegetarian").
- Generates weekly shopping lists based on a weekly meal plan.

### 3. Supplement Guidance
- AI provides evidence-based supplement recommendations (Creatine, Whey, Magnesium, etc.) based on training intensity and goals.

## Technical Implementation Strategy

### 1. User Profile Extensions (`User.swift`)
Add fields for:
- `dietaryPreferencesRaw`: String (JSON/CSV of preferences/allergies)
- `nutritionGoalRaw`: String (Bulk, Cut, Maintenance)
- `dailyCalorieTarget`: Double? (Optional override)

### 2. Nutrition Analysis Engine
- Create `NutritionService` that interfaces with Gemini.
- **Context Window:** Include the current `ActiveCycle`, recent `CompletedWorkout` volume, and `User` profile.
- **Prompt:** "Act as a sports nutritionist. Review this athlete's recent squat-heavy volume and their goal of hypertrophy. Recommend a macro split for tomorrow's rest day."

### 3. Subscription Tier Update (`SubscriptionTier.swift`)
- Add `case elite`.
- Set price to $19.99/mo or $29.99/mo.
- Gate Nutrition and Conversational Coach features behind this tier.

## Impact on Revenue
- **Tier Differentiation:** Provides a clear "Premium" vs "Professional" distinction.
- **Higher LTV:** Nutrition integration creates higher "stickiness" as users track their progress holistically within one app.
- **Premium Pricing:** Human nutrition coaching typically costs $100-$300/mo. AI-driven counseling at $29.99/mo offers immense relative value.

## Next Steps
1. **Design Doc:** Finalize the schema changes and UI wireframes for the Nutrition tab.
2. **Prototype Prompting:** Test Gemini's reliability in generating structured macro data based on workout volume.
3. **StoreKit Update:** Add the Elite product ID to the App Store Connect and local `.storekit` config.
