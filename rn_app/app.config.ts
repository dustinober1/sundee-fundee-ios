import type { ExpoConfig } from 'expo/config';

const config: ExpoConfig = {
  name: 'Sundee-Fundee',
  slug: 'sundee-fundee-mobile',
  version: '1.0.0',
  orientation: 'portrait',
  scheme: 'sundeefundee',
  userInterfaceStyle: 'automatic',
  ios: {
    supportsTablet: false,
    bundleIdentifier: 'com.sundeefundee.mobile',
  },
  android: {
    package: 'com.sundeefundee.mobile',
  },
  extra: {
    SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
    SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
  },
};

export default config;
