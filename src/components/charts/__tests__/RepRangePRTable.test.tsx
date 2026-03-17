/**
 * RepRangePRTable.test.tsx — Unit tests for RepRangePRTable component.
 *
 * Verifies weight rendering with lb and kg units, dash for null weights,
 * and default unit behavior.
 */

// ---------------------------------------------------------------------------
// Module mocks — must come before imports
// ---------------------------------------------------------------------------

jest.mock('@/src/theme/colors', () => ({
  CREAM: '#F4F0DF',
  CREAM_LIGHT: '#FAF7EE',
  NAVY: '#0D1A40',
  NAVY_MEDIUM: '#3A4A6B',
  ORANGE: '#F2731A',
  ORANGE_LIGHT: '#FDE8D5',
  ORANGE_DARK: '#C45A10',
  RED: '#DC2626',
}));

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------

import React from 'react';
import { render, screen } from '@testing-library/react-native';
import { RepRangePRTable } from '../RepRangePRTable';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const singlePR = [{ repRange: 1, weight: 200, date: '2026-01-01' }];
const nullWeightPR = [{ repRange: 1, weight: null, date: null }];
const multiplePRs = [
  { repRange: 1, weight: 200, date: '2026-01-01' },
  { repRange: 3, weight: 185, date: '2026-02-01' },
  { repRange: 5, weight: 175, date: null },
];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('RepRangePRTable — weight unit rendering', () => {
  it('Test 1: renders weight with "lbs" suffix when weightUnit is lb', () => {
    render(<RepRangePRTable prs={singlePR} weightUnit="lb" />);
    expect(screen.getByText('200.0 lbs')).toBeTruthy();
  });

  it('Test 2: renders weight with "kg" suffix when weightUnit is kg', () => {
    render(<RepRangePRTable prs={singlePR} weightUnit="kg" />);
    // 200 lbs = 90.718... kg -> nearest 0.5 = 91.0 kg (actually: 90.718 * 2 = 181.436 -> round = 181 -> /2 = 90.5)
    // 200 * 0.453592 = 90.7185 kg -> round(90.7185 * 2) / 2 = round(181.437) / 2 = 181 / 2 = 90.5
    expect(screen.getByText('90.5 kg')).toBeTruthy();
  });

  it('Test 3: renders dash when weight is null', () => {
    render(<RepRangePRTable prs={nullWeightPR} weightUnit="lb" />);
    // null weight and null date both render as dash — getAllByText finds both
    expect(screen.getAllByText('—').length).toBeGreaterThanOrEqual(1);
  });

  it('Test 4: defaults to lbs when no weightUnit prop given', () => {
    render(<RepRangePRTable prs={singlePR} />);
    expect(screen.getByText('200.0 lbs')).toBeTruthy();
  });

  it('Test 5: renders multiple PRs with kg units', () => {
    render(<RepRangePRTable prs={multiplePRs} weightUnit="kg" />);
    // 200 lbs -> 90.5 kg, 185 lbs -> 83.9... -> nearest 0.5 = 84.0, 175 lbs -> 79.378... -> nearest 0.5 = 79.5
    expect(screen.getByText('90.5 kg')).toBeTruthy();
    // 185 lbs = 83.91... kg -> round(83.91 * 2) / 2 = round(167.82) / 2 = 168 / 2 = 84.0 kg
    expect(screen.getByText('84.0 kg')).toBeTruthy();
    // 175 lbs = 79.378... kg -> round(79.378 * 2) / 2 = round(158.757) / 2 = 159 / 2 = 79.5 kg
    expect(screen.getByText('79.5 kg')).toBeTruthy();
  });
});
