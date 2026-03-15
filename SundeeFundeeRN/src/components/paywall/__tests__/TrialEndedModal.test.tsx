/**
 * Tests for TrialEndedModal component.
 */
import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';

import { TrialEndedModal } from '../TrialEndedModal';

describe('TrialEndedModal', () => {
  const onDismiss = jest.fn();
  const onSubscribe = jest.fn();

  const defaultProps = {
    visible: true,
    onDismiss,
    onSubscribe,
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders "Your Trial Has Ended" heading', () => {
    const { getByText } = render(<TrialEndedModal {...defaultProps} />);
    expect(getByText(/Your Trial Has Ended/i)).toBeTruthy();
  });

  it('renders feature list with premium features', () => {
    const { getByText } = render(<TrialEndedModal {...defaultProps} />);
    expect(getByText(/AI Workouts/i)).toBeTruthy();
    expect(getByText(/Programs/i)).toBeTruthy();
    expect(getByText(/Cycle Adaptation/i)).toBeTruthy();
  });

  it('calls onSubscribe when "Subscribe Now" button is pressed', () => {
    const { getByTestId } = render(<TrialEndedModal {...defaultProps} />);
    fireEvent.press(getByTestId('trial-ended-subscribe-btn'));
    expect(onSubscribe).toHaveBeenCalledTimes(1);
  });

  it('calls onDismiss when "Continue with Free" button is pressed', () => {
    const { getByTestId } = render(<TrialEndedModal {...defaultProps} />);
    fireEvent.press(getByTestId('trial-ended-continue-free-btn'));
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });

  it('does not render when visible is false', () => {
    const { queryByText } = render(
      <TrialEndedModal {...defaultProps} visible={false} />
    );
    // Modal should not show content when not visible
    expect(queryByText(/Your Trial Has Ended/i)).toBeNull();
  });
});
