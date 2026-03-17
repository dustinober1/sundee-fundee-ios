/**
 * HistoryCard.tsx — Card component for a single workout history item.
 *
 * Shows: workout name/title, source badge (colored pill), duration,
 * exercise count, total volume.
 *
 * Source badge colors:
 *   AI = blue (#2563EB)
 *   Program = green (#16A34A)
 *   Custom = ORANGE
 *
 * Swipe left to reveal red delete button.
 * Delete uses Alert.alert on native, window.confirm on web.
 */

import React, { useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Platform,
  Alert,
} from 'react-native';
import { Swipeable, GestureHandlerRootView } from 'react-native-gesture-handler';
import type { HistoryItem } from '@/src/domain/history/history-item';
import { getSourceLabel } from '@/src/domain/history/history-item';
import { formatWeight } from '@/src/utils/formatWeight';
import type { WeightUnit } from '@/src/domain/types';
import * as colors from '@/src/theme/colors';

// ─── Badge color helpers ────────────────────────────────────────────────────

function getBadgeColor(source: HistoryItem['source']): string {
  switch (source.kind) {
    case 'aiWorkout':
      return '#2563EB';
    case 'program':
      return '#16A34A';
    case 'custom':
      return colors.ORANGE;
  }
}

// ─── Duration formatting ────────────────────────────────────────────────────

export function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

// ─── Volume formatting ──────────────────────────────────────────────────────

export function formatVolume(volume: number | undefined, unit: WeightUnit = 'lb'): string | null {
  if (volume === undefined) return null;
  return formatWeight(volume, unit);
}

// ─── Props ───────────────────────────────────────────────────────────────────

interface HistoryCardProps {
  item: HistoryItem;
  onPress: (item: HistoryItem) => void;
  onDelete: (item: HistoryItem) => void;
  weightUnit?: WeightUnit;
}

// ─── HistoryCard ─────────────────────────────────────────────────────────────

export function HistoryCard({ item, onPress, onDelete, weightUnit = 'lb' }: HistoryCardProps): React.JSX.Element {
  const swipeableRef = useRef<Swipeable>(null);

  function confirmDelete(): void {
    const title = 'Delete Workout';
    const message = `Delete "${item.title}"? This cannot be undone.`;

    if (Platform.OS === 'web') {
      if (window.confirm(message)) {
        onDelete(item);
      }
      swipeableRef.current?.close();
    } else {
      Alert.alert(title, message, [
        {
          text: 'Cancel',
          style: 'cancel',
          onPress: () => swipeableRef.current?.close(),
        },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => {
            swipeableRef.current?.close();
            onDelete(item);
          },
        },
      ]);
    }
  }

  function renderRightActions(): React.JSX.Element {
    return (
      <TouchableOpacity style={styles.deleteAction} onPress={confirmDelete} activeOpacity={0.8}>
        <Text style={styles.deleteText}>Delete</Text>
      </TouchableOpacity>
    );
  }

  const badgeColor = getBadgeColor(item.source);
  const sourceLabel = getSourceLabel(item.source);
  const durationStr = formatDuration(item.durationSeconds);
  const volumeStr = formatVolume(item.totalVolume, weightUnit);
  const displayTitle = item.workoutName ?? item.title;

  return (
    <Swipeable
      ref={swipeableRef}
      renderRightActions={renderRightActions}
      overshootRight={false}
    >
      <TouchableOpacity style={styles.card} onPress={() => onPress(item)} activeOpacity={0.8}>
        <View style={styles.header}>
          <Text style={styles.title} numberOfLines={1}>{displayTitle}</Text>
          <View style={[styles.badge, { backgroundColor: badgeColor }]}>
            <Text style={styles.badgeText}>{sourceLabel}</Text>
          </View>
        </View>

        <View style={styles.metaRow}>
          <MetaStat icon="⏱" value={durationStr} />
          <MetaStat icon="🏋️" value={`${item.exerciseCount} exercises`} />
          {volumeStr !== null && <MetaStat icon="📊" value={volumeStr} />}
        </View>
      </TouchableOpacity>
    </Swipeable>
  );
}

// ─── MetaStat helper ─────────────────────────────────────────────────────────

function MetaStat({ icon, value }: { icon: string; value: string }): React.JSX.Element {
  return (
    <View style={styles.metaStat}>
      <Text style={styles.metaIcon}>{icon}</Text>
      <Text style={styles.metaText}>{value}</Text>
    </View>
  );
}

// ─── Styles ──────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    marginHorizontal: 16,
    marginVertical: 6,
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E8E4D6',
    shadowColor: colors.NAVY,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 3,
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 10,
    gap: 8,
  },
  title: {
    flex: 1,
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.2,
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: 12,
    flexShrink: 0,
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  metaRow: {
    flexDirection: 'row',
    gap: 14,
    flexWrap: 'wrap',
  },
  metaStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  metaIcon: {
    fontSize: 12,
  },
  metaText: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    fontWeight: '500',
  },
  deleteAction: {
    backgroundColor: colors.RED,
    justifyContent: 'center',
    alignItems: 'center',
    width: 80,
    marginVertical: 6,
    marginRight: 16,
    borderRadius: 12,
  },
  deleteText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
  },
});
