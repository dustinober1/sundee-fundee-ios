"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.firestore = void 0;
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
exports.firestore = firestore;
firestore.FieldValue = {
    serverTimestamp,
};
firestore.Timestamp = {
    now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
};
exports.default = { firestore, initializeApp: jest.fn() };
//# sourceMappingURL=firebase-admin.js.map