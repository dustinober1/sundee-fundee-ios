/**
 * app/(app)/wods/index.tsx — WOD Archive Browser.
 *
 * Shows recent WODs (last 30) fetched via getWODRepo().getRecentWODs(30).
 * Today's WOD is highlighted at the top.
 * Each card expands to show full exercise list and description.
 * If WOD has scoringType, shows "Record Result" link to benchmark recording.
 *
 * Uses date-fns format() for local date handling (not UTC — per pitfall 4).
 */

import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { format } from 'date-fns';
import { getWODRepo, type WODRecord } from '@/src/repositories/WODRepo';
import * as colors from '@/src/theme/colors';

const WOD_ARCHIVE_LIMIT = 30;

function formatDisplayDate(dateStr: string): string {
  // dateStr is 'yyyy-MM-dd'; parse at noon to avoid UTC boundary issues
  const date = new Date(`${dateStr}T12:00:00`);
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

interface WODCardProps {
  wod: WODRecord;
  isToday: boolean;
  onRecordResult: (wod: WODRecord) => void;
}

function WODCard({ wod, isToday, onRecordResult }: WODCardProps): React.JSX.Element {
  const [expanded, setExpanded] = useState(isToday);

  return (
    <TouchableOpacity
      style={[styles.card, isToday && styles.cardToday]}
      onPress={() => setExpanded((prev) => !prev)}
      activeOpacity={0.8}
      testID={`wod-card-${wod.id}`}
    >
      {/* Date row */}
      <View style={styles.cardHeader}>
        <View style={styles.dateRow}>
          {isToday && (
            <View style={styles.todayBadge}>
              <Text style={styles.todayBadgeText}>TODAY</Text>
            </View>
          )}
          <Text style={[styles.cardDate, isToday && styles.cardDateToday]}>
            {formatDisplayDate(wod.date)}
          </Text>
        </View>
        {wod.scoringType != null && (
          <View style={styles.scoringBadge}>
            <Text style={styles.scoringBadgeText}>{wod.scoringType.toUpperCase()}</Text>
          </View>
        )}
      </View>

      {/* WOD name */}
      <Text style={styles.wodName}>{wod.name}</Text>

      {/* Description */}
      <Text style={styles.wodDescription} numberOfLines={expanded ? undefined : 2}>
        {wod.description}
      </Text>

      {/* Expanded: exercise list */}
      {expanded && wod.exercises.length > 0 && (
        <View style={styles.exerciseList}>
          {wod.exercises.map((exercise, i) => (
            <Text key={i} style={styles.exerciseItem}>
              {'\u2022'} {exercise}
            </Text>
          ))}
        </View>
      )}

      {/* Record result button (only if has scoring type) */}
      {expanded && wod.scoringType != null && (
        <TouchableOpacity
          style={styles.recordButton}
          onPress={() => onRecordResult(wod)}
          activeOpacity={0.8}
          testID={`wod-record-${wod.id}`}
        >
          <Text style={styles.recordButtonText}>Record Result</Text>
        </TouchableOpacity>
      )}

      {/* Expand/collapse hint */}
      <Text style={styles.expandHint}>{expanded ? 'Tap to collapse' : 'Tap to expand'}</Text>
    </TouchableOpacity>
  );
}

export default function WODArchiveScreen(): React.JSX.Element {
  const router = useRouter();
  const [wods, setWods] = useState<WODRecord[]>([]);
  const [loading, setLoading] = useState(true);

  // Today's date in local time using date-fns (not UTC)
  const todayDate = format(new Date(), 'yyyy-MM-dd');

  const loadWODs = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      const recent = await getWODRepo().getRecentWODs(WOD_ARCHIVE_LIMIT);
      // Sort: today first, then by date descending
      const sorted = [...recent].sort((a, b) => {
        if (a.date === todayDate) return -1;
        if (b.date === todayDate) return 1;
        return b.date.localeCompare(a.date);
      });
      setWods(sorted);
    } catch {
      setWods([]);
    } finally {
      setLoading(false);
    }
  }, [todayDate]);

  useFocusEffect(
    useCallback(() => {
      void loadWODs();
    }, [loadWODs]),
  );

  function handleRecordResult(wod: WODRecord): void {
    // Navigate to the benchmark detail page for this WOD's scoring type
    // We use the WOD name to create an ad-hoc benchmark navigation
    router.push({
      pathname: '/(app)/benchmarks/[id]',
      params: {
        id: `wod-${wod.id}`,
        name: wod.name,
        description: wod.description,
        scoringType: wod.scoringType ?? 'reps',
        isPredefined: '0',
      },
    });
  }

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator color={colors.ORANGE} size="large" />
        <Text style={styles.loadingText}>Loading WODs...</Text>
      </View>
    );
  }

  if (wods.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyTitle}>No WODs Available</Text>
        <Text style={styles.emptyBody}>
          WODs are loaded from the server. Check back soon!
        </Text>
      </View>
    );
  }

  return (
    <FlatList
      style={styles.list}
      contentContainerStyle={styles.listContent}
      data={wods}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => (
        <WODCard
          wod={item}
          isToday={item.date === todayDate}
          onRecordResult={handleRecordResult}
        />
      )}
      showsVerticalScrollIndicator={false}
      ListHeaderComponent={
        <Text style={styles.archiveHeader}>WOD Archive</Text>
      }
    />
  );
}

const styles = StyleSheet.create({
  list: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  listContent: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 40,
    gap: 12,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
    gap: 12,
  },
  loadingText: {
    fontSize: 14,
    color: colors.GREY,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
    paddingHorizontal: 32,
    gap: 12,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.NAVY,
  },
  emptyBody: {
    fontSize: 14,
    color: colors.GREY,
    textAlign: 'center',
    lineHeight: 20,
  },
  archiveHeader: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1.2,
    textTransform: 'uppercase',
    marginBottom: 4,
  },
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 14,
    gap: 8,
  },
  cardToday: {
    borderWidth: 2,
    borderColor: colors.ORANGE,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dateRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  todayBadge: {
    backgroundColor: colors.ORANGE,
    borderRadius: 4,
    paddingVertical: 2,
    paddingHorizontal: 6,
  },
  todayBadgeText: {
    fontSize: 9,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 1,
  },
  cardDate: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.GREY,
  },
  cardDateToday: {
    color: colors.NAVY_MEDIUM,
  },
  scoringBadge: {
    borderWidth: 1,
    borderColor: colors.ORANGE,
    borderRadius: 4,
    paddingVertical: 2,
    paddingHorizontal: 6,
  },
  scoringBadgeText: {
    fontSize: 10,
    fontWeight: '700',
    color: colors.ORANGE_DARK,
    letterSpacing: 0.5,
  },
  wodName: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
  },
  wodDescription: {
    fontSize: 12,
    color: colors.NAVY_MEDIUM,
    lineHeight: 17,
  },
  exerciseList: {
    gap: 3,
    paddingTop: 6,
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
  },
  exerciseItem: {
    fontSize: 13,
    color: colors.NAVY,
    lineHeight: 19,
  },
  recordButton: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 8,
    paddingVertical: 10,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.ORANGE,
    marginTop: 4,
  },
  recordButtonText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.ORANGE_DARK,
    letterSpacing: 0.3,
  },
  expandHint: {
    fontSize: 11,
    color: colors.GREY,
    textAlign: 'right',
    marginTop: 2,
  },
});
