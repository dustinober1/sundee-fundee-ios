/**
 * Tests for ReadinessSurveyCard component.
 *
 * Uses static helper functions for text assertion (testable without mounting).
 * UI rendering tests verify card structure and callback wiring.
 */

import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import ReadinessSurveyCard, {
  cardHeadingText,
  cardSubText,
} from '../ReadinessSurveyCard';

// ─── Static helper tests ──────────────────────────────────────────────────────

describe('ReadinessSurveyCard — static helpers', () => {
  it('cardHeadingText returns expected heading', () => {
    expect(cardHeadingText()).toBe('How are you feeling today?');
  });

  it('cardSubText returns expected subtext', () => {
    expect(cardSubText()).toBe('Quick check-in takes 15 seconds');
  });
});

// ─── Rendering tests ──────────────────────────────────────────────────────────

describe('ReadinessSurveyCard — rendering', () => {
  it('renders heading text', () => {
    const { getByTestId } = render(
      <ReadinessSurveyCard onPress={jest.fn()} onDismiss={jest.fn()} />
    );
    const heading = getByTestId('readiness-card-heading');
    expect(heading.props.children).toBe('How are you feeling today?');
  });

  it('renders subtext', () => {
    const { getByTestId } = render(
      <ReadinessSurveyCard onPress={jest.fn()} onDismiss={jest.fn()} />
    );
    const subtext = getByTestId('readiness-card-subtext');
    expect(subtext.props.children).toBe('Quick check-in takes 15 seconds');
  });

  it('calls onPress when card is tapped', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <ReadinessSurveyCard onPress={onPress} onDismiss={jest.fn()} />
    );
    fireEvent.press(getByTestId('readiness-survey-card'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('calls onDismiss when dismiss button is tapped', () => {
    const onDismiss = jest.fn();
    const { getByTestId } = render(
      <ReadinessSurveyCard onPress={jest.fn()} onDismiss={onDismiss} />
    );
    fireEvent.press(getByTestId('readiness-dismiss-button'));
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });

  it('does not call onPress when dismiss button is tapped', () => {
    const onPress = jest.fn();
    const onDismiss = jest.fn();
    const { getByTestId } = render(
      <ReadinessSurveyCard onPress={onPress} onDismiss={onDismiss} />
    );
    fireEvent.press(getByTestId('readiness-dismiss-button'));
    expect(onPress).not.toHaveBeenCalled();
  });
});
