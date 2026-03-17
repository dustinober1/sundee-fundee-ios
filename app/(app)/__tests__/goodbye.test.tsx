/**
 * Tests for GoodbyeScreen.
 *
 * Verifies the screen renders without crash after account deletion,
 * shows the "Done" button, and has the correct content.
 */

// ---------------------------------------------------------------------------
// Module mocks — must come before imports
// ---------------------------------------------------------------------------

const mockRouterReplace = jest.fn();

jest.mock('expo-router', () => ({
  useRouter: jest.fn(() => ({ replace: mockRouterReplace })),
}));

jest.mock('@/src/theme/colors', () => ({
  CREAM: '#F4F0DF',
  CREAM_LIGHT: '#FAF7EE',
  NAVY: '#0D1A40',
  NAVY_MEDIUM: '#3A4A6B',
  ORANGE: '#F2731A',
}));

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------

import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react-native';
import GoodbyeScreen from '../goodbye';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('GoodbyeScreen', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('Test 1: Renders without crash and shows the Done button', () => {
    render(<GoodbyeScreen />);
    expect(screen.getByTestId('goodbye-done-button')).toBeTruthy();
  });

  it('shows "Account Deleted" heading', () => {
    render(<GoodbyeScreen />);
    expect(screen.getByText('Account Deleted')).toBeTruthy();
  });

  it('Done button navigates to sign-in via router.replace', () => {
    render(<GoodbyeScreen />);
    fireEvent.press(screen.getByTestId('goodbye-done-button'));
    expect(mockRouterReplace).toHaveBeenCalledWith('/sign-in');
  });
});
