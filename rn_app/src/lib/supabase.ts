import Constants from 'expo-constants';
import { createClient } from '@supabase/supabase-js';

function getConfig() {
  const extra = (Constants && (Constants.expoConfig || Constants.manifest) && (Constants.expoConfig?.extra || Constants.manifest?.extra)) || {};
  return {
    url: process.env.NEXT_PUBLIC_SUPABASE_URL || extra.SUPABASE_URL || '',
    key: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || extra.SUPABASE_ANON_KEY || '',
  };
}

const { url, key } = getConfig();

if (!url || !key) {
  console.warn('Supabase URL or ANON KEY not configured. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in app config or environment.');
}

export const supabase = createClient(url || '', key || '');

export async function signInWithEmail(email: string, password: string) {
  return supabase.auth.signInWithPassword({ email, password });
}

export async function signOut() {
  return supabase.auth.signOut();
}
