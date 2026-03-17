/**
 * AdaptationChip.tsx
 *
 * Displays a summary pill showing what context has been automatically incorporated
 * into the AI workout generation: cycle phase, active injuries, and readiness score.
 *
 * Returns null if no adaptations apply (no cycle phase, no injuries, no readiness).
 *
 * Static helper buildAdaptationText is exported for unit testing.
 */

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import type { CyclePhase } from '@/src/domain/types';
import type { InjuryProfileRecord } from '@/src/repositories/InjuryRepo';
import type { ReadinessSurveyRecord } from '@/src/repositories/ReadinessRepo';
import * as colors from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface AdaptationChipProps {
  cyclePhase?: CyclePhase;
  injuries?: InjuryProfileRecord[];
  readiness?: ReadinessSurveyRecord | null;
}

// ─── Static helpers ───────────────────────────────────────────────────────────

function cyclePhaseLabel(phase: CyclePhase): string {
  switch (phase) {
    case 'menstrual': return 'Menstrual phase';
    case 'follicular': return 'Follicular phase';
    case 'ovulation': return 'Ovulation phase';
    case 'luteal': return 'Luteal phase';
  }
}

function injuryLabel(injury: InjuryProfileRecord): string {
  // Use location if provided, else fall back to bodyLocation formatted
  if (injury.location) return injury.location;
  return injury.bodyLocation
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (s) => s.toUpperCase())
    .trim();
}

/**
 * Build the adaptation summary text from context.
 * Returns null if nothing to show.
 * Exported as a static helper for unit testing without rendering.
 */
export function buildAdaptationText(
  cyclePhase: CyclePhase | undefined,
  injuries: InjuryProfileRecord[] | undefined,
  readiness: ReadinessSurveyRecord | null | undefined,
): string | null {
  const parts: string[] = [];

  if (cyclePhase) {
    parts.push(cyclePhaseLabel(cyclePhase));
  }

  if (injuries && injuries.length > 0) {
    const activeInjuries = injuries.filter((i) => i.recoveryPhase !== 'resolved');
    for (const injury of activeInjuries) {
      parts.push(injuryLabel(injury));
    }
  }

  if (readiness != null) {
    const score = Math.round(readiness.result.score * 10);
    parts.push(`Readiness ${score}/10`);
  }

  if (parts.length === 0) return null;
  return `Adapting for: ${parts.join(' · ')}`;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function AdaptationChip({
  cyclePhase,
  injuries,
  readiness,
}: AdaptationChipProps): React.JSX.Element | null {
  const text = buildAdaptationText(cyclePhase, injuries, readiness);
  if (!text) return null;

  return (
    <View style={styles.chip} testID="adaptation-chip">
      <Text style={styles.chipText}>{text}</Text>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  chip: {
    alignSelf: 'flex-start',
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 6,
    marginTop: 8,
  },
  chipText: {
    color: colors.NAVY,
    fontSize: 13,
    fontWeight: '500',
    lineHeight: 18,
  },
});
