const serverTimestamp = () => ({ _serverTimestamp: true });

const mockDocSet = jest.fn().mockResolvedValue(undefined);

const docDirect = jest.fn(() => ({
  id: "mock-doc-id",
  set: mockDocSet,
}));

const collection = jest.fn(() => ({
  doc: jest.fn(() => ({ id: "mock-workout-id" })),
}));

const firestoreInstance = { collection, doc: docDirect };

const firestore = jest.fn(() => firestoreInstance);
(firestore as unknown as { FieldValue: { serverTimestamp: () => unknown } }).FieldValue = {
  serverTimestamp,
};
(firestore as unknown as { Timestamp: { now: jest.Mock } }).Timestamp = {
  now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
};

export default { firestore, initializeApp: jest.fn() };
export { firestore };
