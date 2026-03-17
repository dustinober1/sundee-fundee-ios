/**
 * Tests for AuthContext: SessionProvider and useSession hook.
 */
import React from 'react';
import { render, waitFor, act } from '@testing-library/react-native';
import { Text } from 'react-native';
import { renderHook } from '@testing-library/react-native';

// Mock AsyncStorage
jest.mock('@react-native-async-storage/async-storage', () => ({
  clear: jest.fn().mockResolvedValue(undefined),
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
}));

// Use the existing mock for @react-native-firebase/auth
import auth from '@react-native-firebase/auth';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Import after mocks are set up
import { SessionProvider, useSession } from '../AuthContext';

const mockAuthInstance = auth();

describe('SessionProvider', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset onAuthStateChanged to default: calls callback with null immediately
    (mockAuthInstance.onAuthStateChanged as jest.Mock).mockImplementation(
      (callback: (user: unknown) => void) => {
        callback(null);
        return jest.fn(); // unsubscribe
      }
    );
  });

  it('renders children while loading', () => {
    // When onAuthStateChanged has not yet called back, isLoading is true
    // Make onAuthStateChanged not call back immediately to test loading state
    (mockAuthInstance.onAuthStateChanged as jest.Mock).mockImplementation(
      (_callback: (user: unknown) => void) => {
        // Don't call callback — simulates async delay
        return jest.fn();
      }
    );

    const { getByText } = render(
      <SessionProvider>
        <Text>Child content</Text>
      </SessionProvider>
    );

    expect(getByText('Child content')).toBeTruthy();
  });

  it('sets user and isLoading=false when onAuthStateChanged returns a user', async () => {
    const mockUser = { uid: 'test-uid', email: 'test@example.com', isAnonymous: false };
    (mockAuthInstance.onAuthStateChanged as jest.Mock).mockImplementation(
      (callback: (user: unknown) => void) => {
        callback(mockUser);
        return jest.fn();
      }
    );

    let sessionResult: ReturnType<typeof useSession> | null = null;

    function TestComponent() {
      sessionResult = useSession();
      return null;
    }

    render(
      <SessionProvider>
        <TestComponent />
      </SessionProvider>
    );

    await waitFor(() => {
      expect(sessionResult?.isLoading).toBe(false);
      expect(sessionResult?.user).toEqual(mockUser);
    });
  });

  it('sets user=null and isLoading=false when onAuthStateChanged returns null', async () => {
    (mockAuthInstance.onAuthStateChanged as jest.Mock).mockImplementation(
      (callback: (user: unknown) => void) => {
        callback(null);
        return jest.fn();
      }
    );

    let sessionResult: ReturnType<typeof useSession> | null = null;

    function TestComponent() {
      sessionResult = useSession();
      return null;
    }

    render(
      <SessionProvider>
        <TestComponent />
      </SessionProvider>
    );

    await waitFor(() => {
      expect(sessionResult?.isLoading).toBe(false);
      expect(sessionResult?.user).toBeNull();
    });
  });

  it('throws when useSession is used outside SessionProvider', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    function TestComponent() {
      useSession();
      return null;
    }

    expect(() => render(<TestComponent />)).toThrow();
    consoleSpy.mockRestore();
  });

  it('signOut calls auth().signOut() and clears AsyncStorage', async () => {
    const mockUser = { uid: 'test-uid', isAnonymous: false };
    (mockAuthInstance.onAuthStateChanged as jest.Mock).mockImplementation(
      (callback: (user: unknown) => void) => {
        callback(mockUser);
        return jest.fn();
      }
    );

    let sessionResult: ReturnType<typeof useSession> | null = null;

    function TestComponent() {
      sessionResult = useSession();
      return null;
    }

    render(
      <SessionProvider>
        <TestComponent />
      </SessionProvider>
    );

    await waitFor(() => expect(sessionResult?.user).toBeTruthy());

    await act(async () => {
      await sessionResult?.signOut();
    });

    expect(mockAuthInstance.signOut).toHaveBeenCalledTimes(1);
    expect(AsyncStorage.clear).toHaveBeenCalledTimes(1);
  });

  it('unsubscribes from onAuthStateChanged on unmount', () => {
    const mockUnsubscribe = jest.fn();
    (mockAuthInstance.onAuthStateChanged as jest.Mock).mockImplementation(
      (callback: (user: unknown) => void) => {
        callback(null);
        return mockUnsubscribe;
      }
    );

    const { unmount } = render(
      <SessionProvider>
        <Text>Child</Text>
      </SessionProvider>
    );

    unmount();

    expect(mockUnsubscribe).toHaveBeenCalledTimes(1);
  });
});
