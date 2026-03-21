// Mock for firebase-admin and firebase-admin/app

export function initializeApp() {
  return {};
}

export function getApps() {
  return [];
}

export function getApp() {
  return {};
}

// Default export for `import * as admin from 'firebase-admin'`
const admin = {
  initializeApp,
  apps: [] as unknown[],
  firestore: () => ({
    collection: (_path: string) => ({
      doc: (_id: string) => ({
        update: jest.fn().mockResolvedValue(undefined),
        get: jest.fn().mockResolvedValue({ exists: false, data: () => undefined }),
        set: jest.fn().mockResolvedValue(undefined),
      }),
    }),
  }),
};

export default admin;
