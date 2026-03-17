/**
 * Tests for TrialBanner component.
 */
import React from 'react';
import { render, fireEvent, waitFor, act } from '@testing-library/react-native';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Mock react-native-purchases with trial data
const mockGetCustomerInfo = jest.fn();
jest.mock('react-native-purchases', () => ({
  __esModule: true,
  default: {
    getCustomerInfo: (...args: unknown[]) => mockGetCustomerInfo(...args),
  },
}));

import { TrialBanner } from '../TrialBanner';

describe('TrialBanner', () => {
  const onSubscribe = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
  });

  it('renders when trial has <= 2 days remaining', async () => {
    const future = new Date();
    future.setDate(future.getDate() + 1); // 1 day remaining

    mockGetCustomerInfo.mockResolvedValueOnce({
      entitlements: {
        active: {
          premium: {
            periodType: 'TRIAL',
            expirationDate: future.toISOString(),
          },
        },
      },
    });

    const { getByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(getByTestId('trial-banner')).toBeTruthy();
    });
  });

  it('does not render when trial has > 2 days remaining', async () => {
    const future = new Date();
    future.setDate(future.getDate() + 5); // 5 days remaining

    mockGetCustomerInfo.mockResolvedValueOnce({
      entitlements: {
        active: {
          premium: {
            periodType: 'TRIAL',
            expirationDate: future.toISOString(),
          },
        },
      },
    });

    const { queryByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(queryByTestId('trial-banner')).toBeNull();
    });
  });

  it('does not render when user is not on trial', async () => {
    mockGetCustomerInfo.mockResolvedValueOnce({
      entitlements: {
        active: {
          premium: {
            periodType: 'NORMAL',
            expirationDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          },
        },
      },
    });

    const { queryByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(queryByTestId('trial-banner')).toBeNull();
    });
  });

  it('does not render when user has no active entitlements', async () => {
    mockGetCustomerInfo.mockResolvedValueOnce({
      entitlements: { active: {} },
    });

    const { queryByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(queryByTestId('trial-banner')).toBeNull();
    });
  });

  it('stores dismissal in AsyncStorage when X button pressed', async () => {
    const future = new Date();
    future.setDate(future.getDate() + 1);

    mockGetCustomerInfo.mockResolvedValueOnce({
      entitlements: {
        active: {
          premium: {
            periodType: 'TRIAL',
            expirationDate: future.toISOString(),
          },
        },
      },
    });

    const { getByTestId, queryByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(getByTestId('trial-banner')).toBeTruthy();
    });

    await act(async () => {
      fireEvent.press(getByTestId('trial-banner-dismiss'));
    });

    expect(AsyncStorage.setItem).toHaveBeenCalledWith('trialBannerDismissed', 'true');
    expect(queryByTestId('trial-banner')).toBeNull();
  });

  it('calls onSubscribe when Subscribe button pressed', async () => {
    const future = new Date();
    future.setDate(future.getDate() + 1);

    mockGetCustomerInfo.mockResolvedValueOnce({
      entitlements: {
        active: {
          premium: {
            periodType: 'TRIAL',
            expirationDate: future.toISOString(),
          },
        },
      },
    });

    const { getByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(getByTestId('trial-banner')).toBeTruthy();
    });

    fireEvent.press(getByTestId('trial-banner-subscribe'));

    expect(onSubscribe).toHaveBeenCalledTimes(1);
  });

  it('does not render when previously dismissed', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValueOnce('true'); // already dismissed

    const future = new Date();
    future.setDate(future.getDate() + 1);

    mockGetCustomerInfo.mockResolvedValueOnce({
      entitlements: {
        active: {
          premium: {
            periodType: 'TRIAL',
            expirationDate: future.toISOString(),
          },
        },
      },
    });

    const { queryByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(queryByTestId('trial-banner')).toBeNull();
    });
  });

  it('does not render on web', async () => {
    Object.defineProperty(Platform, 'OS', { value: 'web', configurable: true });

    const { queryByTestId } = render(<TrialBanner onSubscribe={onSubscribe} />);

    await waitFor(() => {
      expect(queryByTestId('trial-banner')).toBeNull();
    });
  });
});
