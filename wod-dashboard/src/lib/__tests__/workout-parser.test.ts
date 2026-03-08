import { parseWorkoutText } from '../workout-parser';

describe('parseWorkoutText', () => {
  describe('template type detection', () => {
    it('detects strength by default', () => {
      const result = parseWorkoutText('5x5 back squat 75%');
      expect(result.templateType).toBe('strength');
    });

    it('detects AMRAP', () => {
      const result = parseWorkoutText('AMRAP 12 min: 10 KB swings, 15 box jumps');
      expect(result.templateType).toBe('amrap');
      expect(result.timeCap).toBe(12);
    });

    it('detects EMOM', () => {
      const result = parseWorkoutText('EMOM 20: 5 cleans, 10 burpees');
      expect(result.templateType).toBe('emom');
      expect(result.timeCap).toBe(20);
    });

    it('detects For Time', () => {
      const result = parseWorkoutText('For time: 21-15-9 thrusters and pull-ups');
      expect(result.templateType).toBe('forTime');
    });
  });

  describe('exercise parsing', () => {
    it('parses sets x reps format', () => {
      const result = parseWorkoutText('5x5 back squat 75%');
      expect(result.exercises[0].sets).toBe(5);
      expect(result.exercises[0].reps).toBe(5);
      expect(result.exercises[0].percent1RM).toBe(0.75);
    });

    it('parses multiple exercises', () => {
      const result = parseWorkoutText('3x10 RDL 60%, 3x12 leg press, 3x60s plank');
      expect(result.exercises).toHaveLength(3);
    });

    it('matches exercise names case-insensitively', () => {
      const result = parseWorkoutText('5x5 BACK SQUAT');
      expect(result.exercises[0].exercise).toBe('Back Squat');
    });

    it('handles common abbreviations', () => {
      const result = parseWorkoutText('3x10 RDL');
      expect(result.exercises[0].exercise).toBe('Romanian Deadlift');
    });
  });
});
