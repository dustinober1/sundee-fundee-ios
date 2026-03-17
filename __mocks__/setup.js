/**
 * Jest global setup file — runs before jest-expo's setup.
 *
 * Pre-stubs globals that Expo SDK 55's WinterCG runtime (expo/src/winter)
 * tries to install lazily via property getters. Without this, Jest's
 * setupFiles phase triggers those lazy getters, which then try to `require()`
 * ES-module-only packages, causing "import outside of test scope" errors.
 *
 * Stubs provided here:
 * - globalThis.structuredClone: already available in Node 17+ but the getter fires anyway
 * - globalThis.__ExpoImportMetaRegistry: import.meta polyfill stub
 */

// structuredClone is available in Node 17+ natively. The expo winter runtime
// tries to lazily polyfill it with @ungap/structured-clone (an ES module).
// Providing the native version here prevents the lazy getter from firing.
if (typeof globalThis.structuredClone === 'undefined') {
  // Fallback for older Node versions
  globalThis.structuredClone = (obj) => JSON.parse(JSON.stringify(obj));
}

// Prevent the __ExpoImportMetaRegistry lazy getter from requiring runtime.native.ts
if (typeof globalThis.__ExpoImportMetaRegistry === 'undefined') {
  Object.defineProperty(globalThis, '__ExpoImportMetaRegistry', {
    value: { url: null },
    writable: true,
    configurable: true,
    enumerable: false,
  });
}
