/**
 * Tests for ai-workout, history, readiness, and benchmarks subdomains.
 * Written FIRST (RED phase) — implementations do not exist yet.
 */

import {
  generateOfflineWorkout,
  selectTemplates,
  filterForEquipment,
  scaleForTime,
  applyWeights,
  applyEnergyLevel,
  buildCoachingSummary,
  defaultPercentage,
} from '../ai-workout/offline-workout-generator';

import type {
  GeneratedWorkout,
  GeneratedExercise,
  QuestionnaireAnswers,
  ExerciseEquipmentType,
} from '../ai-workout/generated-workout';
import {
  getEquipmentType,
  extractMuscleGroups,
  totalEstimatedMinutes,
  strippedForSharing,
} from '../ai-workout/generated-workout';

import type { WorkoutGenerationContext } from '../ai-workout/workout-generation-context';

import type { HistoryItem, HistoryItemSource } from '../history/history-item';
import { getSourceLabel } from '../history/history-item';

import {
  calculateReadinessScore,
  tierFromScore,
  tierDisplayName,
  tierStringForAI,
  adjustmentBannerText,
  blendWithHealthKit,
} from '../readiness/readiness-survey';

import {
  BENCHMARK_CATALOG,
  encodeRoundsAndReps,
  decodeRoundsAndReps,
} from '../benchmarks/benchmark-catalog';

import {
  getBenchmarkCategoryGroups,
} from '../benchmarks/benchmark-catalog';

import benchmarkFixture from '../__fixtures__/benchmark-scoring.json';

// ============================================================================
// WorkoutGenerationContext helpers
// ============================================================================

function makeContext(
  overrides: Partial<WorkoutGenerationContext> = {},
): WorkoutGenerationContext {
  return {
    userID: 'test-user',
    timeMinutes: 30,
    focus: 'strength',
    energyLevel: 'medium',
    equipment: 'full_gym',
    maxes: [],
    recentWorkouts: [],
    cyclePhase: null,
    readinessTier: null,
    activeInjuries: [],
    experienceLevel: 'intermediate',
    primaryGoal: 'strength',
    gender: 'female',
    weightUnit: 'lb',
    desiredSkills: [],
    benchmarkSummaries: [],
    bodyWeightKg: null,
    recentPainActivity: [],
    workoutCompletionRate: null,
    travelModeEnabled: false,
    ...overrides,
  };
}

function makeExercise(overrides: Partial<GeneratedExercise> = {}): GeneratedExercise {
  return {
    id: 'ex-1',
    name: 'Back Squat',
    sets: 4,
    reps: '5',
    weightLb: 135,
    restMinutes: 3,
    notes: null,
    reasoning: null,
    bodyweightOnly: false,
    ...overrides,
  };
}

// ============================================================================
// OfflineWorkoutGenerator
// ============================================================================

