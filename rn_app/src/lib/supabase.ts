import Constants from 'expo-constants';
import {
  createClient,
  type Session,
  type SupabaseClient,
} from '@supabase/supabase-js';

interface SupabaseConfig {
  url: string;
  anonKey: string;
}

function readConfig(): SupabaseConfig | null {
  const extra =
    (Constants.expoConfig?.extra as Record<string, string | undefined> | undefined) ??
    (Constants.manifest?.extra as Record<string, string | undefined> | undefined) ??
    {};

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL ?? extra.SUPABASE_URL ?? '';
  const anonKey =
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? extra.SUPABASE_ANON_KEY ?? '';

  if (!url || !anonKey) {
    return null;
  }

  return { url, anonKey };
}

let supabaseClient: SupabaseClient | null = null;

export function hasSupabaseConfig(): boolean {
  return readConfig() !== null;
}

export function getSupabaseClient(): SupabaseClient {
  if (supabaseClient) {
    return supabaseClient;
  }

  const config = readConfig();
  if (!config) {
    throw new Error(
      'Supabase config missing. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in Expo app config (extra) or environment.'
    );
  }

  supabaseClient = createClient(config.url, config.anonKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  });

  return supabaseClient;
}

export async function signInWithEmail(email: string, password: string) {
  return getSupabaseClient().auth.signInWithPassword({ email, password });
}

export async function signUpWithEmail(email: string, password: string) {
  return getSupabaseClient().auth.signUp({ email, password });
}

export async function signOut() {
  return getSupabaseClient().auth.signOut();
}

export async function getSession(): Promise<Session | null> {
  const { data } = await getSupabaseClient().auth.getSession();
  return data.session;
}

export function onAuthStateChange(
  callback: (session: Session | null) => void
) {
  const { data } = getSupabaseClient().auth.onAuthStateChange((_, session) => {
    callback(session);
  });
  return {
    unsubscribe: () => data.subscription.unsubscribe(),
  };
}
