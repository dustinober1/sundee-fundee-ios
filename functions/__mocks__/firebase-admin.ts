const serverTimestamp = () => ({ _serverTimestamp: true });

const doc = jest.fn(() => ({
  id: "mock-workout-id",
  set: jest.fn().mockResolvedValue(undefined),
}));

const collection = jest.fn(() => ({
  doc: () => ({ id: "mock-workout-id" }),
}));

const firestore = jest.fn(() => ({ collection }));
(firestore as unknown as { FieldValue: { serverTimestamp: () => unknown } }).FieldValue = {
  serverTimestamp,
};

export default { firestore, initializeApp: jest.fn() };
export { firestore };
