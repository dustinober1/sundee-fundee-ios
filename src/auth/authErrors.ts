/**
 * Maps Firebase Auth error codes to user-friendly inline messages.
 * Used by all auth hooks to surface errors without exposing raw Firebase codes.
 */

const AUTH_ERROR_MESSAGES: Record<string, string> = {
  'auth/email-already-in-use': 'An account with this email already exists',
  'auth/invalid-email': 'Please enter a valid email address',
  'auth/wrong-password': 'Incorrect password. Please try again',
  'auth/user-not-found': 'No account found with this email',
  'auth/too-many-requests': 'Too many attempts. Please try again later',
  'auth/network-request-failed': 'Network error. Please check your connection',
  'auth/invalid-credential': 'Sign-in failed. Please try again',
};

const DEFAULT_ERROR_MESSAGE = 'Something went wrong. Please try again';

/**
 * Returns a user-friendly error message for a Firebase Auth error.
 * Accepts any thrown value; extracts `code` if it resembles a Firebase error.
 */
export function getAuthErrorMessage(error: unknown): string {
  if (error !== null && typeof error === 'object' && 'code' in error) {
    const code = (error as { code: string }).code;
    return AUTH_ERROR_MESSAGES[code] ?? DEFAULT_ERROR_MESSAGE;
  }
  return DEFAULT_ERROR_MESSAGE;
}