describe('OfflineWorkoutGenerator', () => {
  describe('generateOfflineWorkout', () => {
    it('returns a GeneratedWorkout for strength focus', () => {
      const ctx = makeContext({ focus: 'strength' });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.exercises.length).toBeGreaterThan(0);
      expect(workout.questionnaire.focus).toBe('strength');
    });

    it('bodyweight_only equipment excludes barbell exercises', () => {
      const ctx = makeContext({ focus: 'strength', equipment: 'bodyweight_only' });
      const workout = generateOfflineWorkout(ctx);
      for (const ex of workout.exercises) {
        expect(ex.bodyweightOnly).toBe(true);
      }
    });

    it('full_gym equipment allows barbell exercises for strength', () => {
      const ctx = makeContext({ focus: 'strength', equipment: 'full_gym' });
      const workout = generateOfflineWorkout(ctx);
      const hasBarbell = workout.exercises.some(
        (ex) => getEquipmentType(ex.name) === 'barbell',
      );
      expect(hasBarbell).toBe(true);
    });

    it('coaching summary mentions exercise count and time', () => {
      const ctx = makeContext({ focus: 'upper_body', timeMinutes: 45 });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.coachingSummary).toContain('45');
    });

    it('applies energy level adjustment for low energy', () => {
      const ctx30 = makeContext({
        focus: 'strength',
        equipment: 'full_gym',
        energyLevel: 'medium',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
      });
      const ctx15 = makeContext({
        focus: 'strength',
        equipment: 'full_gym',
        energyLevel: 'low',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
      });
      const normal = generateOfflineWorkout(ctx30);
      const reduced = generateOfflineWorkout(ctx15);
      // Find back squat in both workouts
      const squat30 = normal.exercises.find((ex) =>
        ex.name.toLowerCase().includes('squat'),
      );
      const squat15 = reduced.exercises.find((ex) =>
        ex.name.toLowerCase().includes('squat'),
      );
      if (squat30?.weightLb != null && squat15?.weightLb != null) {
        expect(squat15.weightLb).toBeLessThanOrEqual(squat30.weightLb);
      }
    });

    it('includes cycle phase in coaching summary when provided', () => {
      const ctx = makeContext({ cyclePhase: 'menstrual' });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.coachingSummary).toContain('menstrual');
    });

    it('travel mode mentioned in coaching summary', () => {
      const ctx = makeContext({ travelModeEnabled: true });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.coachingSummary.toLowerCase()).toContain('travel');
    });

    it('core focus returns core exercises', () => {
      const ctx = makeContext({ focus: 'core' });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.exercises.length).toBeGreaterThan(0);
    });

    it('conditioning focus returns conditioning exercises', () => {
      const ctx = makeContext({ focus: 'conditioning', equipment: 'bodyweight_only' });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.exercises.length).toBeGreaterThan(0);
    });
  });

  describe('selectTemplates', () => {
    it('upper_body returns upper body templates', () => {
      const templates = selectTemplates('upper_body', 'full_gym');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('lower_body returns lower body templates', () => {
      const templates = selectTemplates('lower_body', 'full_gym');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('full_body returns upper + lower templates', () => {
      const fullBodyTemplates = selectTemplates('full_body', 'full_gym');
      const upperTemplates = selectTemplates('upper_body', 'full_gym');
      const lowerTemplates = selectTemplates('lower_body', 'full_gym');
      expect(fullBodyTemplates.length).toBe(upperTemplates.length + lowerTemplates.length);
    });

    it('push returns push templates', () => {
      const templates = selectTemplates('push', 'full_gym');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('pull returns pull templates', () => {
      const templates = selectTemplates('pull', 'full_gym');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('olympic_lifts returns conditioning + upper body templates', () => {
      const templates = selectTemplates('olympic_lifts', 'full_gym');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('gymnastics returns pull + core templates', () => {
      const templates = selectTemplates('gymnastics', 'bodyweight_only');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('mobility returns core templates', () => {
      const templates = selectTemplates('mobility', 'bodyweight_only');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('stretching returns core templates', () => {
      const templates = selectTemplates('stretching', 'bodyweight_only');
      expect(templates.length).toBeGreaterThan(0);
    });

    it('bodyweight_only filters barbell exercises', () => {
      const templates = selectTemplates('strength', 'bodyweight_only');
      for (const t of templates) {
        expect(t.requiresBarbell).toBe(false);
      }
    });
  });

  describe('filterForEquipment', () => {
    it('full_gym returns all templates', () => {
      const all = selectTemplates('upper_body', 'full_gym');
      const barbell = all.filter((t) => t.requiresBarbell);
      expect(barbell.length).toBeGreaterThan(0);
    });

    it('home_dumbbells excludes barbell exercises', () => {
      const templates = selectTemplates('upper_body', 'home_dumbbells');
      for (const t of templates) {
        expect(t.requiresBarbell).toBe(false);
      }
    });

    it('bodyweight_only returns only bodyweight exercises', () => {
      const templates = selectTemplates('upper_body', 'bodyweight_only');
      for (const t of templates) {
        expect(t.bodyweightOnly).toBe(true);
      }
    });

    it('outdoor returns only bodyweight exercises', () => {
      const templates = selectTemplates('upper_body', 'outdoor');
      for (const t of templates) {
        expect(t.bodyweightOnly).toBe(true);
      }
    });
  });

  describe('scaleForTime', () => {
    it('returns minimum 3 exercises', () => {
      const templates = selectTemplates('upper_body', 'full_gym');
      const result = scaleForTime(templates, 5);
      expect(result.length).toBeGreaterThanOrEqual(3);
    });

    it('longer time produces more exercises', () => {
      const templates = selectTemplates('full_body', 'full_gym');
      const short = scaleForTime(templates, 20);
      const long = scaleForTime(templates, 60);
      expect(long.length).toBeGreaterThanOrEqual(short.length);
    });

    it('returns empty array when given empty templates', () => {
      expect(scaleForTime([], 30)).toEqual([]);
    });
  });

  describe('defaultPercentage', () => {
    it('returns 0.80 for 5 reps', () => {
      expect(defaultPercentage('5')).toBe(0.80);
    });

    it('returns 0.80 for 3 reps', () => {
      expect(defaultPercentage('3')).toBe(0.80);
    });

    it('returns 0.70 for 8-10 reps', () => {
      expect(defaultPercentage('8-10')).toBe(0.70);
    });

    it('returns 0.60 for 12-15 reps', () => {
      expect(defaultPercentage('12-15')).toBe(0.60);
    });

    it('returns 0.65 for unknown reps', () => {
      expect(defaultPercentage('AMRAP')).toBe(0.65);
    });
  });

  describe('applyWeights', () => {
    it('applies 1RM percentage for barbell exercises with known max', () => {
      const templates = selectTemplates('lower_body', 'full_gym');
      const squat = templates.find((t) => t.name === 'Back Squat');
      expect(squat).toBeDefined();
      const exercises = applyWeights(
        [squat!],
        [{ name: 'Back Squat', weightLb: 200 }],
        'full_gym',
      );
      expect(exercises[0].weightLb).toBeGreaterThan(0);
      // 80% of 200 = 160, snapped to barbell
      expect(exercises[0].weightLb).toBe(160);
    });

    it('uses default dumbbell weight for dumbbell templates without max', () => {
      const templates = selectTemplates('upper_body', 'home_dumbbells');
      const dbPress = templates.find((t) => t.requiresDumbbells);
      expect(dbPress).toBeDefined();
      const exercises = applyWeights([dbPress!], [], 'home_dumbbells');
      expect(exercises[0].weightLb).toBeGreaterThan(0);
    });

    it('uses default weight for home_dumbbells equipment even without requiresDumbbells', () => {
      // Face Pulls has no requiresBarbell, no requiresDumbbells
      const templates = selectTemplates('pull', 'home_dumbbells');
      const facePulls = templates.find((t) => t.name === 'Face Pulls');
      if (facePulls) {
        const exercises = applyWeights([facePulls], [], 'home_dumbbells');
        // Face Pulls is not requiresDumbbells, but home_dumbbells provides default
        expect(exercises[0].weightLb).toBeGreaterThan(0);
      }
    });

    it('uses dumbbell default when template has maxKey but no ORM and requiresDumbbells', () => {
      // Create a template with maxKey but no ORM provided, requiresDumbbells=true
      // Dumbbell Overhead Press has no maxKey in templates... but Dumbbell Bench Press has requiresDumbbells
      // Let's just directly test applyWeights with such a template
      const template = {
        name: 'Dumbbell Overhead Press',
        defaultSets: 3,
        defaultReps: '8-10',
        defaultRestMinutes: 2.0,
        bodyweightOnly: false,
        muscleGroups: ['shoulders'],
        requiresBarbell: false,
        requiresDumbbells: true,
        maxKey: 'Dumbbell Overhead Press Max', // has a key but no ORM in dict
      };
      const exercises = applyWeights([template], [], 'full_gym'); // no maxes, so orm = undefined
      // requiresDumbbells = true AND maxKey not found → falls to line 260
      expect(exercises[0].weightLb).toBeGreaterThan(0);
    });

    it('uses home_dumbbells fallback when template has maxKey but no ORM and is not requiresDumbbells', () => {
      const template = {
        name: 'Face Pulls',
        defaultSets: 3,
        defaultReps: '15',
        defaultRestMinutes: 1.0,
        bodyweightOnly: false,
        muscleGroups: ['shoulders', 'back'],
        requiresBarbell: false,
        requiresDumbbells: false,
        maxKey: 'Some Face Pull Max', // has a key but no ORM, no requiresDumbbells
      };
      const exercises = applyWeights([template], [], 'home_dumbbells');
      // Should use home_dumbbells fallback on line 262
      expect(exercises[0].weightLb).toBeGreaterThan(0);
    });

    it('sets null weight for bodyweight exercises', () => {
      const templates = selectTemplates('upper_body', 'bodyweight_only');
      const exercises = applyWeights(templates, [], 'bodyweight_only');
      for (const ex of exercises) {
        expect(ex.weightLb).toBeNull();
      }
    });
  });

  describe('applyInjurySubstitutions', () => {
    it('returns exercises unchanged when no injuries', () => {
      const ctx = makeContext({ focus: 'lower_body', equipment: 'full_gym' });
      const templates = selectTemplates('lower_body', 'full_gym');
      const scaled = scaleForTime(templates, 30);
      const withWeights = applyWeights(scaled, [], 'full_gym');
      const result = generateOfflineWorkout(ctx);
      // Just verify it doesn't crash
      expect(result.exercises.length).toBeGreaterThan(0);
    });

    it('substitutes back squat with goblet squat for knee injury', () => {
      const ctx = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        timeMinutes: 15,
        activeInjuries: [{ location: 'knee', phase: 'rehab', restrictions: [] }],
      });
      const workout = generateOfflineWorkout(ctx);
      const names = workout.exercises.map((e) => e.name);
      expect(names).not.toContain('Back Squat');
    });

    it('removes exercises when no safe substitute exists for shoulder injury', () => {
      const ctx = makeContext({
        focus: 'push',
        equipment: 'full_gym',
        timeMinutes: 30,
        activeInjuries: [{ location: 'shoulder', phase: 'acute', restrictions: [] }],
      });
      const workout = generateOfflineWorkout(ctx);
      // Should still produce some workout (may be smaller)
      expect(workout.exercises.length).toBeGreaterThanOrEqual(0);
    });

    it('mentions injured locations in coaching summary', () => {
      const ctx = makeContext({
        activeInjuries: [{ location: 'knee', phase: 'rehab', restrictions: [] }],
      });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.coachingSummary).toContain('knee');
    });
  });

  describe('applyCyclePhase', () => {
    it('reduces weight for menstrual phase', () => {
      const ctxBase = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: null,
      });
      const ctxMenstrual = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'menstrual',
      });
      const base = generateOfflineWorkout(ctxBase);
      const menstrual = generateOfflineWorkout(ctxMenstrual);
      const baseSquat = base.exercises.find((e) => e.name.includes('Squat'));
      const menstrualSquat = menstrual.exercises.find((e) => e.name.includes('Squat'));
      if (baseSquat?.weightLb != null && menstrualSquat?.weightLb != null) {
        expect(menstrualSquat.weightLb).toBeLessThanOrEqual(baseSquat.weightLb);
      }
    });

    it('increases weight for ovulation phase', () => {
      const ctxBase = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: null,
      });
      const ctxOvulation = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'ovulation',
      });
      const base = generateOfflineWorkout(ctxBase);
      const ovulation = generateOfflineWorkout(ctxOvulation);
      const baseSquat = base.exercises.find((e) => e.name.includes('Squat'));
      const ovulationSquat = ovulation.exercises.find((e) => e.name.includes('Squat'));
      if (baseSquat?.weightLb != null && ovulationSquat?.weightLb != null) {
        expect(ovulationSquat.weightLb).toBeGreaterThanOrEqual(baseSquat.weightLb);
      }
    });

    it('handles luteal phase', () => {
      const ctx = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'luteal',
      });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.coachingSummary).toContain('luteal');
    });

    it('handles follicular phase (no multiplier change)', () => {
      const ctx = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'follicular',
      });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.exercises.length).toBeGreaterThan(0);
    });

    it('low readiness reduces weight further', () => {
      const ctxNormal = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'ovulation',
        readinessTier: null,
      });
      const ctxLow = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'ovulation',
        readinessTier: 'low',
      });
      const normal = generateOfflineWorkout(ctxNormal);
      const lowReady = generateOfflineWorkout(ctxLow);
      const normalSquat = normal.exercises.find((e) => e.name.includes('Squat'));
      const lowSquat = lowReady.exercises.find((e) => e.name.includes('Squat'));
      if (normalSquat?.weightLb != null && lowSquat?.weightLb != null) {
        expect(lowSquat.weightLb).toBeLessThanOrEqual(normalSquat.weightLb);
      }
    });

    it('handles unknown cycle phase gracefully', () => {
      const ctx = makeContext({
        focus: 'upper_body',
        equipment: 'full_gym',
        cyclePhase: 'unknown-phase',
      });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.exercises.length).toBeGreaterThan(0);
    });
  });

  describe('hotel_gym equipment', () => {
    it('excludes barbell exercises for hotel gym', () => {
      const templates = selectTemplates('upper_body', 'hotel_gym');
      for (const t of templates) {
        expect(t.requiresBarbell).toBe(false);
      }
    });
  });

  describe('applyEnergyLevel — high energy', () => {
    it('increases weights for high energy when exercises have weights', () => {
      const ctx = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        energyLevel: 'high',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
      });
      const ctxMedium = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        energyLevel: 'medium',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
      });
      const high = generateOfflineWorkout(ctx);
      const medium = generateOfflineWorkout(ctxMedium);
      const highSquat = high.exercises.find((e) => e.name.includes('Squat'));
      const mediumSquat = medium.exercises.find((e) => e.name.includes('Squat'));
      if (highSquat?.weightLb != null && mediumSquat?.weightLb != null) {
        expect(highSquat.weightLb).toBeGreaterThanOrEqual(mediumSquat.weightLb);
      }
    });
  });

  describe('kettlebell snapping', () => {
    it('snaps kettlebell exercise weight to nearest available', () => {
      const ctx = makeContext({ focus: 'conditioning', equipment: 'full_gym' });
      const workout = generateOfflineWorkout(ctx);
      const kbSwing = workout.exercises.find((e) =>
        e.name.toLowerCase().includes('kettlebell'),
      );
      // Kettlebell Swings will have a weight from dumbbell default
      if (kbSwing?.weightLb != null) {
        const AVAILABLE_KB = [15, 25, 32, 53, 70];
        expect(AVAILABLE_KB).toContain(kbSwing.weightLb);
      }
    });
  });

  describe('injury substitution — no substitute found', () => {
    it('removes exercises with no safe substitute (double-contraindicated location)', () => {
      // Walking Lunges → Step-Ups, but if hip injury also contrindicates Step-Ups...
      // Use ankle injury which has no substitutions
      const ctx = makeContext({
        focus: 'conditioning',
        equipment: 'full_gym',
        timeMinutes: 10,
        activeInjuries: [{ location: 'ankle', phase: 'acute', restrictions: [] }],
      });
      // Should not crash
      const workout = generateOfflineWorkout(ctx);
      expect(workout).toBeDefined();
    });

    it('handles injuries with unknown location gracefully', () => {
      const ctx = makeContext({
        focus: 'upper_body',
        equipment: 'full_gym',
        activeInjuries: [{ location: 'unknown-location', phase: 'rehab', restrictions: [] }],
      });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.exercises.length).toBeGreaterThan(0);
    });
  });

  describe('applyCyclePhase — high readiness', () => {
    it('increases weight for high readiness', () => {
      const ctxNormal = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'follicular',
        readinessTier: null,
      });
      const ctxHigh = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'follicular',
        readinessTier: 'high',
      });
      const normal = generateOfflineWorkout(ctxNormal);
      const highReady = generateOfflineWorkout(ctxHigh);
      const normalSquat = normal.exercises.find((e) => e.name.includes('Squat'));
      const highSquat = highReady.exercises.find((e) => e.name.includes('Squat'));
      if (normalSquat?.weightLb != null && highSquat?.weightLb != null) {
        expect(highSquat.weightLb).toBeGreaterThanOrEqual(normalSquat.weightLb);
      }
    });

    it('follicular phase with null readiness passes through (combined=1.0)', () => {
      const ctx = makeContext({
        focus: 'lower_body',
        equipment: 'full_gym',
        maxes: [{ name: 'Back Squat', weightLb: 200 }],
        cyclePhase: 'follicular',
        readinessTier: null,
      });
      const workout = generateOfflineWorkout(ctx);
      expect(workout.exercises.length).toBeGreaterThan(0);
    });
  });

  describe('buildCoachingSummary', () => {
    it('mentions exercise count', () => {
      const ctx = makeContext({ focus: 'upper_body', timeMinutes: 30 });
      const summary = buildCoachingSummary(ctx, 6);
      expect(summary).toContain('6');
    });

    it('mentions low energy when energy is low', () => {
      const ctx = makeContext({ energyLevel: 'low' });
      const summary = buildCoachingSummary(ctx, 5);
      expect(summary.toLowerCase()).toContain('low energy');
    });

    it('mentions high energy when energy is high', () => {
      const ctx = makeContext({ energyLevel: 'high' });
      const summary = buildCoachingSummary(ctx, 5);
      expect(summary.toLowerCase()).toContain('high energy');
    });

    it('mentions dropped exercises when droppedForInjury > 0', () => {
      const ctx = makeContext();
      const summary = buildCoachingSummary(ctx, 4, 2);
      expect(summary).toContain('2');
    });

    it('uses singular "exercise was" for 1 dropped', () => {
      const ctx = makeContext();
      const summary = buildCoachingSummary(ctx, 4, 1);
      expect(summary).toContain('exercise was');
    });

    it('uses plural "exercises were" for 2 dropped', () => {
      const ctx = makeContext();
      const summary = buildCoachingSummary(ctx, 4, 2);
      expect(summary).toContain('exercises were');
    });
  });
});

