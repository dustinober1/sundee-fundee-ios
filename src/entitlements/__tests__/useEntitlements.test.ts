/**
 * Tests for useEntitlements hook.
 *
 * Covers:
 * - Mobile path: initial getCustomerInfo, addCustomerInfoUpdateListener, cleanup
 * - Web path: reads Firestore premiumEntitlement.active via onSnapshot
 * - isLoading transitions
 * - EntitlementContext provider and useEntitlementContext
 */
import { renderHook, waitFor, act } from '@testing-library/react-native';
import { Platform } from 'react-native';
import React from 'react';
import Purchases from 'react-native-purchases';

// Firestore mock — variable name must start with "mock" for jest hoisting to allow access
const mockFirestoreFns = {
  doc: jest.fn(),
  onSnapshot: jest.fn(),
};

jest.mock('@/src/firebase/firestore', () => ({
  getFirestoreInstance: jest.fn().mockReturnValue('mock-db'),
  isWeb: false,
}));

jest.mock('firebase/firestore', () => mockFirestoreFns);

// Mock AuthContext for EntitlementContext tests
jest.mock('@/src/auth/AuthContext', () => ({
  useSession: jest.fn().mockReturnValue({
    user: { uid: 'test-uid', isAnonymous: false },
    isLoading: false,
    isGuest: false,
    signOut: jest.fn(),
  }),
}));

import { useEntitlements, PREMIUM_ENTITLEMENT_ID } from '../useEntitlements';
import { EntitlementProvider, useEntitlementContext } from '../EntitlementContext';

