/**
 * Mock for @react-native-firebase/analytics
 *
 * Prevents "native module not found" errors in Jest test runs.
 * The native Firebase Analytics SDK requires a real device or EAS build to initialize.
 */

const mockAnalyticsInstance = {
  logScreenView: jest.fn().mockResolvedValue(undefined),
  logEvent: jest.fn().mockResolvedValue(undefined),
  setUserProperties: jest.fn().mockResolvedValue(undefined),
  setUserProperty: jest.fn().mockResolvedValue(undefined),
  setAnalyticsCollectionEnabled: jest.fn().mockResolvedValue(undefined),
};

const analytics = jest.fn(() => mockAnalyticsInstance);

module.exports = analytics;
module.exports.default = analytics;
