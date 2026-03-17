/**
 * WODDashboardCard.tsx — Dashboard card showing today's Workout of the Day.
 *
 * Props:
 *   - wod: WODRecord | null — today's WOD, or null if none
 *   - onStart: () => void — expands inline or navigates to WOD detail (read-only)
 *   - onViewAll: () => void — navigates to WOD archive browser
 *
 * Design: orange accent border, navy text, cream background (Art Deco card).
 * WOD exercises are string[] (plain text) — NOT a workout-session, no structured data.
 *
 * Uses getWODRepo().getWODForDate() pattern.
 */

import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import type { WODRecord } from '@/src/repositories/WODRepo';
import * as colors from '@/src/theme/colors';

interface WODDashboardCardProps {
  wod: WODRecord | null;
  onStart: () => void;
  onViewAll: () => void;
}

const DESCRIPTION_PREVIEW_LENGTH = 100;

export function WODDashboardCard({
  wod,
  onStart,
  onViewAll,
}: WODDashboardCardProps): React.JSX.Element | null {
  const [expanded, setExpanded] = useState(false);

  // If no WOD today, render nothing
  if (wod == null) {
    return null;
  }

  const descriptionPreview =
    wod.description.length > DESCRIPTION_PREVIEW_LENGTH
      ? `${wod.description.slice(0, DESCRIPTION_PREVIEW_LENGTH)}...`
      : wod.description;

  function handleStart(): void {
    // Expand inline to show exercise list, then call onStart
    setExpanded(true);
    onStart();
  }

  return (
    <View style={styles.card} testID="wod-dashboard-card">
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.titleRow}>
          <View style={styles.wodLabel}>
            <Text style={styles.wodLabelText}>TODAY'S WOD</Text>
          </View>
          {wod.scoringType != null && (
            <View style={styles.scoringBadge}>
              <Text style={styles.scoringBadgeText}>{wod.scoringType.toUpperCase()}</Text>
            </View>
          )}
        </View>
        <Text style={styles.wodName}>{wod.name}</Text>
      </View>

      {/* Description preview */}
      <Text style={styles.description}>
        {expanded ? wod.description : descriptionPreview}
      </Text>

      {/* Exercise list (shown when expanded) */}
      {expanded && wod.exercises.length > 0 && (
        <View style={styles.exerciseList} testID="wod-exercises">
          {wod.exercises.map((exercise, i) => (
            <Text key={i} style={styles.exerciseItem}>
              {'\u2022'} {exercise}
            </Text>
          ))}
        </View>
      )}

      {/* Action buttons */}
      <View style={styles.actions}>
        <TouchableOpacity
          style={styles.startButton}
          onPress={handleStart}
          activeOpacity={0.85}
          testID="wod-start-button"
        >
          <Text style={styles.startButtonText}>{expanded ? 'Hide' : 'Start'}</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.viewAllButton}
          onPress={onViewAll}
          activeOpacity={0.75}
          testID="wod-view-all-button"
        >
          <Text style={styles.viewAllText}>View All</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 14,
    borderWidth: 2,
    borderColor: colors.ORANGE,
    padding: 16,
    gap: 12,
    shadowColor: colors.ORANGE_DARK,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.12,
    shadowRadius: 6,
    elevation: 3,
  },
  header: {
    gap: 6,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  wodLabel: {
    backgroundColor: colors.ORANGE,
    borderRadius: 4,
    paddingVertical: 2,
    paddingHorizontal: 7,
  },
  wodLabelText: {
    fontSize: 10,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 1,
  },
  scoringBadge: {
    borderWidth: 1,
    borderColor: colors.ORANGE,
    borderRadius: 4,
    paddingVertical: 2,
    paddingHorizontal: 7,
  },
  scoringBadgeText: {
    fontSize: 10,
    fontWeight: '700',
    color: colors.ORANGE_DARK,
    letterSpacing: 0.5,
  },
  wodName: {
    fontSize: 20,
    fontWeight: '800',
    color: colors.NAVY,
    letterSpacing: 0.3,
  },
  description: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
  },
  exerciseList: {
    gap: 4,
    paddingTop: 4,
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
  },
  exerciseItem: {
    fontSize: 13,
    color: colors.NAVY,
    lineHeight: 20,
  },
  actions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 4,
  },
  startButton: {
    flex: 1,
    backgroundColor: colors.ORANGE,
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  startButtonText: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
  viewAllButton: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: colors.NAVY,
    alignItems: 'center',
    justifyContent: 'center',
  },
  viewAllText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.NAVY,
    letterSpacing: 0.3,
  },
});
