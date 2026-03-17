/**
 * Mock for expo-apple-authentication
 *
 * Provides Jest function stubs for Apple Sign-In operations.
 * Used on iOS only; mocked here to prevent native module errors in tests.
 *
 * The real package exports individual functions (not an AppleAuthentication object).
 */

// Standalone function exports (matching actual package API)
export const signInAsync = jest.fn().mockResolvedValue({
  user: 'mock-apple-user-id',
  email: 'test@privaterelay.appleid.com',
  fullName: {
    givenName: 'Test',
    familyName: 'User',
  },
  identityToken: 'mock-identity-token',
  authorizationCode: 'mock-auth-code',
  realUserStatus: 1,
  nonce: 'mock-nonce',
});

export const isAvailableAsync = jest.fn().mockResolvedValue(true);
export const getCredentialStateAsync = jest.fn().mockResolvedValue(1); // Authorized

// Apple Authentication scopes enum
export enum AppleAuthenticationScope {
  FULL_NAME = 0,
  EMAIL = 1,
}

// Apple Authentication button appearance
export enum AppleAuthenticationButtonStyle {
  WHITE = 0,
  WHITE_OUTLINE = 1,
  BLACK = 2,
}

// Apple Authentication button type
export enum AppleAuthenticationButtonType {
  SIGN_IN = 0,
  CONTINUE = 1,
}

// Mock AppleAuthenticationButton component
export const AppleAuthenticationButton = jest.fn().mockReturnValue(null);
