/**
 * Mock for expo-secure-store
 *
 * Provides Jest function stubs for SecureStore operations.
 */

export const setItemAsync = jest.fn().mockResolvedValue(undefined);
export const getItemAsync = jest.fn().mockResolvedValue(null);
export const deleteItemAsync = jest.fn().mockResolvedValue(undefined);
export const isAvailableAsync = jest.fn().mockResolvedValue(true);
