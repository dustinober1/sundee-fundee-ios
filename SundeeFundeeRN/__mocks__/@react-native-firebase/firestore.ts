/**
 * Mock for @react-native-firebase/firestore
 *
 * Provides Jest function stubs for Firestore CRUD operations.
 * Returns chainable mock objects that simulate the Firestore query API.
 */

const mockDocumentSnapshot = {
  exists: true,
  id: 'mock-doc-id',
  data: jest.fn().mockReturnValue({ mockField: 'mockValue' }),
};

const mockQuerySnapshot = {
  empty: false,
  size: 1,
  docs: [mockDocumentSnapshot],
  forEach: jest.fn(),
};

const mockDocumentRef = {
  id: 'mock-doc-id',
  get: jest.fn().mockResolvedValue(mockDocumentSnapshot),
  set: jest.fn().mockResolvedValue(undefined),
  update: jest.fn().mockResolvedValue(undefined),
  delete: jest.fn().mockResolvedValue(undefined),
  onSnapshot: jest.fn((callback: (snap: typeof mockDocumentSnapshot) => void) => {
    callback(mockDocumentSnapshot);
    return jest.fn(); // Returns unsubscribe function
  }),
};

const mockCollectionRef = {
  doc: jest.fn().mockReturnValue(mockDocumentRef),
  get: jest.fn().mockResolvedValue(mockQuerySnapshot),
  add: jest.fn().mockResolvedValue(mockDocumentRef),
  where: jest.fn().mockReturnThis(),
  orderBy: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  onSnapshot: jest.fn((callback: (snap: typeof mockQuerySnapshot) => void) => {
    callback(mockQuerySnapshot);
    return jest.fn(); // Returns unsubscribe function
  }),
};

const mockFirestoreInstance = {
  collection: jest.fn().mockReturnValue(mockCollectionRef),
  doc: jest.fn().mockReturnValue(mockDocumentRef),
  batch: jest.fn().mockReturnValue({
    set: jest.fn().mockReturnThis(),
    update: jest.fn().mockReturnThis(),
    delete: jest.fn().mockReturnThis(),
    commit: jest.fn().mockResolvedValue(undefined),
  }),
};

const firestore = jest.fn().mockReturnValue(mockFirestoreInstance);

export default firestore;
