import { getFunctions, httpsCallable } from 'firebase/functions';
import { getApps } from 'firebase/app';

export async function callCloudFunction<T>(
  name: string,
  data: Record<string, unknown>,
): Promise<T> {
  const apps = getApps();
  if (apps.length === 0) throw new Error('Firebase not initialized');
  const functionsInstance = getFunctions(apps[0]);
  const fn = httpsCallable(functionsInstance, name);
  const result = await fn(data);
  return result.data as T;
}
