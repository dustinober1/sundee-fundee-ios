/**
 * Workout Session Actions Tests
 * Tests for pure reducer-style session management functions.
 */

import {
  createSession,
  addExercise,
  removeExercise,
  addSet,
  removeSet,
  completeSet,
  reorderExercises,
} from '../workout-session';
import type { WorkoutSession, ActiveExercise, LoggedSet } from '../workout-session';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const testIdGen = (() => {
  let counter = 0;
  return () => `test-id-${++counter}`;
})();

function freshIdGen() {
  let counter = 0;
  return () => `id-${++counter}`;
}

// ---------------------------------------------------------------------------
// createSession
// ---------------------------------------------------------------------------

describe('createSession', () => {
  it('returns a session with a unique id', () => {
    const s1 = createSession();
    const s2 = createSession();
    expect(s1.id).toBeTruthy();
    expect(s2.id).toBeTruthy();
    expect(s1.id).not.toBe(s2.id);
  });

  it('returns a session with a startedAt ISO string', () => {
    const session = createSession();
    expect(session.startedAt).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
    expect(() => new Date(session.startedAt)).not.toThrow();
  });

  it('returns a session with empty exercises array', () => {
    const session = createSession();
    expect(session.exercises).toEqual([]);
  });

  it('accepts optional timerMode', () => {
    const session = createSession('forTime');
    expect(session.timerMode).toBe('forTime');
  });

  it('accepts optional timerConfig', () => {
    const session = createSession('amrap', { durationSeconds: 1200 });
    expect(session.timerConfig).toEqual({ durationSeconds: 1200 });
  });

  it('defaults timerMode to "none" when not provided', () => {
    const session = createSession();
    expect(session.timerMode).toBe('none');
  });
});

// ---------------------------------------------------------------------------
// addExercise
// ---------------------------------------------------------------------------

describe('addExercise', () => {
  it('appends exercise with 3 empty sets', () => {
    const session = createSession();
    const result = addExercise(session, {
      exerciseId: 'ex1',
      exerciseName: 'Bench Press',
      muscleGroup: 'Chest',
    });
    expect(result.exercises).toHaveLength(1);
    const ex = result.exercises[0];
    expect(ex.exerciseId).toBe('ex1');
    expect(ex.exerciseName).toBe('Bench Press');
    expect(ex.muscleGroup).toBe('Chest');
    expect(ex.sets).toHaveLength(3);
  });

  it('sets order = exercises.length (0 for first exercise)', () => {
    const session = createSession();
    const result = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Squat', muscleGroup: 'Legs' });
    expect(result.exercises[0].order).toBe(0);
  });

  it('sets order = exercises.length for subsequent exercises', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Squat', muscleGroup: 'Legs' });
    session = addExercise(session, { exerciseId: 'ex2', exerciseName: 'Deadlift', muscleGroup: 'Back' });
    expect(session.exercises[0].order).toBe(0);
    expect(session.exercises[1].order).toBe(1);
  });

  it('initial sets have completed: false and no completedAt', () => {
    const session = createSession();
    const result = addExercise(session, { exerciseId: 'ex1', exerciseName: 'OHP', muscleGroup: 'Shoulders' });
    for (const set of result.exercises[0].sets) {
      expect(set.completed).toBe(false);
      expect(set.completedAt).toBeUndefined();
    }
  });

  it('does not mutate the original session', () => {
    const session = createSession();
    const originalExCount = session.exercises.length;
    addExercise(session, { exerciseId: 'ex1', exerciseName: 'Press', muscleGroup: 'Shoulders' });
    expect(session.exercises.length).toBe(originalExCount);
  });
});

// ---------------------------------------------------------------------------
// removeExercise
// ---------------------------------------------------------------------------

describe('removeExercise', () => {
  it('removes the exercise with matching id', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Squat', muscleGroup: 'Legs' });
    session = addExercise(session, { exerciseId: 'ex2', exerciseName: 'Deadlift', muscleGroup: 'Back' });
    const idToRemove = session.exercises[0].id;
    const result = removeExercise(session, idToRemove);
    expect(result.exercises).toHaveLength(1);
    expect(result.exercises[0].exerciseId).toBe('ex2');
  });

  it('re-numbers order on remaining exercises', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'A', muscleGroup: 'Back' });
    session = addExercise(session, { exerciseId: 'ex2', exerciseName: 'B', muscleGroup: 'Chest' });
    session = addExercise(session, { exerciseId: 'ex3', exerciseName: 'C', muscleGroup: 'Legs' });

    const idToRemove = session.exercises[0].id;
    const result = removeExercise(session, idToRemove);

    expect(result.exercises).toHaveLength(2);
    expect(result.exercises[0].order).toBe(0);
    expect(result.exercises[1].order).toBe(1);
  });

  it('is a no-op if exerciseId does not exist', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Squat', muscleGroup: 'Legs' });
    const result = removeExercise(session, 'nonexistent-id');
    expect(result.exercises).toHaveLength(1);
  });

  it('does not mutate the original session', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Squat', muscleGroup: 'Legs' });
    const idToRemove = session.exercises[0].id;
    const originalCount = session.exercises.length;
    removeExercise(session, idToRemove);
    expect(session.exercises.length).toBe(originalCount);
  });
});