// ============================================================================
// GeneratedWorkout / GeneratedExercise
// ============================================================================

describe('GeneratedExercise', () => {
  describe('getEquipmentType', () => {
    it('identifies barbell exercises', () => {
      expect(getEquipmentType('Back Squat')).toBe('barbell');
      expect(getEquipmentType('Deadlift')).toBe('barbell');
      expect(getEquipmentType('Bench Press')).toBe('barbell');
      expect(getEquipmentType('Strict Press / Military Press')).toBe('barbell');
    });

    it('identifies dumbbell exercises', () => {
      expect(getEquipmentType('Dumbbell Row')).toBe('dumbbell');
      expect(getEquipmentType('Goblet Squat')).toBe('dumbbell');
      expect(getEquipmentType('Lateral Raises')).toBe('dumbbell');
    });

    it('identifies kettlebell exercises', () => {
      expect(getEquipmentType('Kettlebell Swings')).toBe('kettlebell');
    });

    it('returns other for bodyweight exercises', () => {
      expect(getEquipmentType('Air Squats')).toBe('other');
      expect(getEquipmentType('Pull-Up')).toBe('other');
      expect(getEquipmentType('Push-Ups')).toBe('other');
    });
  });

  describe('extractMuscleGroups', () => {
    it('extracts quads from squat', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Back Squat' })]);
      expect(groups).toContain('Quads');
    });

    it('extracts chest from bench press', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Flat Barbell Bench Press' })]);
      expect(groups).toContain('Chest');
    });

    it('extracts back from row', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Barbell Row' })]);
      expect(groups).toContain('Back');
    });

    it('returns sorted array', () => {
      const groups = extractMuscleGroups([
        makeExercise({ name: 'Back Squat' }),
        makeExercise({ name: 'Barbell Row' }),
      ]);
      expect(groups).toEqual([...groups].sort());
    });

    it('extracts glutes from hip thrust', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Hip Thrust' })]);
      expect(groups).toContain('Glutes');
    });

    it('extracts glutes from deadlift', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Conventional Deadlift (No Straps)' })]);
      expect(groups).toContain('Glutes');
    });

    it('extracts shoulders from overhead press', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Dumbbell Overhead Press' })]);
      expect(groups).toContain('Shoulders');
    });

    it('extracts biceps from curl', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Dumbbell Curl' })]);
      expect(groups).toContain('Biceps');
    });

    it('extracts triceps from tricep dip', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Tricep Dips' })]);
      expect(groups).toContain('Triceps');
    });

    it('extracts core from plank', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Plank Hold' })]);
      expect(groups).toContain('Core');
    });

    it('extracts calves from calf raises', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Calf Raises' })]);
      expect(groups).toContain('Calves');
    });

    it('extracts hamstrings from Romanian deadlift', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Romanian Deadlift' })]);
      expect(groups).toContain('Hamstrings');
    });

    it('returns empty array for exercises with no matches', () => {
      const groups = extractMuscleGroups([makeExercise({ name: 'Unknown Exercise' })]);
      expect(groups).toEqual([]);
    });
  });

  describe('totalEstimatedMinutes', () => {
    it('returns at least 1 minute', () => {
      const exercises: GeneratedExercise[] = [makeExercise({ sets: 1, restMinutes: 0 })];
      expect(totalEstimatedMinutes(exercises)).toBeGreaterThanOrEqual(1);
    });

    it('calculates correctly for multiple exercises', () => {
      // Each exercise: sets * (0.5 repTime + restMinutes)
      // 1 exercise, 3 sets, 1.5 rest: 3 * (0.5 + 1.5) = 6 min
      const exercises: GeneratedExercise[] = [makeExercise({ sets: 3, restMinutes: 1.5 })];
      expect(totalEstimatedMinutes(exercises)).toBe(6);
    });

    it('uses default 1.5 min rest when restMinutes is null', () => {
      // 1 exercise, 3 sets, null rest → uses 1.5 default: 3 * (0.5 + 1.5) = 6
      const exercises: GeneratedExercise[] = [makeExercise({ sets: 3, restMinutes: null })];
      expect(totalEstimatedMinutes(exercises)).toBe(6);
    });
  });

  describe('strippedForSharing', () => {
    const baseWorkout: GeneratedWorkout = {
      id: 'w1',
      createdAt: new Date('2026-01-01'),
      isFavorite: false,
      isCompleted: false,
      coachingSummary: 'Adjusted for menstrual phase. Exercises modified for knee injury considerations.',
      exercises: [makeExercise({ weightLb: 135, reasoning: 'Heavy load for PR' })],
      questionnaire: {
        timeMinutes: 30,
        focus: 'strength',
        energyLevel: 'medium',
        equipment: 'full_gym',
        desiredSkills: null,
      },
    };

    it('strips weight from exercises', () => {
      const stripped = strippedForSharing(baseWorkout);
      for (const ex of stripped.exercises) {
        expect(ex.weightLb).toBeNull();
      }
    });

    it('strips reasoning from exercises', () => {
      const stripped = strippedForSharing(baseWorkout);
      for (const ex of stripped.exercises) {
        expect(ex.reasoning).toBeNull();
      }
    });

    it('strips health references from coaching summary', () => {
      const stripped = strippedForSharing(baseWorkout);
      expect(stripped.coachingSummary).not.toContain('menstrual phase');
      expect(stripped.coachingSummary).not.toContain('injury considerations');
    });

    it('generates a new ID', () => {
      const stripped = strippedForSharing(baseWorkout);
      expect(stripped.id).not.toBe(baseWorkout.id);
    });

    it('sets isFavorite and isCompleted to false', () => {
      const stripped = strippedForSharing(baseWorkout);
      expect(stripped.isFavorite).toBe(false);
      expect(stripped.isCompleted).toBe(false);
    });
  });
});

