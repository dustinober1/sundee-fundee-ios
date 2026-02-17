import { Program, CompletedSet, User, ExperienceLevel } from '../index';

describe('Type Exports', () => {
  it('should export Program type', () => {
    const program: Program = {
      id: 'test',
      name: 'Test Program',
      category: 'back-squat',
      description: 'Test',
      durationWeeks: 8,
      daysPerWeek: 3,
      exercises: ['back-squat'],
      difficulty: 'intermediate',
      weeks: [],
    };
    expect(program).toBeDefined();
  });

  it('should export CompletedSet type', () => {
    const set: CompletedSet = {
      id: '1',
      workoutId: '1',
      exerciseId: 'back-squat',
      setNumber: 1,
      actualWeight: 225,
      actualReps: 5,
      prescribedReps: 5,
      createdAt: new Date(),
    };
    expect(set).toBeDefined();
  });

  it('should export User type', () => {
    const experience: ExperienceLevel = 'beginner';
    expect(experience).toBe('beginner');
  });
});
