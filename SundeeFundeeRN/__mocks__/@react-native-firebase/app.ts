/**
 * Mock for @react-native-firebase/app
 *
 * Prevents "native module not found" errors in Jest test runs.
 * The native Firebase SDK requires a real device or EAS build to initialize.
 */

const mockFirebaseApp = {
  name: '[DEFAULT]',
  options: {
    apiKey: 'mock-api-key',
    projectId: 'mock-project-id',
  },
};

const firebase = {
  initializeApp: jest.fn().mockReturnValue(mockFirebaseApp),
  app: jest.fn().mockReturnValue(mockFirebaseApp),
  apps: [mockFirebaseApp],
};

export { firebase };
export default firebase;