// ---------------------------------------------------------------------------
// addSet
// ---------------------------------------------------------------------------

describe('addSet', () => {
  it('appends a new empty LoggedSet to the exercise', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const exId = session.exercises[0].id;
    const result = addSet(session, exId);
    expect(result.exercises[0].sets).toHaveLength(4); // 3 initial + 1 added
  });

  it('new set has completed: false', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const exId = session.exercises[0].id;
    const result = addSet(session, exId);
    const newSet = result.exercises[0].sets[3];
    expect(newSet.completed).toBe(false);
    expect(newSet.completedAt).toBeUndefined();
  });

  it('does not mutate the original session', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const exId = session.exercises[0].id;
    const originalCount = session.exercises[0].sets.length;
    addSet(session, exId);
    expect(session.exercises[0].sets.length).toBe(originalCount);
  });
});

// ---------------------------------------------------------------------------
// removeSet
// ---------------------------------------------------------------------------

describe('removeSet', () => {
  it('removes the set with the specified id', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const ex = session.exercises[0];
    const setId = ex.sets[0].id;
    const result = removeSet(session, ex.id, setId);
    expect(result.exercises[0].sets).toHaveLength(2);
    expect(result.exercises[0].sets.find((s) => s.id === setId)).toBeUndefined();
  });

  it('is a no-op if set id does not exist', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const ex = session.exercises[0];
    const result = removeSet(session, ex.id, 'nonexistent-set');
    expect(result.exercises[0].sets).toHaveLength(3);
  });
});

// ---------------------------------------------------------------------------
// completeSet
// ---------------------------------------------------------------------------

describe('completeSet', () => {
  it('marks the set as completed with the provided weight and reps', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const ex = session.exercises[0];
    const setId = ex.sets[0].id;
    const result = completeSet(session, ex.id, setId, { weight: 185, reps: 5 });
    const completedSet = result.exercises[0].sets[0];
    expect(completedSet.completed).toBe(true);
    expect(completedSet.weight).toBe(185);
    expect(completedSet.reps).toBe(5);
  });

  it('records completedAt as a valid ISO string', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const ex = session.exercises[0];
    const setId = ex.sets[0].id;
    const result = completeSet(session, ex.id, setId, { weight: 135, reps: 10 });
    const completedSet = result.exercises[0].sets[0];
    expect(completedSet.completedAt).toBeDefined();
    expect(() => new Date(completedSet.completedAt!)).not.toThrow();
    expect(completedSet.completedAt).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
  });

  it('does not affect other sets in the exercise', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const ex = session.exercises[0];
    const setId = ex.sets[0].id;
    const result = completeSet(session, ex.id, setId, { weight: 185, reps: 5 });
    expect(result.exercises[0].sets[1].completed).toBe(false);
    expect(result.exercises[0].sets[2].completed).toBe(false);
  });

  it('does not mutate the original session', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'Bench', muscleGroup: 'Chest' });
    const ex = session.exercises[0];
    const setId = ex.sets[0].id;
    completeSet(session, ex.id, setId, { weight: 185, reps: 5 });
    expect(session.exercises[0].sets[0].completed).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// reorderExercises
// ---------------------------------------------------------------------------

describe('reorderExercises', () => {
  it('reorders exercises according to orderedIds', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'A', muscleGroup: 'Back' });
    session = addExercise(session, { exerciseId: 'ex2', exerciseName: 'B', muscleGroup: 'Chest' });
    session = addExercise(session, { exerciseId: 'ex3', exerciseName: 'C', muscleGroup: 'Legs' });

    const [id1, id2, id3] = session.exercises.map((e) => e.id);
    const result = reorderExercises(session, [id3, id1, id2]);

    expect(result.exercises[0].exerciseId).toBe('ex3');
    expect(result.exercises[1].exerciseId).toBe('ex1');
    expect(result.exercises[2].exerciseId).toBe('ex2');
  });

  it('updates order numbers after reorder', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'A', muscleGroup: 'Back' });
    session = addExercise(session, { exerciseId: 'ex2', exerciseName: 'B', muscleGroup: 'Chest' });
    session = addExercise(session, { exerciseId: 'ex3', exerciseName: 'C', muscleGroup: 'Legs' });

    const [id1, id2, id3] = session.exercises.map((e) => e.id);
    const result = reorderExercises(session, [id3, id1, id2]);

    expect(result.exercises[0].order).toBe(0);
    expect(result.exercises[1].order).toBe(1);
    expect(result.exercises[2].order).toBe(2);
  });

  it('does not mutate the original session', () => {
    let session = createSession();
    session = addExercise(session, { exerciseId: 'ex1', exerciseName: 'A', muscleGroup: 'Back' });
    session = addExercise(session, { exerciseId: 'ex2', exerciseName: 'B', muscleGroup: 'Chest' });

    const [id1, id2] = session.exercises.map((e) => e.id);
    const originalFirstId = session.exercises[0].id;
    reorderExercises(session, [id2, id1]);
    expect(session.exercises[0].id).toBe(originalFirstId);
  });
});
