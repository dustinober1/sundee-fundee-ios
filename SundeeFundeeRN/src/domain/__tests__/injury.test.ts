/**
 * Injury domain — parity tests.
 * Written RED-first (TDD). All tests must fail before implementation exists.
 *
 * Coverage target: 100% on src/domain/injury/**
 */

// ---------------------------------------------------------------------------
// Imports — will fail until implementations exist
// ---------------------------------------------------------------------------

import {
  phaseIndex,
  isMoreRestrictive,
  nextPhase,
} from '../injury/recovery-phase';

import {
  BODY_LOCATIONS,
  bodyLocationDisplayName,
  parseRegions,
  encodeRegions,
  bodyLocationEngineKeyFromRegion,
} from '../injury/body-location';

import {
  getLoadMultipliers,
  adjustExerciseValue,
  adjustLoad,
} from '../injury/load-adjustment-policy';

import { analyzeTrend } from '../injury/pain-trend-analyzer';

import {
  meetsThreshold,
  evaluateTransition,
} from '../injury/phase-transition-advisor';

import {
  mostRestrictive,
  adaptProgram,
  buildRecoveryPrepBlock,
} from '../injury/injury-adaptation-engine';

import { generateSession } from '../injury/rehab-session-generator';

// Barrel re-export smoke test
import * as InjuryDomain from '../injury/index';

import type { RecoveryPhase, PainLog, InjuryProfile, Program, ProgramSession, ProgramExercise } from '../types';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makePainLog(painLevel: number, daysAgo = 0): PainLog {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return { date, painLevel, injuryId: 'inj-1' };
}

function makeInjury(
  bodyLocation: InjuryProfile['bodyLocation'],
  recoveryPhase: RecoveryPhase,
  location?: string
): InjuryProfile {
  return {
    id: 'inj-1',
    bodyLocation,
    recoveryPhase,
    injuryDate: new Date(),
    location: location ?? bodyLocation,
  };
}

function makeExercise(name: string): ProgramExercise {
  return {
    id: name,
    name,
    sets: 3,
    reps: { kind: 'fixed', value: 8 },
  };
}

function makeSession(exercises: ProgramExercise[]): ProgramSession {
  return { id: 'session-1', name: 'Test Session', exercises };
}

function makeProgram(exercises: ProgramExercise[]): Program {
  return {
    id: 'prog-1',
    name: 'Test Program',
    sessions: [makeSession(exercises)],
  };
}

// ---------------------------------------------------------------------------
// RecoveryPhase helpers
// ---------------------------------------------------------------------------

