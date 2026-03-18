/**
 * Tests for src/firebase/analytics.ts — logEvent and setUserProperties helpers.
 *
 * The @react-native-firebase/analytics module is mocked via
 * __mocks__/@react-native-firebase/analytics.js (auto-discovered by Jest).
 *
 * Platform.OS is mocked per test group to verify web guard behavior.
 */

import { Platform } from 'react-native';

// ─── Module setup ─────────────────────────────────────────────────────────────

// Grab the mock analytics factory (set up in __mocks__)
// eslint-disable-next-line @typescript-eslint/no-require-imports
const mockAnalyticsFactory = require('@react-native-firebase/analytics');
const mockAnalyticsInstance = mockAnalyticsFactory();

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('logEvent', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default: native platform
    Object.defineProperty(Platform, 'OS', { value: 'ios', writable: true, configurable: true });
  });

  it('calls analytics().logEvent with event name and params on native', async () => {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { logEvent } = require('../analytics');
    await logEvent('workout_started', { source: 'manual' });

    expect(mockAnalyticsInstance.logEvent).toHaveBeenCalledWith('workout_started', {
      source: 'manual',
    });
  });

  it('passes empty object when no params provided', async () => {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { logEvent } = require('../analytics');
    await logEvent('test_event');

    expect(mockAnalyticsInstance.logEvent).toHaveBeenCalledWith('test_event', {});
  });

  it('is a no-op on web platform', async () => {
    Object.defineProperty(Platform, 'OS', { value: 'web', writable: true, configurable: true });

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { logEvent } = require('../analytics');
    await logEvent('workout_started', { source: 'manual' });

    expect(mockAnalyticsInstance.logEvent).not.toHaveBeenCalled();
  });
});

describe('setUserProperties', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Object.defineProperty(Platform, 'OS', { value: 'ios', writable: true, configurable: true });
  });

  it('calls analytics().setUserProperties with stringified values for premium user', async () => {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { setUserProperties } = require('../analytics');
    await setUserProperties({ subscriptionTier: 'premium', cycleTrackingEnabled: true });

    expect(mockAnalyticsInstance.setUserProperties).toHaveBeenCalledWith({
      subscription_tier: 'premium',
      cycle_tracking_enabled: 'true',
    });
  });

  it('stringifies cycleTrackingEnabled=false as string "false" for free user', async () => {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { setUserProperties } = require('../analytics');
    await setUserProperties({ subscriptionTier: 'free', cycleTrackingEnabled: false });

    expect(mockAnalyticsInstance.setUserProperties).toHaveBeenCalledWith({
      subscription_tier: 'free',
      cycle_tracking_enabled: 'false',
    });
  });
});
