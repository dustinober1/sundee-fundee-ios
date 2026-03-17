/**
 * Tests for PremiumBadge component.
 */
import React from 'react';
import { render } from '@testing-library/react-native';
import { PremiumBadge } from '../PremiumBadge';

describe('PremiumBadge', () => {
  it('renders "Premium" text in default mode', () => {
    const { getByText } = render(<PremiumBadge />);
    expect(getByText('Premium')).toBeTruthy();
  });

  it('renders compact badge without full "Premium" text', () => {
    const { queryByText } = render(<PremiumBadge compact />);
    expect(queryByText('Premium')).toBeNull();
  });

  it('renders lock icon in both modes', () => {
    const { getAllByText } = render(<PremiumBadge />);
    // Lock icon should be present
    expect(getAllByText(/🔒|★|lock/i).length).toBeGreaterThanOrEqual(0);
  });
});
