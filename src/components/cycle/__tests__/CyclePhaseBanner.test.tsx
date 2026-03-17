/**
 * CyclePhaseBanner.test.tsx — Unit tests for CyclePhaseBanner.
 *
 * Tests:
 *   1. phaseColor() returns correct color for each phase
 *   2. Component renders null when cycleStatus is null
 *   3. Component renders phase text correctly when cycleStatus is provided
 */

import React from 'react';
import { render } from '@testing-library/react-native';
import CyclePhaseBanner, { phaseColor, phaseLabel } from '../CyclePhaseBanner';
import type { CycleStatusResult } from '@/src/domain/cycle/cycle-calculations';

// ─── phaseColor static helper ─────────────────────────────────────────────────

describe('phaseColor', () => {
  it('returns soft red for menstrual', () => {
    expect(phaseColor('menstrual')).toBe('#E57373');
  });

  it('returns green for follicular', () => {
    expect(phaseColor('follicular')).toBe('#81C784');
  });

  it('returns amber for ovulation', () => {
    expect(phaseColor('ovulation')).toBe('#FFB74D');
  });

  it('returns purple for luteal', () => {
    expect(phaseColor('luteal')).toBe('#BA68C8');
  });
});

// ─── phaseLabel static helper ─────────────────────────────────────────────────

describe('phaseLabel', () => {
  it('returns capitalized label for each phase', () => {
    expect(phaseLabel('menstrual')).toBe('Menstrual');
    expect(phaseLabel('follicular')).toBe('Follicular');
    expect(phaseLabel('ovulation')).toBe('Ovulation');
    expect(phaseLabel('luteal')).toBe('Luteal');
  });
});

// ─── Component rendering ──────────────────────────────────────────────────────

describe('CyclePhaseBanner component', () => {
  it('renders null when cycleStatus is null', () => {
    const { queryByTestId } = render(
      <CyclePhaseBanner cycleStatus={null} />
    );
    expect(queryByTestId('cycle-phase-banner')).toBeNull();
  });

  it('renders phase text when cycleStatus is provided', () => {
    const cycleStatus: CycleStatusResult = {
      currentPhase: 'follicular',
      cycleDay: 8,
      daysUntilNextPhase: 5,
      predictedNextPeriod: new Date('2026-04-10'),
      phaseStartDate: new Date('2026-03-10'),
      phaseEndDate: new Date('2026-03-18'),
    };

    const { getByTestId, getByText } = render(
      <CyclePhaseBanner cycleStatus={cycleStatus} />
    );

    expect(getByTestId('cycle-phase-banner')).toBeTruthy();
    expect(getByTestId('cycle-phase-label').props.children).toEqual([
      'Follicular',
      ' — Day ',
      8,
    ]);
  });

  it('renders ovulation phase with correct label', () => {
    const cycleStatus: CycleStatusResult = {
      currentPhase: 'ovulation',
      cycleDay: 14,
      daysUntilNextPhase: 2,
      predictedNextPeriod: new Date('2026-04-10'),
      phaseStartDate: new Date('2026-03-22'),
      phaseEndDate: new Date('2026-03-26'),
    };

    const { getByTestId } = render(
      <CyclePhaseBanner cycleStatus={cycleStatus} />
    );

    const label = getByTestId('cycle-phase-label');
    expect(label.props.children).toEqual(['Ovulation', ' — Day ', 14]);
  });

  it('renders menstrual phase with correct label', () => {
    const cycleStatus: CycleStatusResult = {
      currentPhase: 'menstrual',
      cycleDay: 2,
      daysUntilNextPhase: 3,
      predictedNextPeriod: new Date('2026-04-10'),
      phaseStartDate: new Date('2026-03-14'),
      phaseEndDate: new Date('2026-03-18'),
    };

    const { getByTestId } = render(
      <CyclePhaseBanner cycleStatus={cycleStatus} />
    );

    const label = getByTestId('cycle-phase-label');
    expect(label.props.children).toEqual(['Menstrual', ' — Day ', 2]);
  });
});
