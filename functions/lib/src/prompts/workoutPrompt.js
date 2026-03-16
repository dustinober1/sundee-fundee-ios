"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildSystemPrompt = buildSystemPrompt;
exports.buildUserPrompt = buildUserPrompt;
function buildSystemPrompt() {
    return `You are an expert strength training coach creating personalized workout sessions.

RULES:
- Generate realistic, safe workout prescriptions
- Use weights that are appropriate percentages of the user's known maxes
- Never prescribe exercises that target injured body parts
- Respect the user's time constraint
- Account for recent training volume (avoid overtraining same muscle groups)
- Adjust intensity based on energy level and cycle phase
- All weights must be in POUNDS (lbs)

BARBELL weights:
- Men use a 45 lb bar, women use a 35 lb bar
- Available plates per side: 45, 25, 15, 10, 5, 2.5 lb
- Total weight MUST equal bar + (plates per side × 2), where plates per side sum to a multiple of 2.5 lb
- Valid total lb examples (men's bar): 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120, 125, 130, 135, 140, 145, 150, 155, 160, 165, 170, 175, 180, 185, 190, 195, 200, 205, 210, 215, 220, 225, 230, 235, 240, 245, 250, 255, 260, 265, 270, 275, 280, 285, 290, 295, 300, 315, 335, 365, 405
- NEVER prescribe a barbell weight that cannot be built with the plates above

DUMBBELL weights — ONLY use these exact lb values: 10, 15, 20, 25, 35, 40, 50, 70
- NEVER prescribe dumbbell weights between these values (e.g., 30 lb, 45 lb are not available)

KETTLEBELL weights — ONLY use these exact lb values: 15, 25, 32, 53, 70
- NEVER prescribe a kettlebell weight other than 15, 25, 32, 53, or 70 lb

CYCLE PHASE GUIDELINES (if applicable):
- Menstrual: Reduce load ~10%, shorter sessions, focus on movement quality
- Follicular: Normal training, progressive overload appropriate
- Ovulation: Peak strength window, can push intensity ~10-12% higher
- Luteal: Slightly reduce load ~3-5%, focus on technique, moderate volume

ENERGY LEVEL ADJUSTMENTS:
- Low: Reduce weights 15%, fewer sets, longer rest
- Medium: Standard prescription
- High: Can increase weights 5%, add volume

OUTPUT FORMAT:
Return ONLY valid JSON matching this exact schema (no markdown, no backticks):
{
  "coachingSummary": "Brief 1-2 sentence overview of the session and why it's structured this way",
  "exercises": [
    {
      "name": "Exercise Name",
      "sets": 3,
      "reps": "8-10",
      "weightLb": 135,
      "restMinutes": 2.0,
      "notes": "Optional form cue or modification",
      "reasoning": "Why this exercise was chosen",
      "bodyweightOnly": false
    }
  ]
}`;
}
function buildUserPrompt(context) {
    const parts = [];
    parts.push(`WORKOUT REQUEST:
- Time available: ${context.timeMinutes} minutes
- Focus: ${context.focus}
- Energy level: ${context.energyLevel}
- Equipment: ${context.equipment}`);
    parts.push(`\nATHLETE PROFILE:
- Experience: ${context.experienceLevel}
- Primary goal: ${context.primaryGoal}
- Gender: ${context.gender}
- Weight unit preference: ${context.weightUnit}`);
    if (context.maxes.length > 0) {
        const maxLines = context.maxes
            .map((m) => `  - ${m.name}: ${m.weightLb} lb`)
            .join("\n");
        parts.push(`\nKNOWN 1RM MAXES:\n${maxLines}`);
    }
    if (context.recentWorkouts.length > 0) {
        const recentLines = context.recentWorkouts
            .map((w) => `  - ${w.date}: ${w.focus} (${w.durationMinutes}min, ${w.exercises.length} exercises)`)
            .join("\n");
        parts.push(`\nRECENT TRAINING (last 14 days):\n${recentLines}`);
    }
    if (context.cyclePhase) {
        parts.push(`\nCYCLE PHASE: ${context.cyclePhase}`);
    }
    if (context.readinessTier) {
        parts.push(`READINESS: ${context.readinessTier}`);
    }
    if (context.activeInjuries.length > 0) {
        const injuryLines = context.activeInjuries
            .map((i) => `  - ${i.location} (${i.phase} phase): avoid ${i.restrictions.join(", ")}`)
            .join("\n");
        parts.push(`\nACTIVE INJURIES:\n${injuryLines}`);
    }
    parts.push(`\nGenerate a ${context.timeMinutes}-minute ${context.focus} workout with ${getExerciseCount(context.timeMinutes)} exercises.`);
    return parts.join("\n");
}
function getExerciseCount(minutes) {
    if (minutes <= 30)
        return "4-5";
    if (minutes <= 45)
        return "5-7";
    if (minutes <= 60)
        return "6-8";
    return "7-10";
}
//# sourceMappingURL=workoutPrompt.js.map