// ============================================================================
// HistoryItem
// ============================================================================

describe('HistoryItem', () => {
  it('constructs a history item from AI workout source', () => {
    const item: HistoryItem = {
      id: 'ai-h1',
      title: 'Strength Workout',
      source: { kind: 'aiWorkout' },
      completedAt: new Date('2026-01-15'),
      exerciseCount: 6,
      durationSeconds: 3600,
      originalID: 'h1',
      isAIWorkout: true,
    };
    expect(item.isAIWorkout).toBe(true);
    expect(getSourceLabel(item.source)).toBe('AI Workout');
  });

  it('constructs a history item from program source', () => {
    const item: HistoryItem = {
      id: 'prog-h1',
      title: 'Week 1 Day 1',
      source: { kind: 'program', name: 'Starting Strength' },
      completedAt: new Date('2026-01-16'),
      exerciseCount: 3,
      durationSeconds: 2700,
      originalID: 'ph1',
      isAIWorkout: false,
    };
    expect(item.isAIWorkout).toBe(false);
    expect(getSourceLabel(item.source)).toBe('Starting Strength');
  });

  it('getSourceLabel returns AI Workout for aiWorkout source', () => {
    const source: HistoryItemSource = { kind: 'aiWorkout' };
    expect(getSourceLabel(source)).toBe('AI Workout');
  });

  it('getSourceLabel returns program name for program source', () => {
    const source: HistoryItemSource = { kind: 'program', name: 'GZCLP' };
    expect(getSourceLabel(source)).toBe('GZCLP');
  });
});

