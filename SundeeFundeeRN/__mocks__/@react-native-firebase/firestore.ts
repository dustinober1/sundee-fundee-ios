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

const mockDocumentRef: Record<string, jest.Mock | unknown> = {
  id: 'mock-doc-id',
  get: jest.fn().mockResolvedValue(mockDocumentSnapshot),
  set: jest.fn().mockResolvedValue(undefined),
  update: jest.fn().mockResolvedValue(undefined),
  delete: jest.fn().mockResolvedValue(undefined),
  onSnapshot: jest.fn((callback: (snap: typeof mockDocumentSnapshot) => void) => {
    callback(mockDocumentSnapshot);
    return jest.fn(); // Returns unsubscribe function
  }),
  // Support subcollections: collection().doc().collection()
  collection: jest.fn(),
};

const mockCollectionRef: Record<string, jest.Mock | unknown> = {
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

// Wire up subcollection support:
// collection().doc() returns mockDocumentRef, and mockDocumentRef.collection() returns mockCollectionRef
// This allows chaining: collection('users').doc(uid).collection('workouts').doc(id).set(...)
(mockDocumentRef.collection as jest.Mock).mockReturnValue(mockCollectionRef);
(mockCollectionRef.doc as jest.Mock).mockReturnValue(mockDocumentRef);

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
