/**
 * Tests for ProgramRepository — interface, factory, Firestore, and Local implementations.
 */

jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
  clear: jest.fn().mockResolvedValue(undefined),
  getAllKeys: jest.fn().mockResolvedValue([]),
  multiGet: jest.fn().mockResolvedValue([]),
  multiRemove: jest.fn().mockResolvedValue(undefined),
}));

// Mock the bundled programs JSON
jest.mock('../../resources/programs.json', () => [
  {
    id: 'test-program-1',
    name: 'Test Program One',
    weeks: [
      {
        id: 'w1',
        name: 'Week 1',
        sessions: [
          {
            id: 's1',
            name: 'Session 1',
            focusArea: 'lower_body',
            exercises: [
              {
                id: 'e1',
                name: 'Back Squat',
                sets: 3,
                reps: { kind: 'fixed', value: 5 },
              },
            ],
          },
        ],
      },
    ],
  },
  {
    id: 'test-program-2',
    name: 'Test Program Two',
    weeks: [
      {
        id: 'w1',
        name: 'Week 1',
        sessions: [
          {
            id: 's1',
            name: 'Session 1',
            exercises: [],
          },
        ],
      },
    ],
  },
]);

import firestore from '@react-native-firebase/firestore';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { LocalProgramRepo } from '../LocalProgramRepo';
import { FirestoreProgramRepo } from '../FirestoreProgramRepo';
import { getProgramRepo, firestoreProgramToProgram } from '../ProgramRepo';
import type { FirestoreProgramDocument, ProgramEnrollment } from '../ProgramRepo';
import type { Program } from '../../domain/types/index';

const ENROLLMENT_KEY = '@sundee/program_enrollment';

const testFirestoreProgram: FirestoreProgramDocument = {
  id: 'prog-001',
  name: 'Strength Builder',
  weeks: [
    {
      id: 'w1',
      name: 'Week 1',
      sessions: [
        {
          id: 's1',
          name: 'Day 1',
          exercises: [
            {
              id: 'e1',
              name: 'Squat',
              sets: 3,
              reps: { kind: 'fixed', value: 5 },
            },
          ],
        },
      ],
    },
  ],
};

const testEnrollment: ProgramEnrollment = {
  programId: 'prog-001',
  startDate: '2026-03-15',
  currentWeek: 0,
  currentSession: 0,
};

// ─── LocalProgramRepo ─────────────────────────────────────────────────────────

describe('LocalProgramRepo', () => {
  let repo: LocalProgramRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalProgramRepo();
  });

  it('getPrograms returns all programs from bundled JSON', async () => {
    const result = await repo.getPrograms();

    expect(result).toHaveLength(2);
    expect(result[0].id).toBe('test-program-1');
    expect(result[1].id).toBe('test-program-2');
  });

  it('getPrograms flattens weeks.sessions into program.sessions', async () => {
    const result = await repo.getPrograms();

    // test-program-1 has 1 week with 1 session
    expect(result[0].sessions).toHaveLength(1);
    expect(result[0].sessions[0].id).toBe('s1');
  });

  it('getProgram returns matching program by id', async () => {
    const result = await repo.getProgram('test-program-1');

    expect(result).not.toBeNull();
    expect(result?.id).toBe('test-program-1');
    expect(result?.name).toBe('Test Program One');
  });

  it('getProgram returns null when program not found', async () => {
    const result = await repo.getProgram('nonexistent-id');

    expect(result).toBeNull();
  });

  it('enrollUser saves enrollment to AsyncStorage', async () => {
    await repo.enrollUser('guest-uid', 'test-program-1');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData.programId).toBe('test-program-1');
    expect(savedData.currentWeek).toBe(0);
    expect(savedData.currentSession).toBe(0);
  });

  it('getEnrollment returns enrollment from AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify(testEnrollment));

    const result = await repo.getEnrollment('guest-uid');

    expect(result).toEqual(testEnrollment);
  });

  it('getEnrollment returns null when nothing stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getEnrollment('guest-uid');

    expect(result).toBeNull();
  });

  it('updateEnrollmentProgress updates week and session indices', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify(testEnrollment));

    await repo.updateEnrollmentProgress('guest-uid', 1, 2);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData.currentWeek).toBe(1);
    expect(savedData.currentSession).toBe(2);
    expect(savedData.programId).toBe('prog-001'); // unchanged
  });

  it('updateEnrollmentProgress does nothing when no enrollment exists', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    await repo.updateEnrollmentProgress('guest-uid', 1, 0);

    expect(AsyncStorage.setItem).not.toHaveBeenCalled();
  });

  it('unenroll removes enrollment from AsyncStorage', async () => {
    await repo.unenroll('guest-uid');

    expect(AsyncStorage.removeItem).toHaveBeenCalledWith(ENROLLMENT_KEY);
  });
});

