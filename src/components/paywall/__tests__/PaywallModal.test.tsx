/**
 * Tests for PaywallModal component.
 */
import React from 'react';
import { render, fireEvent, waitFor, act } from '@testing-library/react-native';
import { Platform } from 'react-native';
import Purchases from 'react-native-purchases';
import { mockCustomerInfo, mockAnnualPackage } from '../../../../__mocks__/react-native-purchases';

// Mock session
const mockUseSession = jest.fn();
jest.mock('@/src/auth/AuthContext', () => ({
  useSession: () => mockUseSession(),
}));

// Mock expo-router
jest.mock('expo-router', () => ({
  router: { push: jest.fn() },
}));

// Mock Firebase Functions
const mockHttpsCallable = jest.fn();
jest.mock('firebase/functions', () => ({
  httpsCallable: () => mockHttpsCallable,
  getFunctions: jest.fn().mockReturnValue('mock-functions'),
}));

// Mock Linking
jest.mock('react-native/Libraries/Linking/Linking', () => ({
  openURL: jest.fn().mockResolvedValue(undefined),
}));

import { PaywallModal } from '../PaywallModal';

const defaultSession = {
  user: { uid: 'test-uid', isAnonymous: false },
  isLoading: false,
  isGuest: false,
  signOut: jest.fn(),
};

describe('PaywallModal', () => {
  const defaultProps = {
    visible: true,
    onDismiss: jest.fn(),
    onSubscribed: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseSession.mockReturnValue(defaultSession);
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
  });

  it('renders feature list with 4 premium features', async () => {
    const { getByText } = render(<PaywallModal {...defaultProps} />);

    await waitFor(() => {
      expect(getByText(/AI Workouts/i)).toBeTruthy();
      expect(getByText(/Cycle Adaptation/i)).toBeTruthy();
      expect(getByText(/Programs/i)).toBeTruthy();
      expect(getByText(/Injury/i)).toBeTruthy();
    });
  });

  it('shows annual plan pre-selected with "Best Value" badge', async () => {
    const { getByText } = render(<PaywallModal {...defaultProps} />);

    await waitFor(() => {
      expect(getByText(/Best Value/i)).toBeTruthy();
    });
  });

  it('shows "Create Account to Subscribe" for guest users', () => {
    mockUseSession.mockReturnValue({
      ...defaultSession,
      user: { uid: 'anon-uid', isAnonymous: true },
      isGuest: true,
    });

    const { getByText } = render(<PaywallModal {...defaultProps} />);
    expect(getByText(/Create Account to Subscribe/i)).toBeTruthy();
  });

  it('calls onDismiss when close button pressed', async () => {
    const onDismiss = jest.fn();
    const { getByTestId } = render(
      <PaywallModal {...defaultProps} onDismiss={onDismiss} />
    );

    await waitFor(() => {
      const closeBtn = getByTestId('paywall-close-btn');
      fireEvent.press(closeBtn);
    });

    expect(onDismiss).toHaveBeenCalledTimes(1);
  });

  it('calls purchasePackage when subscribe tapped (successful purchase)', async () => {
    const premiumCustomerInfo = {
      ...mockCustomerInfo,
      entitlements: {
        active: { premium: { identifier: 'premium' } },
        all: {},
      },
    };
    (Purchases.purchasePackage as jest.Mock).mockResolvedValueOnce({
      customerInfo: premiumCustomerInfo,
    });

    // Provide annual package in offerings
    (Purchases.getOfferings as jest.Mock).mockResolvedValueOnce({
      current: {
        availablePackages: [mockAnnualPackage],
        annual: mockAnnualPackage,
        monthly: null,
      },
    });

    const onSubscribed = jest.fn();
    const { getByTestId } = render(
      <PaywallModal {...defaultProps} onSubscribed={onSubscribed} />
    );

    await waitFor(() => {
      expect(getByTestId('paywall-subscribe-btn')).toBeTruthy();
    });

    await act(async () => {
      fireEvent.press(getByTestId('paywall-subscribe-btn'));
    });

    await waitFor(() => {
      expect(Purchases.purchasePackage).toHaveBeenCalled();
      expect(onSubscribed).toHaveBeenCalledTimes(1);
    });
  });

  it('calls onSubscribed after successful purchase', async () => {
    const premiumCustomerInfo = {
      ...mockCustomerInfo,
      entitlements: {
        active: { premium: { identifier: 'premium' } },
        all: {},
      },
    };
    (Purchases.purchasePackage as jest.Mock).mockResolvedValueOnce({
      customerInfo: premiumCustomerInfo,
    });

    const onSubscribed = jest.fn();
    const { getByTestId } = render(
      <PaywallModal {...defaultProps} onSubscribed={onSubscribed} />
    );

    await waitFor(() => {
      expect(getByTestId('paywall-subscribe-btn')).toBeTruthy();
    });

    await act(async () => {
      fireEvent.press(getByTestId('paywall-subscribe-btn'));
    });

    await waitFor(() => {
      expect(onSubscribed).toHaveBeenCalledTimes(1);
    });
  });
});
