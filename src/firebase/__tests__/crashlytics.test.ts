/**
 * Tests for src/firebase/crashlytics.ts — recordError and setCrashlyticsKeys helpers.
 *
 * The @react-native-firebase/crashlytics module is mocked via
 * __mocks__/@react-native-firebase/crashlytics.js (auto-discovered by Jest).
 *
 * Platform.OS is mocked per test group to verify web guard behavior.
 */

import { Platform } from 'react-native';

// ─── Module setup ─────────────────────────────────────────────────────────────

// Grab the mock crashlytics factory (set up in __mocks__)
// eslint-disable-next-line @typescript-eslint/no-require-imports
const mockCrashlyticsFactory = require('@react-native-firebase/crashlytics');
const mockCrashlyticsInstance = mockCrashlyticsFactory();

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('recordError', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Object.defineProperty(Platform, 'OS', { value: 'ios', writable: true, configurable: true });
  });

  it('calls crashlytics().recordError with the error object', () => {
    const { recordError } = require('../crashlytics');
    const error = new Error('test error');
    recordError(error);

    expect(mockCrashlyticsInstance.recordError).toHaveBeenCalledWith(error);
    expect(mockCrashlyticsInstance.log).not.toHaveBeenCalled();
  });

  it('calls crashlytics().log(context) then crashlytics().recordError when context is provided', () => {
    const { recordError } = require('../crashlytics');
    const error = new Error('test error');
    recordError(error, 'context info');

    expect(mockCrashlyticsInstance.log).toHaveBeenCalledWith('context info');
    expect(mockCrashlyticsInstance.recordError).toHaveBeenCalledWith(error);
  });

  it('is a no-op on web platform', () => {
    Object.defineProperty(Platform, 'OS', { value: 'web', writable: true, configurable: true });

    const { recordError } = require('../crashlytics');
    recordError(new Error('web error'));

    expect(mockCrashlyticsInstance.recordError).not.toHaveBeenCalled();
    expect(mockCrashlyticsInstance.log).not.toHaveBeenCalled();
  });
});

describe('setCrashlyticsKeys', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Object.defineProperty(Platform, 'OS', { value: 'ios', writable: true, configurable: true });
  });

  it('calls crashlytics().setAttributes with mapped keys for all provided values', async () => {
    const { setCrashlyticsKeys } = require('../crashlytics');
    await setCrashlyticsKeys({ subscriptionTier: 'premium', cyclePhase: 'follicular' });

    expect(mockCrashlyticsInstance.setAttributes).toHaveBeenCalledWith({
      subscription_tier: 'premium',
      cycle_phase: 'follicular',
    });
  });

  it('only includes subscription_tier when cyclePhase is not provided', async () => {
    const { setCrashlyticsKeys } = require('../crashlytics');
    await setCrashlyticsKeys({ subscriptionTier: 'free' });

    expect(mockCrashlyticsInstance.setAttributes).toHaveBeenCalledWith({
      subscription_tier: 'free',
    });
    const call = mockCrashlyticsInstance.setAttributes.mock.calls[0][0];
    expect(Object.keys(call)).not.toContain('cycle_phase');
  });

  it('does NOT call setAttributes when empty keys object is passed', async () => {
    const { setCrashlyticsKeys } = require('../crashlytics');
    await setCrashlyticsKeys({});

    expect(mockCrashlyticsInstance.setAttributes).not.toHaveBeenCalled();
  });
});
