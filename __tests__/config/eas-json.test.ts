/**
 * Config validation tests for eas.json.
 *
 * Verifies that eas.json contains correct submit profiles, environment variable names,
 * and does not include disallowed configuration (e.g., serviceAccountKeyPath).
 */

import easJson from '../../eas.json';

describe('eas.json submit.production.ios', () => {
  const iosSubmit = easJson.submit.production.ios;

  it('ascAppId exists and is a string', () => {
    expect(typeof iosSubmit.ascAppId).toBe('string');
    expect(iosSubmit.ascAppId.length).toBeGreaterThan(0);
  });
});

describe('eas.json submit.production.android', () => {
  const androidSubmit = easJson.submit.production.android as {
    track: string;
    serviceAccountKeyPath?: string;
  };

  it('track is internal', () => {
    expect(androidSubmit.track).toBe('internal');
  });

  it('does NOT have serviceAccountKeyPath (first submission is manual AAB upload)', () => {
    expect(androidSubmit.serviceAccountKeyPath).toBeUndefined();
  });
});

describe('eas.json build.development.env', () => {
  const devEnv = easJson.build.development.env as Record<string, string>;

  it('uses EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN (not the old FIREBASE_ prefixed var)', () => {
    expect(devEnv['EXPO_PUBLIC_APP_CHECK_DEBUG_TOKEN']).toBeDefined();
  });

  it('does NOT use the old FIREBASE_APP_CHECK_DEBUG_TOKEN var name', () => {
    expect(devEnv['FIREBASE_APP_CHECK_DEBUG_TOKEN']).toBeUndefined();
  });
});
