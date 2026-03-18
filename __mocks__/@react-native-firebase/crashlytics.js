/**
 * Mock for @react-native-firebase/crashlytics
 *
 * Prevents "native module not found" errors in Jest test runs.
 * The native Firebase Crashlytics SDK requires a real device or EAS build to initialize.
 */

const mockCrashlyticsInstance = {
  setCrashlyticsCollectionEnabled: jest.fn().mockResolvedValue(undefined),
  recordError: jest.fn(),
  setAttribute: jest.fn().mockResolvedValue(undefined),
  setAttributes: jest.fn().mockResolvedValue(undefined),
  log: jest.fn(),
  setUserId: jest.fn().mockResolvedValue(undefined),
  crash: jest.fn(),
};

const crashlytics = jest.fn(() => mockCrashlyticsInstance);

module.exports = crashlytics;
module.exports.default = crashlytics;
