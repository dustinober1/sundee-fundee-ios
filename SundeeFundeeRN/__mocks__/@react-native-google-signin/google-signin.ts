/**
 * Mock for @react-native-google-signin/google-signin
 *
 * Provides Jest function stubs for Google Sign-In operations.
 * Used on Android and Web; mocked here to prevent native module errors in tests.
 */

export const GoogleSignin = {
  configure: jest.fn(),
  hasPlayServices: jest.fn().mockResolvedValue(true),
  signIn: jest.fn().mockResolvedValue({
    type: 'success',
    data: {
      idToken: 'mock-google-id-token',
      user: {
        id: 'mock-google-user-id',
        email: 'test@gmail.com',
        name: 'Test User',
        givenName: 'Test',
        familyName: 'User',
        photo: null,
      },
    },
  }),
  signOut: jest.fn().mockResolvedValue(undefined),
  isSignedIn: jest.fn().mockReturnValue(false),
  getCurrentUser: jest.fn().mockReturnValue(null),
  revokeAccess: jest.fn().mockResolvedValue(undefined),
};

export const GoogleAuthProvider = {
  credential: jest.fn().mockReturnValue({
    providerId: 'google.com',
    token: 'mock-google-credential',
  }),
};

// Status codes enum for error handling
export enum statusCodes {
  SIGN_IN_CANCELLED = 'SIGN_IN_CANCELLED',
  IN_PROGRESS = 'IN_PROGRESS',
  PLAY_SERVICES_NOT_AVAILABLE = 'PLAY_SERVICES_NOT_AVAILABLE',
  SIGN_IN_REQUIRED = 'SIGN_IN_REQUIRED',
}

export default GoogleSignin;
