/**
 * Tests for src/hooks/useScreenTracking.ts
 *
 * The @react-native-firebase/analytics and crashlytics modules are mocked via
 * __mocks__/@react-native-firebase/*.js (auto-discovered by Jest).
 *
 * expo-router is mocked to provide a controllable usePathname value.
 */

// jest.mock must be hoisted before imports
jest.mock('expo-router', () => ({
  usePathname: jest.fn().mockReturnValue('/dashboard'),
}));

import { renderHook } from '@testing-library/react-native';
import { Platform } from 'react-native';
import { usePathname } from 'expo-router';

import { useScreenTracking } from '../useScreenTracking';

// ─── Module setup ─────────────────────────────────────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-require-imports
const mockAnalyticsFactory = require('@react-native-firebase/analytics');
const mockAnalyticsInstance = mockAnalyticsFactory();

// eslint-disable-next-line @typescript-eslint/no-require-imports
const mockCrashlyticsFactory = require('@react-native-firebase/crashlytics');
const mockCrashlyticsInstance = mockCrashlyticsFactory();

const mockUsePathname = usePathname as jest.MockedFunction<typeof usePathname>;

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('useScreenTracking', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockUsePathname.mockReturnValue('/dashboard');
    Object.defineProperty(Platform, 'OS', { value: 'ios', writable: true, configurable: true });
  });

  it('calls logScreenView with screen_name and screen_class on initial render', () => {
    renderHook(() => useScreenTracking());

    expect(mockAnalyticsInstance.logScreenView).toHaveBeenCalledWith({
      screen_name: '/dashboard',
      screen_class: '/dashboard',
    });
  });

  it('calls crashlytics setAttribute with current_screen on initial render', () => {
    renderHook(() => useScreenTracking());

    expect(mockCrashlyticsInstance.setAttribute).toHaveBeenCalledWith(
      'current_screen',
      '/dashboard',
    );
  });

  it('calls logScreenView and setAttribute again when pathname changes', () => {
    const { rerender } = renderHook(() => useScreenTracking());

    // Initial render — '/dashboard'
    expect(mockAnalyticsInstance.logScreenView).toHaveBeenCalledTimes(1);

    // Simulate navigation to a new route
    mockUsePathname.mockReturnValue('/programs');
    rerender({});

    expect(mockAnalyticsInstance.logScreenView).toHaveBeenCalledTimes(2);
    expect(mockAnalyticsInstance.logScreenView).toHaveBeenLastCalledWith({
      screen_name: '/programs',
      screen_class: '/programs',
    });
    expect(mockCrashlyticsInstance.setAttribute).toHaveBeenLastCalledWith(
      'current_screen',
      '/programs',
    );
  });

  it('skips all analytics calls on web platform', () => {
    Object.defineProperty(Platform, 'OS', { value: 'web', writable: true, configurable: true });

    renderHook(() => useScreenTracking());

    expect(mockAnalyticsInstance.logScreenView).not.toHaveBeenCalled();
    expect(mockCrashlyticsInstance.setAttribute).not.toHaveBeenCalled();
  });
});