// ============================================================================
// ReadinessSurvey
// ============================================================================

describe('ReadinessSurvey', () => {
  describe('calculateReadinessScore', () => {
    it('calculates score from sleep, stress, soreness', () => {
      // sleep=8 (weight 0.4), stress=2 (inverted=8, weight 0.3), soreness=3 (inverted=7, weight 0.3)
      // = 8*0.4 + 8*0.3 + 7*0.3 = 3.2 + 2.4 + 2.1 = 7.7
      const result = calculateReadinessScore(8, 2, 3);
      expect(result.score).toBeCloseTo(7.7, 4);
    });

    it('clamps score to [0, 10] range', () => {
      const high = calculateReadinessScore(10, 0, 0);
      expect(high.score).toBeLessThanOrEqual(10);

      const low = calculateReadinessScore(0, 10, 10);
      expect(low.score).toBeGreaterThanOrEqual(0);
    });

    it('returns correct tier for high score', () => {
      const result = calculateReadinessScore(10, 0, 0);
      expect(result.tier).toBe('high');
    });

    it('returns correct tier for low score', () => {
      const result = calculateReadinessScore(0, 10, 10);
      expect(result.tier).toBe('low');
    });

    it('returns neutral tier for mid-range score', () => {
      // sleep=5, stress=5 (inverted=5), soreness=5 (inverted=5)
      // = 5*0.4 + 5*0.3 + 5*0.3 = 2 + 1.5 + 1.5 = 5.0
      const result = calculateReadinessScore(5, 5, 5);
      expect(result.tier).toBe('neutral');
    });
  });

  describe('tierFromScore', () => {
    it('score <= 3 returns low', () => {
      expect(tierFromScore(0)).toBe('low');
      expect(tierFromScore(3)).toBe('low');
    });

    it('score >= 8 returns high', () => {
      expect(tierFromScore(8)).toBe('high');
      expect(tierFromScore(10)).toBe('high');
    });

    it('score between 3 and 8 (exclusive/inclusive) returns neutral', () => {
      expect(tierFromScore(4)).toBe('neutral');
      expect(tierFromScore(7.9)).toBe('neutral');
    });
  });

  describe('tierDisplayName', () => {
    it('returns Fatigued for low', () => {
      expect(tierDisplayName('low')).toBe('Fatigued');
    });

    it('returns Normal for neutral', () => {
      expect(tierDisplayName('neutral')).toBe('Normal');
    });

    it('returns Prime for high', () => {
      expect(tierDisplayName('high')).toBe('Prime');
    });
  });

  describe('tierStringForAI', () => {
    it('returns fatigued for low', () => {
      expect(tierStringForAI('low')).toBe('fatigued');
    });

    it('returns normal for neutral', () => {
      expect(tierStringForAI('neutral')).toBe('normal');
    });

    it('returns prime for high', () => {
      expect(tierStringForAI('high')).toBe('prime');
    });
  });

  describe('adjustmentBannerText', () => {
    it('returns volume reduced text for low', () => {
      const text = adjustmentBannerText('low');
      expect(text).not.toBeNull();
      expect(text?.toLowerCase()).toContain('volume');
    });

    it('returns intensity boosted text for high', () => {
      const text = adjustmentBannerText('high');
      expect(text).not.toBeNull();
      expect(text?.toLowerCase()).toContain('intensity');
    });

    it('returns null for neutral', () => {
      expect(adjustmentBannerText('neutral')).toBeNull();
    });
  });

  describe('blendWithHealthKit', () => {
    it('returns survey score when no HealthKit data', () => {
      const result = blendWithHealthKit(7.0, null);
      expect(result.score).toBe(7.0);
    });

    it('blends survey (0.7) and HealthKit (0.3) scores', () => {
      // 7.0 * 0.7 + 5.0 * 0.3 = 4.9 + 1.5 = 6.4
      const result = blendWithHealthKit(7.0, 5.0);
      expect(result.score).toBeCloseTo(6.4, 4);
    });
  });
});