describe('useEntitlements', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockFirestoreFns.doc.mockReset();
    mockFirestoreFns.onSnapshot.mockReset();
    // Reset Platform to mobile default
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
  });

  describe('mobile path (iOS/Android)', () => {
    it('calls getCustomerInfo on mount and sets isPremium=false for non-premium user', async () => {
      const { result } = renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(Purchases.getCustomerInfo).toHaveBeenCalledTimes(1);
      expect(result.current.isPremium).toBe(false);
    });

    it('sets isPremium=true when premium entitlement is active', async () => {
      (Purchases.getCustomerInfo as jest.Mock).mockResolvedValueOnce({
        entitlements: {
          active: { [PREMIUM_ENTITLEMENT_ID]: { identifier: PREMIUM_ENTITLEMENT_ID } },
          all: {},
        },
      });

      const { result } = renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(result.current.isPremium).toBe(true);
    });

    it('registers addCustomerInfoUpdateListener on mount', async () => {
      renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(Purchases.addCustomerInfoUpdateListener).toHaveBeenCalledTimes(1);
      });
    });

    it('updates isPremium via listener callback', async () => {
      let listenerCallback: ((info: unknown) => void) | null = null;
      (Purchases.addCustomerInfoUpdateListener as jest.Mock).mockImplementation(
        (cb: (info: unknown) => void) => {
          listenerCallback = cb;
          return { remove: jest.fn() };
        }
      );

      const { result } = renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(result.current.isPremium).toBe(false);

      act(() => {
        listenerCallback?.({
          entitlements: {
            active: { [PREMIUM_ENTITLEMENT_ID]: { identifier: PREMIUM_ENTITLEMENT_ID } },
            all: {},
          },
        });
      });

      expect(result.current.isPremium).toBe(true);
    });

    it('cleans up listener on unmount', async () => {
      const mockRemove = jest.fn();
      (Purchases.addCustomerInfoUpdateListener as jest.Mock).mockReturnValue({
        remove: mockRemove,
      });

      const { unmount } = renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(Purchases.addCustomerInfoUpdateListener).toHaveBeenCalled();
      });

      unmount();

      expect(mockRemove).toHaveBeenCalledTimes(1);
    });

    it('starts with isLoading=true and transitions to false after check', async () => {
      let resolveCustomerInfo: ((value: unknown) => void) | null = null;
      (Purchases.getCustomerInfo as jest.Mock).mockReturnValueOnce(
        new Promise((res) => {
          resolveCustomerInfo = res;
        })
      );

      const { result } = renderHook(() => useEntitlements('test-uid'));

      expect(result.current.isLoading).toBe(true);

      act(() => {
        resolveCustomerInfo?.({
          entitlements: { active: {}, all: {} },
        });
      });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });
    });
  });

  describe('web path', () => {
    beforeEach(() => {
      Object.defineProperty(Platform, 'OS', { value: 'web', configurable: true });
    });

    it('returns isPremium=false without calling Purchases on web', async () => {
      mockFirestoreFns.doc.mockReturnValue('mock-doc-ref');
      mockFirestoreFns.onSnapshot.mockImplementation(
        (_ref: unknown, callback: (snap: unknown) => void) => {
          callback({ exists: () => false, data: () => undefined });
          return jest.fn();
        }
      );

      const { result } = renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(Purchases.getCustomerInfo).not.toHaveBeenCalled();
      expect(Purchases.addCustomerInfoUpdateListener).not.toHaveBeenCalled();
    });

    it('sets up Firestore onSnapshot listener on web when uid provided', async () => {
      const mockUnsubscribe = jest.fn();
      mockFirestoreFns.doc.mockReturnValue('mock-doc-ref');
      mockFirestoreFns.onSnapshot.mockImplementation(
        (_ref: unknown, _callback: unknown) => mockUnsubscribe
      );

      renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(mockFirestoreFns.onSnapshot).toHaveBeenCalled();
      });
    });

    it('returns isPremium=false when premiumEntitlement absent', async () => {
      mockFirestoreFns.doc.mockReturnValue('mock-doc-ref');
      mockFirestoreFns.onSnapshot.mockImplementation(
        (_ref: unknown, callback: (snap: unknown) => void) => {
          callback({ exists: () => true, data: () => ({}) });
          return jest.fn();
        }
      );

      const { result } = renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(result.current.isPremium).toBe(false);
    });

    it('returns isPremium=true when Firestore premiumEntitlement.active is true', async () => {
      mockFirestoreFns.doc.mockReturnValue('mock-doc-ref');
      mockFirestoreFns.onSnapshot.mockImplementation(
        (_ref: unknown, callback: (snap: unknown) => void) => {
          callback({
            exists: () => true,
            data: () => ({ premiumEntitlement: { active: true } }),
          });
          return jest.fn();
        }
      );

      const { result } = renderHook(() => useEntitlements('test-uid'));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(result.current.isPremium).toBe(true);
    });
  });
});

describe('PREMIUM_ENTITLEMENT_ID', () => {
  it('exports PREMIUM_ENTITLEMENT_ID as "premium"', () => {
    expect(PREMIUM_ENTITLEMENT_ID).toBe('premium');
  });
});

describe('EntitlementContext', () => {
  beforeEach(() => {
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
    jest.clearAllMocks();
  });

  it('useEntitlementContext throws when used outside EntitlementProvider', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const { result } = renderHook(() => {
      try {
        return useEntitlementContext();
      } catch (e) {
        return e;
      }
    });
    expect(result.current).toBeInstanceOf(Error);
    consoleSpy.mockRestore();
  });

  it('EntitlementProvider provides isPremium and isLoading to children', async () => {
    (Purchases.getCustomerInfo as jest.Mock).mockResolvedValueOnce({
      entitlements: {
        active: { [PREMIUM_ENTITLEMENT_ID]: { identifier: PREMIUM_ENTITLEMENT_ID } },
        all: {},
      },
    });

    const wrapper = ({ children }: { children: React.ReactNode }) =>
      React.createElement(EntitlementProvider, null, children);

    const { result } = renderHook(() => useEntitlementContext(), { wrapper });

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.isPremium).toBe(true);
  });
});
