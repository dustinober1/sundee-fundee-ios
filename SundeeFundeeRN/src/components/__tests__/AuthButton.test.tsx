/**
 * AuthButton unit tests.
 *
 * Tests cover:
 * - Renders title text
 * - Shows ActivityIndicator when isLoading=true
 * - Shows error message when error is provided
 * - Calls onPress when tapped
 * - Does NOT call onPress when disabled
 */

import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { AuthButton } from '../AuthButton';

const noop = (): void => {};

describe('AuthButton', () => {
  it('renders title text', () => {
    const { getByText } = render(
      <AuthButton
        title="Sign In with Apple"
        onPress={noop}
        isLoading={false}
        error={null}
        variant="primary"
      />
    );
    expect(getByText('Sign In with Apple')).toBeTruthy();
  });

  it('shows ActivityIndicator when isLoading is true', () => {
    const { getByTestId, queryByText } = render(
      <AuthButton
        title="Sign In with Apple"
        onPress={noop}
        isLoading={true}
        error={null}
        variant="primary"
      />
    );
    expect(getByTestId('auth-button-spinner')).toBeTruthy();
    // Title text should not be visible while loading
    expect(queryByText('Sign In with Apple')).toBeNull();
  });

  it('shows error message when error is provided', () => {
    const { getByTestId } = render(
      <AuthButton
        title="Sign In"
        onPress={noop}
        isLoading={false}
        error="Invalid email or password"
        variant="primary"
      />
    );
    expect(getByTestId('auth-button-error')).toBeTruthy();
  });

  it('does not show error message when error is null', () => {
    const { queryByTestId } = render(
      <AuthButton
        title="Sign In"
        onPress={noop}
        isLoading={false}
        error={null}
        variant="primary"
      />
    );
    expect(queryByTestId('auth-button-error')).toBeNull();
  });

  it('calls onPress when tapped', () => {
    const onPress = jest.fn();
    const { getByRole } = render(
      <AuthButton
        title="Continue as Guest"
        onPress={onPress}
        isLoading={false}
        error={null}
        variant="text"
      />
    );
    fireEvent.press(getByRole('button'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('does NOT call onPress when disabled', () => {
    const onPress = jest.fn();
    const { getByRole } = render(
      <AuthButton
        title="Sign In"
        onPress={onPress}
        isLoading={false}
        error={null}
        variant="primary"
        disabled={true}
      />
    );
    fireEvent.press(getByRole('button'));
    expect(onPress).not.toHaveBeenCalled();
  });

  it('does NOT call onPress when isLoading is true', () => {
    const onPress = jest.fn();
    const { getByRole } = render(
      <AuthButton
        title="Sign In"
        onPress={onPress}
        isLoading={true}
        error={null}
        variant="primary"
      />
    );
    fireEvent.press(getByRole('button'));
    expect(onPress).not.toHaveBeenCalled();
  });

  it('renders secondary variant without error', () => {
    const { getByText } = render(
      <AuthButton
        title="Create Account"
        onPress={noop}
        isLoading={false}
        error={null}
        variant="secondary"
      />
    );
    expect(getByText('Create Account')).toBeTruthy();
  });
});
