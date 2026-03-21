// Mock for firebase-functions/params

export function defineSecret(name: string) {
  return {
    name,
    value: () => `mock-${name.toLowerCase().replace(/_/g, '-')}`,
  };
}

export function defineString(name: string, options?: { default?: string }) {
  return {
    name,
    value: () => options?.default ?? `mock-${name}`,
  };
}
