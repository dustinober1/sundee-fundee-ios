// Mock for firebase-admin/firestore
//
// Design: All operations delegate to mutable handler functions.
// Tests can replace these handlers before each test.
// The getFirestore() always returns the same object structure,
// so the implementation always calls through these handlers.

// Mutable handlers — tests replace these in beforeEach
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let _handleGet: () => Promise<any> = jest.fn().mockResolvedValue({
  exists: false,
  data: () => undefined,
});
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let _handleSet: (data: any, opts?: any) => Promise<void> = jest.fn().mockResolvedValue(undefined);
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let _handleUpdate: (data: any) => Promise<void> = jest.fn().mockResolvedValue(undefined);

// Stable document reference that delegates to mutable handlers
const stableDocRef: {
  get: () => Promise<unknown>;
  set: (data: unknown, opts?: unknown) => void;
  update: (data: unknown) => void;
  collection: (path: string) => { doc: (id: string) => typeof stableDocRef };
} = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  get: () => _handleGet(),
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  set: (data: unknown, opts?: unknown) => _handleSet(data, opts),
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  update: (data: unknown) => _handleUpdate(data),
  // Nested collection chaining — reuses the same stableDocRef so tests control handlers globally
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  collection: (_path: string) => ({
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    doc: (_id: string) => stableDocRef,
  }),
};

// Transaction mock type
type TransactionMock = {
  get: (ref: typeof stableDocRef) => Promise<unknown>;
  set: (ref: typeof stableDocRef, data: unknown) => void;
  update: (ref: typeof stableDocRef, data: unknown) => void;
};

const stableDb = {
  collection: (_path: string) => ({
    doc: (_id: string) => stableDocRef,
  }),
  runTransaction: async (callback: (tx: TransactionMock) => Promise<void>) => {
    const tx: TransactionMock = {
      get: (ref) => ref.get(),
      set: (ref, data) => { ref.set(data); },
      update: (ref, data) => { ref.update(data); },
    };
    await callback(tx);
  },
};

export function getFirestore() {
  return stableDb;
}

// ---- Test control API ----

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function setMockGetResult(result: { exists: boolean; data: () => any }) {
  _handleGet = jest.fn().mockResolvedValue(result);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function setMockSetFn(fn: jest.Mock) {
  _handleSet = fn;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function setMockUpdateFn(fn: jest.Mock) {
  _handleUpdate = fn;
}

export function getSetCalls() {
  // Returns the calls made to _handleSet since last reset
  return (_handleSet as jest.Mock).mock.calls;
}

export function resetFirestoreMocks() {
  _handleGet = jest.fn().mockResolvedValue({ exists: false, data: () => undefined });
  _handleSet = jest.fn().mockResolvedValue(undefined);
  _handleUpdate = jest.fn().mockResolvedValue(undefined);
}

// Expose the handlers for assertion (tests call these via the exported refs)
export function getHandlers() {
  return {
    get: _handleGet as jest.Mock,
    set: _handleSet as jest.Mock,
    update: _handleUpdate as jest.Mock,
  };
}
