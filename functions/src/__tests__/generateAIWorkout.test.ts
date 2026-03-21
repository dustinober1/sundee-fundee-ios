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

// eslint-disable-next-line @typescript-eslint/no-require-imports
const mockFirestore = require('../../__mocks__/firebase-admin-firestore') as {
  setMockGetResult: (result: { exists: boolean; data: () => unknown }) => void;
  resetFirestoreMocks: () => void;
  getHandlers: () => { get: jest.Mock; set: jest.Mock; update: jest.Mock };
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

  describe('rate limiting (SEC-04)', () => {
    const todayString = new Date().toISOString().slice(0, 10);
    const authRequest = { auth: { uid: 'uid-123', token: {} }, data: validContext };

    beforeEach(() => {
      mockFirestore.resetFirestoreMocks();
    });

    it('allows first AI workout call (no existing rate limit doc)', async () => {
      mockFirestore.setMockGetResult({ exists: false, data: () => undefined });

      const result = (await callHandler(authRequest)) as Record<string, unknown>;

      // Should succeed and return a workout
      expect(result).toHaveProperty('exercises');

      // Should write initial counter doc
      const handlers = mockFirestore.getHandlers();
      expect(handlers.set).toHaveBeenCalledWith(
        { date: todayString, count: 1 },
        undefined
      );
    });

    it('allows calls when count is under the daily limit', async () => {
      mockFirestore.setMockGetResult({
        exists: true,
        data: () => ({ date: todayString, count: 3 }),
      });

      const result = (await callHandler(authRequest)) as Record<string, unknown>;

      // Should succeed
      expect(result).toHaveProperty('exercises');

      // Should increment counter
      const handlers = mockFirestore.getHandlers();
      expect(handlers.update).toHaveBeenCalledWith({ count: 4 });
    });

    it('rejects 6th call on same UTC day with resource-exhausted', async () => {
      mockFirestore.setMockGetResult({
        exists: true,
        data: () => ({ date: todayString, count: 5 }),
      });

      await expect(callHandler(authRequest)).rejects.toMatchObject({
        code: 'resource-exhausted',
      });
    });

    it('resets counter on a new day (allows call even after hitting limit yesterday)', async () => {
      mockFirestore.setMockGetResult({
        exists: true,
        data: () => ({ date: '2020-01-01', count: 5 }),
      });

      const result = (await callHandler(authRequest)) as Record<string, unknown>;

      // Should succeed (new day)
      expect(result).toHaveProperty('exercises');

      // Should reset counter to 1 for today
      const handlers = mockFirestore.getHandlers();
      expect(handlers.set).toHaveBeenCalledWith(
        { date: todayString, count: 1 },
        undefined
      );
    });
  });
});
