/**
 * Mock for expo-keep-awake.
 *
 * Provides Jest stubs for screen wake lock functionality.
 */

export const activateKeepAwakeAsync = jest.fn().mockResolvedValue(undefined);

export const deactivateKeepAwake = jest.fn().mockResolvedValue(undefined);

export const useKeepAwake = jest.fn();
