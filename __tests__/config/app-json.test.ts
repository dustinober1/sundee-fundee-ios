/**
 * Config validation tests for app.json.
 *
 * Verifies that app.json contains all required plugins, static linking entries,
 * privacy manifests, and iOS entitlements for native Firebase modules.
 */

import appJson from '../../app.json';

const expo = appJson.expo;
const plugins: (string | unknown[])[] = expo.plugins as (string | unknown[])[];

const buildPropsEntry = plugins.find(
  (p): p is [string, { ios: { forceStaticLinking: string[] } }] =>
    Array.isArray(p) && p[0] === 'expo-build-properties'
);

const forceStaticLinking: string[] =
  buildPropsEntry?.[1]?.ios?.forceStaticLinking ?? [];

describe('app.json plugins', () => {
  it('includes @react-native-firebase/crashlytics plugin', () => {
    expect(plugins).toContain('@react-native-firebase/crashlytics');
  });

  it('includes @react-native-firebase/messaging plugin', () => {
    expect(plugins).toContain('@react-native-firebase/messaging');
  });

  it('does NOT include @react-native-firebase/analytics plugin (no config plugin for analytics)', () => {
    expect(plugins).not.toContain('@react-native-firebase/analytics');
  });
});

describe('app.json expo-build-properties forceStaticLinking', () => {
  it('includes RNFBMessaging', () => {
    expect(forceStaticLinking).toContain('RNFBMessaging');
  });

  it('includes RNFBCrashlytics', () => {
    expect(forceStaticLinking).toContain('RNFBCrashlytics');
  });

  it('includes RNFBAnalytics', () => {
    expect(forceStaticLinking).toContain('RNFBAnalytics');
  });
});

describe('app.json expo.ios.privacyManifests', () => {
  const privacyManifests = expo.ios.privacyManifests as {
    NSPrivacyCollectedDataTypes: { NSPrivacyCollectedDataType: string }[];
    NSPrivacyTracking: boolean;
  };

  it('exists', () => {
    expect(privacyManifests).toBeDefined();
  });

  it('has exactly 5 collected data types', () => {
    expect(privacyManifests.NSPrivacyCollectedDataTypes).toHaveLength(5);
  });

  it('NSPrivacyTracking is false', () => {
    expect(privacyManifests.NSPrivacyTracking).toBe(false);
  });

  it('includes NSPrivacyCollectedDataTypeHealthAndFitness', () => {
    const types = privacyManifests.NSPrivacyCollectedDataTypes.map(
      (t) => t.NSPrivacyCollectedDataType
    );
    expect(types).toContain('NSPrivacyCollectedDataTypeHealthAndFitness');
  });
});

describe('app.json expo.ios.entitlements', () => {
  const entitlements = expo.ios.entitlements as Record<string, string>;

  it('has aps-environment set to production', () => {
    expect(entitlements['aps-environment']).toBe('production');
  });
});

describe('app.json expo.ios.infoPlist', () => {
  const infoPlist = expo.ios.infoPlist as { UIBackgroundModes: string[] };

  it('includes remote-notification in UIBackgroundModes', () => {
    expect(infoPlist.UIBackgroundModes).toContain('remote-notification');
  });
});
