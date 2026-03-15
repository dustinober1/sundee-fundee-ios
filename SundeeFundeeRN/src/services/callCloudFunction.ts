import functions from '@react-native-firebase/functions';

export async function callCloudFunction<T>(
  name: string,
  data: Record<string, unknown>,
): Promise<T> {
  const fn = functions().httpsCallable(name);
  const result = await fn(data);
  return result.data as T;
}
