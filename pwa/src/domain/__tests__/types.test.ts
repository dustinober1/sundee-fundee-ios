import {
  bodyLocationEngineKey,
  workoutFocusDisplayName,
  scaleExerciseValue,
  clamp,
  swiftRound,
  type BodyLocation,
  type BodyLocationEngineKey,
  type WorkoutFocus,
  type ExerciseValue,
} from '../types';

// ---------------------------------------------------------------------------
// bodyLocationEngineKey — all 17 BodyLocation values
// ---------------------------------------------------------------------------

describe('bodyLocationEngineKey', () => {
  test.each<[BodyLocation, BodyLocationEngineKey]>([
    ['head', 'back'],
    ['neck', 'back'],
    ['upperBack', 'back'],
    ['lowerBack', 'back'],
    ['leftShoulder', 'shoulder'],
    ['rightShoulder', 'shoulder'],
    ['chest', 'shoulder'],
    ['leftElbow', 'wrist'],
    ['rightElbow', 'wrist'],
    ['leftWrist', 'wrist'],
    ['rightWrist', 'wrist'],
    ['leftHip', 'hip'],
    ['rightHip', 'hip'],
    ['leftKnee', 'knee'],
    ['rightKnee', 'knee'],
    ['leftAnkle', 'ankle'],
    ['rightAnkle', 'ankle'],
  ])('%s → %s', (location, expected) => {
    expect(bodyLocationEngineKey(location)).toBe(expected);
  });
});

// ---------------------------------------------------------------------------
// workoutFocusDisplayName — all 12 WorkoutFocus values
// ---------------------------------------------------------------------------

describe('workoutFocusDisplayName', () => {
  test.each<[WorkoutFocus, string]>([
    ['upper_body', 'Upper Body'],
    ['lower_body', 'Lower Body'],
    ['full_body', 'Full Body'],
    ['push', 'Push'],
    ['pull', 'Pull'],
    ['core', 'Core'],
    ['conditioning', 'Conditioning'],
    ['strength', 'Strength'],
    ['olympic_lifts', 'Olympic Lifts'],
    ['gymnastics', 'Gymnastics'],
    ['mobility', 'Mobility'],
    ['stretching', 'Stretching'],
  ])('%s → %s', (focus, expected) => {
    expect(workoutFocusDisplayName(focus)).toBe(expected);
  });
});

// ---------------------------------------------------------------------------
// scaleExerciseValue — covers all four ExerciseValue kinds
// ---------------------------------------------------------------------------

describe('scaleExerciseValue', () => {
  test('scales fixed value by factor', () => {
    const ev: ExerciseValue = { kind: 'fixed', value: 100 };
    expect(scaleExerciseValue(ev, 0.9)).toEqual({ kind: 'fixed', value: 90 });
  });

  test('scales range lo and hi by factor', () => {
    const ev: ExerciseValue = { kind: 'range', lo: 10, hi: 20 };
    expect(scaleExerciseValue(ev, 1.1)).toEqual({ kind: 'range', lo: 11, hi: 22 });
  });

  test('passes amrap through unchanged', () => {
    const ev: ExerciseValue = { kind: 'amrap' };
    expect(scaleExerciseValue(ev, 0.5)).toEqual({ kind: 'amrap' });
  });

  test('passes text through unchanged', () => {
    const ev: ExerciseValue = { kind: 'text', value: 'max effort' };
    expect(scaleExerciseValue(ev, 2)).toEqual({ kind: 'text', value: 'max effort' });
  });
});

// ---------------------------------------------------------------------------
// clamp
// ---------------------------------------------------------------------------

describe('clamp', () => {
  test('returns value when within range', () => {
    expect(clamp(5, 0, 10)).toBe(5);
  });

  test('clamps to min', () => {
    expect(clamp(-1, 0, 10)).toBe(0);
  });

  test('clamps to max', () => {
    expect(clamp(11, 0, 10)).toBe(10);
  });
});

// ---------------------------------------------------------------------------
// swiftRound — half-away-from-zero rounding
// ---------------------------------------------------------------------------

describe('swiftRound', () => {
  test('rounds 2.5 to 3 (positive half rounds up)', () => {
    expect(swiftRound(2.5)).toBe(3);
  });

  test('rounds -2.5 to -3 (negative half rounds away from zero)', () => {
    expect(swiftRound(-2.5)).toBe(-3);
  });

  test('rounds 0 to 0', () => {
    expect(swiftRound(0)).toBe(0);
  });

  test('rounds 99.4 to 99', () => {
    expect(swiftRound(99.4)).toBe(99);
  });

  test('rounds 99.6 to 100', () => {
    expect(swiftRound(99.6)).toBe(100);
  });
});