describe('RecoveryPhase helpers', () => {
  test('phaseIndex acute = 0', () => {
    expect(phaseIndex('acute')).toBe(0);
  });

  test('phaseIndex rehab = 1', () => {
    expect(phaseIndex('rehab')).toBe(1);
  });

  test('phaseIndex lightLoad = 2', () => {
    expect(phaseIndex('lightLoad')).toBe(2);
  });

  test('phaseIndex returnToPlay = 3', () => {
    expect(phaseIndex('returnToPlay')).toBe(3);
  });

  test('phaseIndex resolved = 4', () => {
    expect(phaseIndex('resolved')).toBe(4);
  });

  test('isMoreRestrictive(acute, rehab) = true', () => {
    expect(isMoreRestrictive('acute', 'rehab')).toBe(true);
  });

  test('isMoreRestrictive(rehab, acute) = false', () => {
    expect(isMoreRestrictive('rehab', 'acute')).toBe(false);
  });

  test('isMoreRestrictive(resolved, resolved) = false', () => {
    expect(isMoreRestrictive('resolved', 'resolved')).toBe(false);
  });

  test('isMoreRestrictive(lightLoad, returnToPlay) = true', () => {
    expect(isMoreRestrictive('lightLoad', 'returnToPlay')).toBe(true);
  });

  test('nextPhase returns next in sequence', () => {
    expect(nextPhase('acute')).toBe('rehab');
    expect(nextPhase('rehab')).toBe('lightLoad');
    expect(nextPhase('lightLoad')).toBe('returnToPlay');
    expect(nextPhase('returnToPlay')).toBe('resolved');
    expect(nextPhase('resolved')).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// BodyLocation helpers
// ---------------------------------------------------------------------------

describe('BodyLocation helpers', () => {
  test('BODY_LOCATIONS contains all 17 regions', () => {
    expect(BODY_LOCATIONS).toHaveLength(17);
    expect(BODY_LOCATIONS).toContain('head');
    expect(BODY_LOCATIONS).toContain('neck');
    expect(BODY_LOCATIONS).toContain('leftShoulder');
    expect(BODY_LOCATIONS).toContain('rightShoulder');
    expect(BODY_LOCATIONS).toContain('chest');
    expect(BODY_LOCATIONS).toContain('upperBack');
    expect(BODY_LOCATIONS).toContain('lowerBack');
    expect(BODY_LOCATIONS).toContain('leftElbow');
    expect(BODY_LOCATIONS).toContain('rightElbow');
    expect(BODY_LOCATIONS).toContain('leftWrist');
    expect(BODY_LOCATIONS).toContain('rightWrist');
    expect(BODY_LOCATIONS).toContain('leftHip');
    expect(BODY_LOCATIONS).toContain('rightHip');
    expect(BODY_LOCATIONS).toContain('leftKnee');
    expect(BODY_LOCATIONS).toContain('rightKnee');
    expect(BODY_LOCATIONS).toContain('leftAnkle');
    expect(BODY_LOCATIONS).toContain('rightAnkle');
  });

  test('bodyLocationDisplayName returns correct display names', () => {
    expect(bodyLocationDisplayName('head')).toBe('Head');
    expect(bodyLocationDisplayName('leftShoulder')).toBe('Left Shoulder');
    expect(bodyLocationDisplayName('rightKnee')).toBe('Right Knee');
    expect(bodyLocationDisplayName('lowerBack')).toBe('Lower Back');
    expect(bodyLocationDisplayName('leftAnkle')).toBe('Left Ankle');
  });

  test('parseRegions round-trips correctly', () => {
    const raw = 'leftKnee,rightShoulder,lowerBack';
    const parsed = parseRegions(raw);
    expect(parsed).toEqual(['leftKnee', 'rightShoulder', 'lowerBack']);
  });

  test('parseRegions trims whitespace', () => {
    const parsed = parseRegions('leftKnee, rightShoulder, lowerBack');
    expect(parsed).toEqual(['leftKnee', 'rightShoulder', 'lowerBack']);
  });

  test('parseRegions ignores unknown values', () => {
    const parsed = parseRegions('leftKnee,unknown,rightShoulder');
    expect(parsed).toEqual(['leftKnee', 'rightShoulder']);
  });

  test('encodeRegions produces comma-separated string', () => {
    const encoded = encodeRegions(['leftKnee', 'rightShoulder']);
    expect(encoded).toBe('leftKnee,rightShoulder');
  });

  test('parse/encode round-trip preserves values', () => {
    const original = ['leftKnee', 'rightShoulder', 'lowerBack'] as const;
    const encoded = encodeRegions([...original]);
    const parsed = parseRegions(encoded);
    expect(parsed).toEqual([...original]);
  });

  test('bodyLocationEngineKeyFromRegion maps correctly', () => {
    expect(bodyLocationEngineKeyFromRegion('head')).toBe('back');
    expect(bodyLocationEngineKeyFromRegion('neck')).toBe('back');
    expect(bodyLocationEngineKeyFromRegion('leftShoulder')).toBe('shoulder');
    expect(bodyLocationEngineKeyFromRegion('rightShoulder')).toBe('shoulder');
    expect(bodyLocationEngineKeyFromRegion('chest')).toBe('shoulder');
    expect(bodyLocationEngineKeyFromRegion('upperBack')).toBe('back');
    expect(bodyLocationEngineKeyFromRegion('lowerBack')).toBe('back');
    expect(bodyLocationEngineKeyFromRegion('leftElbow')).toBe('wrist');
    expect(bodyLocationEngineKeyFromRegion('rightElbow')).toBe('wrist');
    expect(bodyLocationEngineKeyFromRegion('leftWrist')).toBe('wrist');
    expect(bodyLocationEngineKeyFromRegion('rightWrist')).toBe('wrist');
    expect(bodyLocationEngineKeyFromRegion('leftHip')).toBe('hip');
    expect(bodyLocationEngineKeyFromRegion('rightHip')).toBe('hip');
    expect(bodyLocationEngineKeyFromRegion('leftKnee')).toBe('knee');
    expect(bodyLocationEngineKeyFromRegion('rightKnee')).toBe('knee');
    expect(bodyLocationEngineKeyFromRegion('leftAnkle')).toBe('ankle');
    expect(bodyLocationEngineKeyFromRegion('rightAnkle')).toBe('ankle');
  });
});

// ---------------------------------------------------------------------------
// LoadAdjustmentPolicy
// ---------------------------------------------------------------------------

describe('LoadAdjustmentPolicy', () => {
  test('acute: all multipliers are 0', () => {
    const m = getLoadMultipliers('acute');
    expect(m.load).toBe(0.0);
    expect(m.sets).toBe(0.0);
    expect(m.reps).toBe(0.0);
  });

  test('resolved: all multipliers are 1.0', () => {
    const m = getLoadMultipliers('resolved');
    expect(m.load).toBe(1.0);
    expect(m.sets).toBe(1.0);
    expect(m.reps).toBe(1.0);
  });

  test('rehab multipliers', () => {
    const m = getLoadMultipliers('rehab');
    expect(m.load).toBeCloseTo(0.30);
    expect(m.sets).toBeCloseTo(0.50);
    expect(m.reps).toBeCloseTo(0.70);
  });

  test('lightLoad multipliers', () => {
    const m = getLoadMultipliers('lightLoad');
    expect(m.load).toBeCloseTo(0.50);
    expect(m.sets).toBeCloseTo(0.75);
    expect(m.reps).toBeCloseTo(0.85);
  });

  test('returnToPlay multipliers', () => {
    const m = getLoadMultipliers('returnToPlay');
    expect(m.load).toBeCloseTo(0.80);
    expect(m.sets).toBeCloseTo(0.90);
    expect(m.reps).toBeCloseTo(1.0);
  });

  test('adjustExerciseValue fixed scales and clamps to min 1', () => {
    const result = adjustExerciseValue({ kind: 'fixed', value: 10 }, 0.5);
    expect(result).toEqual({ kind: 'fixed', value: 5 });
  });

  test('adjustExerciseValue fixed rounds using swiftRound', () => {
    const result = adjustExerciseValue({ kind: 'fixed', value: 3 }, 0.7);
    // 3 * 0.7 = 2.1 → rounds to 2
    expect(result).toEqual({ kind: 'fixed', value: 2 });
  });

  test('adjustExerciseValue fixed clamps to min 1', () => {
    const result = adjustExerciseValue({ kind: 'fixed', value: 1 }, 0.0);
    expect(result).toEqual({ kind: 'fixed', value: 1 });
  });

  test('adjustExerciseValue range scales both ends', () => {
    const result = adjustExerciseValue({ kind: 'range', lo: 4, hi: 8 }, 0.5);
    expect(result).toEqual({ kind: 'range', lo: 2, hi: 4 });
  });

  test('adjustExerciseValue amrap passes through', () => {
    const result = adjustExerciseValue({ kind: 'amrap' }, 0.5);
    expect(result).toEqual({ kind: 'amrap' });
  });

  test('adjustExerciseValue text passes through', () => {
    const result = adjustExerciseValue({ kind: 'text', value: 'max' }, 0.5);
    expect(result).toEqual({ kind: 'text', value: 'max' });
  });

  test('adjustLoad returns null when load is undefined', () => {
    expect(adjustLoad(undefined, 0.5)).toBeNull();
  });

  test('adjustLoad scales the value', () => {
    expect(adjustLoad(0.80, 0.5)).toBeCloseTo(0.40);
  });
});

// ---------------------------------------------------------------------------
// PainTrendAnalyzer
// ---------------------------------------------------------------------------

describe('PainTrendAnalyzer — analyzeTrend', () => {
  test('empty logs returns {trailingAverage:0, isImproving:false, latestPainLevel:null, readingCount:0}', () => {
    const result = analyzeTrend([]);
    expect(result.trailingAverage).toBe(0);
    expect(result.isImproving).toBe(false);
    expect(result.latestPainLevel).toBeNull();
    expect(result.readingCount).toBe(0);
  });

  test('single log: isImproving=false, trailingAverage=pain level', () => {
    const result = analyzeTrend([makePainLog(6)]);
    expect(result.trailingAverage).toBe(6);
    expect(result.isImproving).toBe(false);
    expect(result.latestPainLevel).toBe(6);
    expect(result.readingCount).toBe(1);
  });

  test('decreasing pain values (newest first) → isImproving: true', () => {
    // Newest first: 2, 3, 5, 7 — newer half avg (2,3)=2.5 < older half avg (5,7)=6
    const logs = [2, 3, 5, 7].map((p, i) => makePainLog(p, i));
    const result = analyzeTrend(logs);
    expect(result.isImproving).toBe(true);
  });

  test('increasing pain values (newest first) → isImproving: false', () => {
    // Newest first: 7, 5, 3, 2 — newer half avg (7,5)=6 > older half avg (3,2)=2.5
    const logs = [7, 5, 3, 2].map((p, i) => makePainLog(p, i));
    const result = analyzeTrend(logs);
    expect(result.isImproving).toBe(false);
  });

  test('trailingAverage is computed over windowSize logs only', () => {
    // 7 logs: [1,1,1,1,9,9,9], window=4 → avg of first 4 = 1.0
    const logs = [1, 1, 1, 1, 9, 9, 9].map((p, i) => makePainLog(p, i));
    const result = analyzeTrend(logs, 4);
    expect(result.trailingAverage).toBe(1.0);
  });

  test('Swift prefix/suffix split: odd count drops middle element for halves', () => {
    // 5 logs newest first: [2, 3, 5, 7, 9]
    // halfSize = 5/2 = 2
    // newerHalf = prefix(2) = [2,3], olderHalf = suffix(2) = [7,9]
    // newerAvg = 2.5, olderAvg = 8.0 → isImproving = true
    const logs = [2, 3, 5, 7, 9].map((p, i) => makePainLog(p, i));
    const result = analyzeTrend(logs, 5);
    expect(result.isImproving).toBe(true);
  });

  test('readingCount reflects total logs (not window)', () => {
    const logs = [3, 4, 5, 6, 7, 8].map((p, i) => makePainLog(p, i));
    const result = analyzeTrend(logs, 4);
    expect(result.readingCount).toBe(6);
  });

  test('latestPainLevel is the first (newest) log', () => {
    const logs = [2, 5, 8].map((p, i) => makePainLog(p, i));
    const result = analyzeTrend(logs);
    expect(result.latestPainLevel).toBe(2);
  });
});

// ---------------------------------------------------------------------------
// PhaseTransitionAdvisor
// ---------------------------------------------------------------------------

describe('PhaseTransitionAdvisor — meetsThreshold', () => {
  test('returns false when fewer than count logs', () => {
    const logs = [makePainLog(3), makePainLog(4)];
    expect(meetsThreshold(logs, 3, 5)).toBe(false);
  });

  test('returns true when all N logs <= maxPain', () => {
    const logs = [makePainLog(3), makePainLog(4), makePainLog(5)];
    expect(meetsThreshold(logs, 3, 5)).toBe(true);
  });

  test('returns false when any of the N logs > maxPain', () => {
    const logs = [makePainLog(6), makePainLog(4), makePainLog(5)];
    expect(meetsThreshold(logs, 3, 5)).toBe(false);
  });

  test('only checks first N logs, ignores extras', () => {
    // First 3 pass threshold, 4th would fail but is ignored
    const logs = [makePainLog(2), makePainLog(3), makePainLog(4), makePainLog(8)];
    expect(meetsThreshold(logs, 3, 5)).toBe(true);
  });

  test('empty logs returns false', () => {
    expect(meetsThreshold([], 3, 5)).toBe(false);
  });
});

describe('PhaseTransitionAdvisor — evaluateTransition', () => {
  test('acute → rehab: 3 logs at pain <= 5', () => {
    const logs = [makePainLog(5), makePainLog(4), makePainLog(3)];
    const result = evaluateTransition('inj-1', 'acute', logs);
    expect(result).not.toBeNull();
    expect(result?.suggestedPhase).toBe('rehab');
    expect(result?.currentPhase).toBe('acute');
    expect(result?.injuryId).toBe('inj-1');
  });

  test('acute: no suggestion when pain > 5 in recent logs', () => {
    const logs = [makePainLog(6), makePainLog(4), makePainLog(3)];
    expect(evaluateTransition('inj-1', 'acute', logs)).toBeNull();
  });

  test('rehab → lightLoad: 3 logs at pain <= 3', () => {
    const logs = [makePainLog(2), makePainLog(3), makePainLog(1)];
    const result = evaluateTransition('inj-1', 'rehab', logs);
    expect(result?.suggestedPhase).toBe('lightLoad');
  });

  test('rehab: no suggestion when pain > 3', () => {
    const logs = [makePainLog(4), makePainLog(2), makePainLog(3)];
    expect(evaluateTransition('inj-1', 'rehab', logs)).toBeNull();
  });

  test('lightLoad → returnToPlay: 3 logs at pain <= 2', () => {
    const logs = [makePainLog(1), makePainLog(2), makePainLog(0)];
    const result = evaluateTransition('inj-1', 'lightLoad', logs);
    expect(result?.suggestedPhase).toBe('returnToPlay');
  });

  test('lightLoad: no suggestion when pain > 2', () => {
    const logs = [makePainLog(3), makePainLog(1), makePainLog(2)];
    expect(evaluateTransition('inj-1', 'lightLoad', logs)).toBeNull();
  });

  test('returnToPlay → resolved: 5 logs at pain <= 1', () => {
    const logs = [makePainLog(0), makePainLog(1), makePainLog(0), makePainLog(1), makePainLog(0)];
    const result = evaluateTransition('inj-1', 'returnToPlay', logs);
    expect(result?.suggestedPhase).toBe('resolved');
  });

  test('returnToPlay: no suggestion when fewer than 5 logs', () => {
    const logs = [makePainLog(0), makePainLog(1), makePainLog(0), makePainLog(1)];
    expect(evaluateTransition('inj-1', 'returnToPlay', logs)).toBeNull();
  });

  test('resolved: always returns null', () => {
    const logs = [makePainLog(0), makePainLog(0), makePainLog(0), makePainLog(0), makePainLog(0)];
    expect(evaluateTransition('inj-1', 'resolved', logs)).toBeNull();
  });

  test('evaluateTransition considers only first 5 logs', () => {
    // 6 logs, first 5 are low pain, 6th is irrelevant
    const logs = [makePainLog(0), makePainLog(1), makePainLog(0), makePainLog(1), makePainLog(0), makePainLog(9)];
    const result = evaluateTransition('inj-1', 'returnToPlay', logs);
    expect(result?.suggestedPhase).toBe('resolved');
  });
});

// ---------------------------------------------------------------------------
// InjuryAdaptationEngine — mostRestrictive
// ---------------------------------------------------------------------------

describe('InjuryAdaptationEngine — mostRestrictive', () => {
  test('mostRestrictive([rehab, acute]) returns acute', () => {
    expect(mostRestrictive(['rehab', 'acute'])).toBe('acute');
  });

  test('mostRestrictive([resolved]) returns resolved', () => {
    expect(mostRestrictive(['resolved'])).toBe('resolved');
  });

  test('mostRestrictive([]) returns undefined', () => {
    expect(mostRestrictive([])).toBeUndefined();
  });

  test('mostRestrictive([lightLoad, returnToPlay, rehab]) returns rehab', () => {
    expect(mostRestrictive(['lightLoad', 'returnToPlay', 'rehab'])).toBe('rehab');
  });

  test('mostRestrictive([resolved, resolved]) returns resolved', () => {
    expect(mostRestrictive(['resolved', 'resolved'])).toBe('resolved');
  });

  test('mostRestrictive uses RECOVERY_PHASE_ORDER.indexOf for comparison', () => {
    // All 5 phases simultaneously
    const result = mostRestrictive(['returnToPlay', 'resolved', 'lightLoad', 'rehab', 'acute']);
    expect(result).toBe('acute');
  });
});

// ---------------------------------------------------------------------------
// InjuryAdaptationEngine — adaptProgram
// ---------------------------------------------------------------------------

describe('InjuryAdaptationEngine — adaptProgram', () => {
  test('resolved injury makes no modifications', () => {
    const program = makeProgram([makeExercise('Back Squat'), makeExercise('Bench Press')]);
    const injuries = [makeInjury('leftKnee', 'resolved', 'knee')];
    const result = adaptProgram(program, injuries);
    expect(result.sessions[0].exercises[0].name).toBe('Back Squat');
    expect(result.sessions[0].exercises[1].name).toBe('Bench Press');
  });

  test('no injuries returns program unchanged', () => {
    const program = makeProgram([makeExercise('Back Squat')]);
    const result = adaptProgram(program, []);
    expect(result.sessions[0].exercises[0].name).toBe('Back Squat');
  });

  test('shoulder injury in acute phase removes/replaces overhead press exercises', () => {
    const program = makeProgram([makeExercise('Strict Press / Military Press'), makeExercise('Bird-Dogs')]);
    const injuries = [makeInjury('leftShoulder', 'acute', 'shoulder')];
    const result = adaptProgram(program, injuries);
    // Strict Press should be replaced (contraindicated for shoulder)
    expect(result.sessions[0].exercises.some(e => e.name === 'Strict Press / Military Press')).toBe(false);
    // Bird-Dogs should remain unchanged
    expect(result.sessions[0].exercises.some(e => e.name === 'Bird-Dogs')).toBe(true);
  });

  test('knee injury in acute phase replaces squat exercises', () => {
    const program = makeProgram([makeExercise('Back Squat'), makeExercise('Deadlift')]);
    const injuries = [makeInjury('leftKnee', 'acute', 'knee')];
    const result = adaptProgram(program, injuries);
    // Back Squat should be replaced (contraindicated for knee)
    expect(result.sessions[0].exercises.some(e => e.name === 'Back Squat')).toBe(false);
  });

  test('multiple injuries applies most restrictive phase rules', () => {
    const program = makeProgram([makeExercise('Back Squat'), makeExercise('Strict Press / Military Press')]);
    const injuries = [
      makeInjury('leftKnee', 'acute', 'knee'),
      makeInjury('leftShoulder', 'lightLoad', 'shoulder'),
    ];
    const result = adaptProgram(program, injuries);
    // Both exercises should be replaced
    expect(result.sessions[0].exercises.some(e => e.name === 'Back Squat')).toBe(false);
    expect(result.sessions[0].exercises.some(e => e.name === 'Strict Press / Military Press')).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// InjuryAdaptationEngine — buildRecoveryPrepBlock
// ---------------------------------------------------------------------------

describe('InjuryAdaptationEngine — buildRecoveryPrepBlock', () => {
  test('returns knee exercises for knee injury', () => {
    const injuries = [makeInjury('leftKnee', 'rehab', 'knee')];
    const block = buildRecoveryPrepBlock(injuries);
    expect(block.length).toBeGreaterThan(0);
    const names = block.map(e => e.name);
    // Should include knee rehab exercises
    expect(names.some(n => ['Bird-Dogs', 'Bodyweight Lunges', 'Terminal Knee Extension', 'Straight Leg Raises'].includes(n))).toBe(true);
  });

  test('returns shoulder exercises for shoulder injury', () => {
    const injuries = [makeInjury('leftShoulder', 'rehab', 'shoulder')];
    const block = buildRecoveryPrepBlock(injuries);
    expect(block.length).toBeGreaterThan(0);
    const names = block.map(e => e.name);
    expect(names.some(n => ['Banded Pull-Aparts', 'Face Pulls', 'Wall Slides', 'Shoulder Circles'].includes(n))).toBe(true);
  });

  test('deduplicates exercises across multiple same-location injuries', () => {
    const injuries = [
      makeInjury('leftKnee', 'rehab', 'knee'),
      makeInjury('rightKnee', 'rehab', 'knee'),
    ];
    const block = buildRecoveryPrepBlock(injuries);
    const names = block.map(e => e.name);
    // No duplicates
    expect(names.length).toBe(new Set(names).size);
  });

  test('exercises have bodyweightOnly=true and sets=2, reps=10', () => {
    const injuries = [makeInjury('leftKnee', 'rehab', 'knee')];
    const block = buildRecoveryPrepBlock(injuries);
    block.forEach(ex => {
      expect(ex.bodyweightOnly).toBe(true);
      expect(ex.sets).toBe(2);
      expect(ex.reps).toEqual({ kind: 'fixed', value: 10 });
    });
  });
});

// ---------------------------------------------------------------------------
// RehabSessionGenerator — generateSession
// ---------------------------------------------------------------------------

describe('RehabSessionGenerator — generateSession', () => {
  test('returns null when no rehab/lightLoad injuries', () => {
    const injuries = [makeInjury('leftKnee', 'acute', 'knee')];
    expect(generateSession(injuries)).toBeNull();
  });

  test('returns null when injuries is empty', () => {
    expect(generateSession([])).toBeNull();
  });

  test('returns session for knee rehab phase', () => {
    const injuries = [makeInjury('leftKnee', 'rehab', 'knee')];
    const session = generateSession(injuries);
    expect(session).not.toBeNull();
    expect(session?.name).toBe('Rehab Session');
    const names = session?.exercises.map(e => e.name) ?? [];
    expect(names.some(n => ['Bird-Dogs', 'Bodyweight Lunges', 'Terminal Knee Extension', 'Straight Leg Raises'].includes(n))).toBe(true);
  });

  test('returns session for shoulder lightLoad phase', () => {
    const injuries = [makeInjury('leftShoulder', 'lightLoad', 'shoulder')];
    const session = generateSession(injuries);
    expect(session).not.toBeNull();
    const names = session?.exercises.map(e => e.name) ?? [];
    expect(names.some(n => ['Banded Pull-Aparts', 'Face Pulls', 'Wall Slides', 'Shoulder Circles'].includes(n))).toBe(true);
  });

  test('rehab phase exercises have sets=3, reps=12', () => {
    const injuries = [makeInjury('leftKnee', 'rehab', 'knee')];
    const session = generateSession(injuries);
    session?.exercises.forEach(ex => {
      expect(ex.sets).toBe(3);
      expect(ex.reps).toEqual({ kind: 'fixed', value: 12 });
    });
  });

  test('lightLoad phase exercises have sets=2, reps=15', () => {
    const injuries = [makeInjury('leftShoulder', 'lightLoad', 'shoulder')];
    const session = generateSession(injuries);
    session?.exercises.forEach(ex => {
      expect(ex.sets).toBe(2);
      expect(ex.reps).toEqual({ kind: 'fixed', value: 15 });
    });
  });

  test('session id starts with rehab-', () => {
    const injuries = [makeInjury('leftKnee', 'rehab', 'knee')];
    const session = generateSession(injuries);
    expect(session?.id).toMatch(/^rehab-/);
  });

  test('excludes resolved and acute injuries', () => {
    const injuries = [
      makeInjury('leftKnee', 'acute', 'knee'),
      makeInjury('leftShoulder', 'rehab', 'shoulder'),
      makeInjury('lowerBack', 'resolved', 'back'),
    ];
    const session = generateSession(injuries);
    expect(session).not.toBeNull();
    // Should only include shoulder exercises (not knee/back)
    const names = session?.exercises.map(e => e.name) ?? [];
    expect(names.some(n => ['Banded Pull-Aparts', 'Face Pulls', 'Wall Slides', 'Shoulder Circles'].includes(n))).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Barrel index re-export smoke test
// ---------------------------------------------------------------------------

describe('Barrel index re-exports', () => {
  test('adaptProgram is exported', () => {
    expect(InjuryDomain.adaptProgram).toBeDefined();
  });

  test('analyzeTrend is exported', () => {
    expect(InjuryDomain.analyzeTrend).toBeDefined();
  });

  test('evaluateTransition is exported', () => {
    expect(InjuryDomain.evaluateTransition).toBeDefined();
  });

  test('generateSession is exported', () => {
    expect(InjuryDomain.generateSession).toBeDefined();
  });

  test('mostRestrictive is exported', () => {
    expect(InjuryDomain.mostRestrictive).toBeDefined();
  });

  test('meetsThreshold is exported', () => {
    expect(InjuryDomain.meetsThreshold).toBeDefined();
  });

  test('phaseIndex is exported', () => {
    expect(InjuryDomain.phaseIndex).toBeDefined();
  });

  test('getLoadMultipliers is exported', () => {
    expect(InjuryDomain.getLoadMultipliers).toBeDefined();
  });
});
