/**
 * Mock for @react-native-firebase/auth
 *
 * Provides Jest function stubs for all auth operations used in the app.
 * The onAuthStateChanged mock calls its callback immediately with null
 * (simulating no signed-in user) and returns an unsubscribe function.
 */

const mockUser = {
  uid: 'mock-user-uid',
  email: 'test@example.com',
  emailVerified: true,
  isAnonymous: false,
  displayName: 'Test User',
  sendEmailVerification: jest.fn().mockResolvedValue(undefined),
  linkWithCredential: jest.fn().mockResolvedValue({ user: null }),
};

const mockAnonymousUser = {
  uid: 'mock-anonymous-uid',
  email: null,
  emailVerified: false,
  isAnonymous: true,
  displayName: null,
  sendEmailVerification: jest.fn().mockResolvedValue(undefined),
};

const mockAuthInstance = {
  onAuthStateChanged: jest.fn((callback: (user: typeof mockUser | null) => void) => {
    callback(null); // Default: no user signed in
    return jest.fn(); // Returns unsubscribe function
  }),
  signInWithCredential: jest.fn().mockResolvedValue({ user: mockUser }),
  signInWithEmailAndPassword: jest.fn().mockResolvedValue({ user: mockUser }),
  createUserWithEmailAndPassword: jest.fn().mockResolvedValue({ user: mockUser }),
  signInAnonymously: jest.fn().mockResolvedValue({ user: mockAnonymousUser }),
  signOut: jest.fn().mockResolvedValue(undefined),
  currentUser: null,
};

// Static provider objects for credential creation
const AppleAuthProvider = {
  credential: jest.fn().mockReturnValue({ providerId: 'apple.com', token: 'mock-token' }),
};

const GoogleAuthProvider = {
  credential: jest.fn().mockReturnValue({ providerId: 'google.com', token: 'mock-token' }),
};

// The default export is a function that returns the auth instance
const auth = jest.fn().mockReturnValue(mockAuthInstance);

// Attach static providers to the auth function
Object.assign(auth, {
  AppleAuthProvider,
  GoogleAuthProvider,
});

export { AppleAuthProvider, GoogleAuthProvider };
export type { FirebaseAuthTypes } from '@react-native-firebase/auth';
export default auth;
