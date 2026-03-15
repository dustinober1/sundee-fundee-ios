export const defineSecret = (name: string) => ({
  name,
  value: () => `test-${name}-value`,
});
