const serverTimestamp = () => ({ _serverTimestamp: true });

const mockDocSet = jest.fn().mockResolvedValue(undefined);
const mockDocGet = jest.fn().mockResolvedValue({ data: () => ({}) });

const docDirect = jest.fn(() => ({
  id: "mock-doc-id",
  set: mockDocSet,
  get: mockDocGet,
}));

const collection = jest.fn(() => ({
  doc: jest.fn(() => ({ id: "mock-workout-id" })),
}));

const mockRecursiveDelete = jest.fn().mockResolvedValue(undefined);

const firestoreInstance = { collection, doc: docDirect, recursiveDelete: mockRecursiveDelete };

const firestore = jest.fn(() => firestoreInstance);
(firestore as unknown as { FieldValue: { serverTimestamp: () => unknown } }).FieldValue = {
  serverTimestamp,
};
(firestore as unknown as { Timestamp: { now: jest.Mock } }).Timestamp = {
  now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
};

const mockDeleteUser = jest.fn().mockResolvedValue(undefined);
const auth = jest.fn(() => ({ deleteUser: mockDeleteUser }));

export default { firestore, auth, initializeApp: jest.fn() };
export { firestore, auth, mockDeleteUser, mockRecursiveDelete, mockDocSet, mockDocGet };