// ─── FirestoreProgramRepo ─────────────────────────────────────────────────────

describe('FirestoreProgramRepo', () => {
  const mockFirestoreInstance = firestore();
  let repo: FirestoreProgramRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreProgramRepo();
  });

  it('getPrograms queries the /programs collection', async () => {
    const mockSnapshot = { empty: true, docs: [] };
    const mockCollection = mockFirestoreInstance.collection('programs');
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    await repo.getPrograms();

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('programs');
  });

  it('getPrograms returns empty array when snapshot is empty', async () => {
    const mockSnapshot = { empty: true, docs: [] };
    const mockCollection = mockFirestoreInstance.collection('programs');
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getPrograms();

    expect(result).toEqual([]);
  });

  it('getPrograms maps Firestore docs to domain Programs', async () => {
    const mockSnapshot = {
      empty: false,
      docs: [{ data: jest.fn().mockReturnValue(testFirestoreProgram) }],
    };
    const mockCollection = mockFirestoreInstance.collection('programs');
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getPrograms();

    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
  });

  it('getProgram returns null when document does not exist', async () => {
    const mockDocRef = mockFirestoreInstance.collection('programs').doc('prog-001');
    const mockDocSnapshot = { exists: false, data: jest.fn() };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getProgram('prog-001');

    expect(result).toBeNull();
  });

  it('enrollUser calls Firestore set on enrollment doc', async () => {
    await repo.enrollUser('test-uid', 'prog-001');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getEnrollment returns null when document does not exist', async () => {
    const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');
    const mockDocSnapshot = { exists: false, data: jest.fn() };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getEnrollment('test-uid');

    expect(result).toBeNull();
  });

  it('unenroll calls Firestore delete', async () => {
    await repo.unenroll('test-uid');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });
});

// ─── Factory function ────────────────────────────────────────────────────────

describe('getProgramRepo', () => {
  it('returns LocalProgramRepo when isGuest is true', () => {
    const repo = getProgramRepo(true);
    expect(repo).toBeInstanceOf(LocalProgramRepo);
  });

  it('returns FirestoreProgramRepo when isGuest is false', () => {
    const repo = getProgramRepo(false);
    expect(repo).toBeInstanceOf(FirestoreProgramRepo);
  });
});

// ─── firestoreProgramToProgram ───────────────────────────────────────────────

describe('firestoreProgramToProgram', () => {
  it('flattens weeks.sessions into program.sessions', () => {
    const result = firestoreProgramToProgram(testFirestoreProgram);

    expect(result.id).toBe('prog-001');
    expect(result.name).toBe('Strength Builder');
    expect(result.sessions).toHaveLength(1);
    expect(result.sessions[0].id).toBe('s1');
  });

  it('flattens sessions from multiple weeks into a single array', () => {
    const multiWeekProgram: FirestoreProgramDocument = {
      id: 'multi-week',
      name: 'Multi Week',
      weeks: [
        {
          id: 'w1',
          name: 'Week 1',
          sessions: [
            { id: 's1', name: 'Session 1', exercises: [] },
            { id: 's2', name: 'Session 2', exercises: [] },
          ],
        },
        {
          id: 'w2',
          name: 'Week 2',
          sessions: [
            { id: 's3', name: 'Session 3', exercises: [] },
          ],
        },
      ],
    };

    const result = firestoreProgramToProgram(multiWeekProgram);

    expect(result.sessions).toHaveLength(3);
    expect(result.sessions.map((s) => s.id)).toEqual(['s1', 's2', 's3']);
  });
});