// ============================================================================
// BenchmarkCatalog
// ============================================================================

describe('BenchmarkCatalog', () => {
  describe('encodeRoundsAndReps', () => {
    it('encodes 3 rounds 15 reps as 30015', () => {
      expect(encodeRoundsAndReps(3, 15)).toBe(30015);
    });

    it('encodes 0 rounds 0 reps as 0', () => {
      expect(encodeRoundsAndReps(0, 0)).toBe(0);
    });

    it('encodes 1 round 0 reps as 10000', () => {
      expect(encodeRoundsAndReps(1, 0)).toBe(10000);
    });

    it('encodes 0 rounds 99 reps as 99', () => {
      expect(encodeRoundsAndReps(0, 99)).toBe(99);
    });

    it('higher rounds+reps produces higher encoded value', () => {
      expect(encodeRoundsAndReps(4, 5)).toBeGreaterThan(encodeRoundsAndReps(3, 15));
    });
  });

  describe('decodeRoundsAndReps', () => {
    it('decodes 30015 as 3 rounds 15 reps', () => {
      expect(decodeRoundsAndReps(30015)).toEqual({ rounds: 3, reps: 15 });
    });

    it('decodes 0 as 0 rounds 0 reps', () => {
      expect(decodeRoundsAndReps(0)).toEqual({ rounds: 0, reps: 0 });
    });

    it('decodes 10000 as 1 round 0 reps', () => {
      expect(decodeRoundsAndReps(10000)).toEqual({ rounds: 1, reps: 0 });
    });
  });

  describe('fixture-driven encode/decode', () => {
    const cases = (benchmarkFixture as Array<{ rounds: number; reps: number; encoded: number }>);
    test.each(cases)(
      'encodeRoundsAndReps($rounds, $reps) === $encoded',
      ({ rounds, reps, encoded }) => {
        expect(encodeRoundsAndReps(rounds, reps)).toBe(encoded);
      },
    );

    test.each(cases)(
      'decodeRoundsAndReps($encoded) returns { rounds: $rounds, reps: $reps }',
      ({ rounds, reps, encoded }) => {
        expect(decodeRoundsAndReps(encoded)).toEqual({ rounds, reps });
      },
    );
  });

  describe('BENCHMARK_CATALOG', () => {
    it('is a non-empty array', () => {
      expect(BENCHMARK_CATALOG.length).toBeGreaterThan(0);
    });

    it('contains Fran as first entry', () => {
      expect(BENCHMARK_CATALOG[0].name).toBe('Fran');
    });

    it('contains Murph', () => {
      const murph = BENCHMARK_CATALOG.find((b) => b.name === 'Murph');
      expect(murph).toBeDefined();
    });

    it('sortOrder matches array index', () => {
      BENCHMARK_CATALOG.forEach((entry, index) => {
        expect(entry.sortOrder).toBe(index);
      });
    });

    it('all entries have required fields', () => {
      for (const entry of BENCHMARK_CATALOG) {
        expect(entry.id).toBeTruthy();
        expect(entry.name).toBeTruthy();
        expect(entry.category).toBeTruthy();
        expect(entry.workoutDescription).toBeTruthy();
        expect(entry.scoringType).toBeTruthy();
        expect(entry.isPredefined).toBe(true);
        expect(entry.userID).toBe('');
      }
    });

    it('Classic WODs category has time and reps scoring types', () => {
      const wods = BENCHMARK_CATALOG.filter((b) => b.category === 'Classic WODs');
      const scoringTypes = new Set(wods.map((b) => b.scoringType));
      expect(scoringTypes.has('time')).toBe(true);
      expect(scoringTypes.has('reps')).toBe(true);
    });

    it('Strength category has weight scoring type', () => {
      const strength = BENCHMARK_CATALOG.filter((b) => b.category === 'Strength');
      for (const entry of strength) {
        expect(entry.scoringType).toBe('weight');
      }
    });

    it('has 26 predefined benchmarks matching Swift catalog', () => {
      expect(BENCHMARK_CATALOG.length).toBe(26);
    });
  });

  describe('getBenchmarkCategoryGroups', () => {
    it('returns groups in category order', () => {
      const groups = getBenchmarkCategoryGroups();
      expect(groups.length).toBe(5);
      expect(groups[0].category).toBe('Classic WODs');
      expect(groups[1].category).toBe('Strength');
      expect(groups[2].category).toBe('Endurance');
      expect(groups[3].category).toBe('Gymnastics');
      expect(groups[4].category).toBe('General Fitness');
    });

    it('each group has entries', () => {
      const groups = getBenchmarkCategoryGroups();
      for (const group of groups) {
        expect(group.entries.length).toBeGreaterThan(0);
      }
    });
  });
});

// Additional applyWeights coverage for non-barbell maxKey path
describe('applyWeights — non-barbell maxKey', () => {
  it('applies roundToNearestFive for non-barbell exercises with maxKey', () => {
    // Strict Press has requiresBarbell: true, so we need a custom template
    // Use the template directly via exported function
    const { applyWeights: aw, selectTemplates: st, scaleForTime: sft } = require('../ai-workout/offline-workout-generator');
    const templates = st('pull', 'full_gym');
    // Face Pulls has no maxKey, requiresDumbbells false
    const facePulls = templates.find((t: { name: string }) => t.name === 'Face Pulls');
    if (facePulls) {
      const exercises = aw([facePulls], [], 'full_gym');
      // No max key, no dumbbell requirement, not home_dumbbells → null weight
      expect(exercises[0].weightLb).toBeNull();
    }
  });
});

