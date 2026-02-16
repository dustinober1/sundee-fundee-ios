import { describe, expect, it } from 'vitest';
import { getAllPrograms, getProgramById } from '@/data/programs';

describe('ProgramV2 Loader', () => {
  it('loads the complete back squat program', () => {
    const programs = getAllPrograms();
    const program = programs.find(p => p.id === 'back-squat-complete-cycle');

    expect(program).toBeDefined();
    expect(program?.durationWeeks).toBe(8);
    expect(program?.sessionsPerWeek).toBe(3);
  });

  it('has three phases', () => {
    const program = getProgramById('back-squat-complete-cycle');
    expect(program?.phases).toHaveLength(3);
  });

  it('week 8 is marked as test week', () => {
    const program = getProgramById('back-squat-complete-cycle');
    const week8 = program?.weeks.find(week => week.week === 8);
    expect(week8?.isTestWeek).toBe(true);
  });

  it('week 1 has three sessions', () => {
    const program = getProgramById('back-squat-complete-cycle');
    const week1 = program?.weeks.find(week => week.week === 1);
    expect(week1?.sessions).toHaveLength(3);
  });

  it('test week has all warm-up and working singles', () => {
    const program = getProgramById('back-squat-complete-cycle');
    const week8 = program?.weeks.find(week => week.week === 8);
    const testSession = week8?.sessions.find(session => session.sessionType === 'testing');
    expect(testSession?.exercises).toHaveLength(8);
  });
});
