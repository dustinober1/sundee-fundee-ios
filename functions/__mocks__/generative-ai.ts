// Mock for @google/genai

const MOCK_WORKOUT_RESPONSE = JSON.stringify({
  coachingSummary: 'Great workout tailored to your goals!',
  exercises: [
    {
      name: 'Barbell Back Squat',
      sets: 3,
      reps: '5',
      weightLb: 185,
      restMinutes: 3,
      notes: 'Focus on depth',
      reasoning: 'Primary lower body strength movement',
      bodyweightOnly: false,
    },
    {
      name: 'Romanian Deadlift',
      sets: 3,
      reps: '8',
      weightLb: 135,
      restMinutes: 2,
      notes: null,
      reasoning: 'Hamstring and posterior chain development',
      bodyweightOnly: false,
    },
  ],
});

export class GoogleGenAI {
  constructor(_config: { apiKey: string }) {}

  models = {
    generateContent: jest.fn().mockResolvedValue({
      text: MOCK_WORKOUT_RESPONSE,
    }),
  };
}
