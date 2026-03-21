/**
 * Tests for generateAIWorkout Cloud Function (BACK-01)
 *
 * The jest moduleNameMapper in package.json routes:
 *   firebase-functions/v2/https  → __mocks__/firebase-functions.ts
 *   firebase-functions/params     → __mocks__/firebase-functions-params.ts
 *   @google/genai                 → __mocks__/generative-ai.ts
 *
 * When generateAIWorkout.ts is imported, all its dependencies are
 * automatically resolved to mocks. We capture the registered handler
 * via getLastHandler() from the mock.
 */

// Import the function module — this triggers onCall registration with the mock
import '../generateAIWorkout';

// Access the mock directly via require (bypasses TS type checking for test-internal mock API)
// eslint-disable-next-line @typescript-eslint/no-require-imports
const mockFunctions = require('../../__mocks__/firebase-functions') as {
  getLastHandler: () => ((request: MockRequest) => Promise<unknown>) | null;
};

type MockRequest = {
  auth: { uid: string; token?: Record<string, unknown> } | null;
  data: Record<string, unknown>;
};

function callHandler(request: MockRequest): Promise<unknown> {
  const handler = mockFunctions.getLastHandler();
  if (!handler) throw new Error('No handler registered — was generateAIWorkout imported?');
  return handler(request);
}

const validContext = {
  userID: 'uid-123',
  timeMinutes: 30,
  focus: 'full_body',
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
  weightUnit: 'lbs',
  desiredSkills: [],
  benchmarkSummaries: [],
  bodyWeightKg: null,
  recentPainActivity: [],
  workoutCompletionRate: null,
  travelModeEnabled: false,
};

describe('generateAIWorkout', () => {
  it('rejects unauthenticated calls with HttpsError code unauthenticated', async () => {
    await expect(
      callHandler({ auth: null, data: validContext })
    ).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('returns a workout with exercises array and coachingSummary string', async () => {
    const result = (await callHandler({
      auth: { uid: 'uid-123', token: {} },
      data: validContext,
    })) as Record<string, unknown>;

    expect(result).toHaveProperty('exercises');
    expect(Array.isArray(result.exercises)).toBe(true);
    expect((result.exercises as unknown[]).length).toBeGreaterThan(0);
    expect(result).toHaveProperty('coachingSummary');
    expect(typeof result.coachingSummary).toBe('string');
  });

  it('throws invalid-argument when timeMinutes is missing', async () => {
    const { timeMinutes: _removed, ...contextWithoutTime } = validContext;
    await expect(
      callHandler({
        auth: { uid: 'uid-123', token: {} },
        data: contextWithoutTime,
      })
    ).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('throws invalid-argument when focus is missing', async () => {
    const { focus: _removed, ...contextWithoutFocus } = validContext;
    await expect(
      callHandler({
        auth: { uid: 'uid-123', token: {} },
        data: contextWithoutFocus,
      })
    ).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('throws invalid-argument when equipment is missing', async () => {
    const { equipment: _removed, ...contextWithoutEquipment } = validContext;
    await expect(
      callHandler({
        auth: { uid: 'uid-123', token: {} },
        data: contextWithoutEquipment,
      })
    ).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });
});
