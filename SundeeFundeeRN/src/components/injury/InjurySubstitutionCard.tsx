/**
 * InjurySubstitutionCard.tsx — Displays exercise substitutions for an injury.
 *
 * Shows a summary count ("N exercises modified for [location]") and an
 * expandable list of original → substituted exercise pairs.
 *
 * Props:
 *   injury: InjuryProfile
 *   substitutions: Array of { original: string; replacement: string }
 */

import React, { useState } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import type { InjuryProfile } from '@/src/domain/types/index';
import { BodyMap } from './BodyMap';
import * as colors from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface SubstitutionPair {
  original: string;
  replacement: string;
}

interface InjurySubstitutionCardProps {
  injury: InjuryProfile;
  substitutions: SubstitutionPair[];
}

// ─── Component ────────────────────────────────────────────────────────────────

export function InjurySubstitutionCard({
  injury,
  substitutions,
}: InjurySubstitutionCardProps): React.JSX.Element {
  const [expanded, setExpanded] = useState(false);
  const locationLabel = BodyMap.locationLabel(injury.bodyLocation);
  const count = substitutions.length;

  if (count === 0) {
    return (
      <View style={styles.card}>
        <Text style={styles.title}>Exercise Substitutions</Text>
        <Text style={styles.emptyText}>
          No substitutions needed for {locationLabel} at this phase.
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.card}>
      <Pressable
        style={styles.header}
        onPress={() => setExpanded((prev) => !prev)}
        accessibilityRole="button"
        accessibilityState={{ expanded }}
        accessibilityLabel={`${count} exercise${count !== 1 ? 's' : ''} modified for ${locationLabel}. Tap to ${expanded ? 'collapse' : 'expand'}`}
      >
        <View style={styles.headerLeft}>
          <Text style={styles.title}>Exercise Substitutions</Text>
          <Text style={styles.summary}>
            {count} exercise{count !== 1 ? 's' : ''} modified for {locationLabel}
          </Text>
        </View>
        <Text style={styles.chevron}>{expanded ? '▲' : '▼'}</Text>
      </Pressable>

      {expanded && (
        <View style={styles.list}>
          <View style={styles.listHeader}>
            <Text style={styles.colHeader}>Original</Text>
            <Text style={styles.arrow}> </Text>
            <Text style={styles.colHeader}>Substitution</Text>
          </View>
          {substitutions.map((sub, idx) => (
            <View key={idx} style={[styles.subRow, idx === substitutions.length - 1 && styles.subRowLast]}>
              <Text style={styles.originalExercise} numberOfLines={2}>{sub.original}</Text>
              <Text style={styles.arrow}>→</Text>
              <Text style={styles.replacementExercise} numberOfLines={2}>{sub.replacement}</Text>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E8E4D6',
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
  },
  headerLeft: {
    flex: 1,
    gap: 3,
  },
  title: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
  },
  summary: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
  },
  chevron: {
    fontSize: 12,
    color: colors.NAVY_MEDIUM,
    marginLeft: 8,
  },
  emptyText: {
    fontSize: 13,
    color: colors.GREY,
    padding: 16,
    paddingTop: 4,
  },
  list: {
    borderTopWidth: 1,
    borderTopColor: '#E8E4D6',
    paddingHorizontal: 16,
    paddingBottom: 12,
  },
  listHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 10,
    paddingBottom: 6,
  },
  colHeader: {
    flex: 1,
    fontSize: 11,
    fontWeight: '700',
    color: colors.NAVY_MEDIUM,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  subRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
  },
  subRowLast: {
    // no extra styling needed
  },
  originalExercise: {
    flex: 1,
    fontSize: 13,
    color: colors.NAVY,
    fontWeight: '500',
  },
  arrow: {
    fontSize: 14,
    color: colors.ORANGE,
    fontWeight: '700',
    marginHorizontal: 8,
  },
  replacementExercise: {
    flex: 1,
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    fontWeight: '500',
  },
});
