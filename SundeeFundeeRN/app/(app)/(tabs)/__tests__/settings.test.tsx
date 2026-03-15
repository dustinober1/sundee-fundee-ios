/**
 * Tests for Settings screen subscription management section.
 */
import React from 'react';
import { render, fireEvent, waitFor, act } from '@testing-library/react-native';
import { Platform, Linking, Alert } from 'react-native';
import Purchases from 'react-native-purchases';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Mock session
const mockUseSession = jest.fn();
jest.mock('@/src/auth/AuthContext', () => ({
  useSession: () => mockUseSession(),
}));

// Mock entitlements context
const mockUseEntitlementContext = jest.fn();
jest.mock('@/src/entitlements/EntitlementContext', () => ({
  useEntitlementContext: () => mockUseEntitlementContext(),
}));

// Mock SettingsRepo
jest.mock('@/src/repositories/SettingsRepo', () => ({
  getSettingsRepo: () => ({
    getSettings: jest.fn().mockResolvedValue(null),
    saveSettings: jest.fn().mockResolvedValue(undefined),
  }),
  DEFAULT_SETTINGS: { defaultRestDuration: 90 },
}));

// Mock expo-router
jest.mock('expo-router', () => ({
  useRouter: () => ({ push: jest.fn() }),
}));

// Alert mock
jest.spyOn(Alert, 'alert').mockImplementation(jest.fn());

import SettingsScreen from '../settings';

const defaultSession = {
  user: { uid: 'test-uid', displayName: 'Test User', email: 'test@test.com', isAnonymous: false },
  isLoading: false,
  isGuest: false,
  signOut: jest.fn(),
};

const premiumEntitlements = {
  isPremium: true,
  isLoading: false,
};

const freeEntitlements = {
  isPremium: false,
  isLoading: false,
};

describe('SettingsScreen - Subscription section', () => {
  let linkingOpenURLSpy: jest.SpyInstance;

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseSession.mockReturnValue(defaultSession);
    mockUseEntitlementContext.mockReturnValue(freeEntitlements);
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
    linkingOpenURLSpy = jest.spyOn(Linking, 'openURL').mockResolvedValue(undefined);
  });

  afterEach(() => {
    linkingOpenURLSpy.mockRestore();
  });

  it('renders "Subscription" section heading', async () => {
    const { getByText } = render(<SettingsScreen />);
    await waitFor(() => {
      expect(getByText('Subscription')).toBeTruthy();
    });
  });

  it('shows "Unlock Premium" card when user is not subscribed', async () => {
    const { getByText } = render(<SettingsScreen />);
    await waitFor(() => {
      expect(getByText(/Unlock Premium/i)).toBeTruthy();
    });
  });

  it('shows "View Plans" button for non-subscribed users', async () => {
    const { getByTestId } = render(<SettingsScreen />);
    await waitFor(() => {
      expect(getByTestId('view-plans-button')).toBeTruthy();
    });
  });

  it('opens PaywallModal when "View Plans" is tapped', async () => {
    const { getByTestId, queryByTestId } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(getByTestId('view-plans-button')).toBeTruthy();
    });

    await act(async () => {
      fireEvent.press(getByTestId('view-plans-button'));
    });

    // PaywallModal should become visible
    await waitFor(() => {
      expect(getByTestId('paywall-close-btn')).toBeTruthy();
    });
  });

  it('shows plan info and "Manage Subscription" when subscribed', async () => {
    mockUseEntitlementContext.mockReturnValue(premiumEntitlements);

    const mockCustomerInfo = {
      entitlements: {
        active: {
          premium: {
            identifier: 'premium',
            productIdentifier: 'com.sundeefundee.premium.annual',
            periodType: 'NORMAL',
            expirationDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          },
        },
      },
      managementURL: 'https://play.google.com/store/account/subscriptions',
    };

    (Purchases.getCustomerInfo as jest.Mock).mockResolvedValueOnce(mockCustomerInfo);

    const { getByTestId } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(getByTestId('manage-subscription-row')).toBeTruthy();
    });
  });

  it('calls Linking.openURL with App Store URL on iOS when Manage Subscription tapped', async () => {
    mockUseEntitlementContext.mockReturnValue(premiumEntitlements);
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });

    const mockCustomerInfo = {
      entitlements: {
        active: {
          premium: {
            identifier: 'premium',
            productIdentifier: 'com.sundeefundee.premium.annual',
            periodType: 'NORMAL',
            expirationDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          },
        },
      },
      managementURL: null,
    };

    (Purchases.getCustomerInfo as jest.Mock).mockResolvedValueOnce(mockCustomerInfo);

    const { getByTestId } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(getByTestId('manage-subscription-row')).toBeTruthy();
    });

    await act(async () => {
      fireEvent.press(getByTestId('manage-subscription-row'));
    });

    expect(linkingOpenURLSpy).toHaveBeenCalledWith('itms-apps://apps.apple.com/account/subscriptions');
  });

  it('shows "Restore Purchases" button on mobile', async () => {
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });

    const { getByTestId } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(getByTestId('restore-purchases-button')).toBeTruthy();
    });
  });

  it('does NOT show "Restore Purchases" button on web', async () => {
    Object.defineProperty(Platform, 'OS', { value: 'web', configurable: true });

    const { queryByTestId } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(queryByTestId('restore-purchases-button')).toBeNull();
    });
  });

  it('calls Purchases.restorePurchases when Restore Purchases is pressed', async () => {
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
    (Purchases.restorePurchases as jest.Mock).mockResolvedValueOnce({
      entitlements: { active: {} },
    });

    const { getByTestId } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(getByTestId('restore-purchases-button')).toBeTruthy();
    });

    await act(async () => {
      fireEvent.press(getByTestId('restore-purchases-button'));
    });

    await waitFor(() => {
      expect(Purchases.restorePurchases).toHaveBeenCalledTimes(1);
    });
  });
});
