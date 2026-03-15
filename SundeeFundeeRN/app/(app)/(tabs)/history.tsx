/**
 * history.tsx — History tab screen.
 *
 * Displays all completed workouts grouped by date with source filtering,
 * swipe-to-delete, and pull-to-refresh.
 *
 * Data flow:
 *   WorkoutRepo.getHistory(uid) → WorkoutRecord[] → HistoryItem[]
 *   → filterHistoryBySource → groupHistoryByDate → SectionList
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  SectionList,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getWorkoutRepo, type WorkoutRecord } from '@/src/repositories/WorkoutRepo';
import type { HistoryItem } from '@/src/domain/history/history-item';
import type { HistorySourceFilter } from '@/src/domain/history/history-filter';
import {
  filterHistoryBySource,
  groupHistoryByDate,
  type HistoryDateGroup,
} from '@/src/domain/history/history-filter';
import { SourceFilter } from '@/src/components/history/SourceFilter';
import { HistoryCard } from '@/src/components/history/HistoryCard';
import * as colors from '@/src/theme/colors';

// ─── WorkoutRecord → HistoryItem conversion ──────────────────────────────────

export function workoutRecordToHistoryItem(record: WorkoutRecord): HistoryItem {
  let source: HistoryItem['source'];

  switch (record.source) {
    case 'ai':
      source = { kind: 'aiWorkout' };
      break;
    case 'program':
      source = { kind: 'program', name: record.workoutName ?? 'Program Workout' };
      break;
    case 'custom':
    default:
      source = { kind: 'custom' };
      break;
  }

  const exerciseCount =
    record.exerciseCount ??
    record.exercises?.length ??
    record.workout?.exercises?.length ??
    0;

  return {
    id: record.id,
    title: record.workoutName ?? (record.source === 'ai' ? 'AI Workout' : 'Custom Workout'),
    source,
    completedAt: new Date(record.completedAt),
    exerciseCount,
    durationSeconds: record.durationSeconds,
    originalID: record.id,
    isAIWorkout: record.source === 'ai',
    totalVolume: record.totalVolume,
    workoutName: record.workoutName,
  };
}

// ─── HistoryScreen ────────────────────────────────────────────────────────────

export default function HistoryScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const router = useRouter();

  const [historyItems, setHistoryItems] = useState<HistoryItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [activeFilter, setActiveFilter] = useState<HistorySourceFilter>('all');

  const loadHistory = useCallback(async (showRefreshing = false): Promise<void> => {
    if (!user) return;
    if (showRefreshing) setIsRefreshing(true);

    try {
      const repo = getWorkoutRepo(isGuest);
      const records = await repo.getHistory(user.uid);
      const items = records.map(workoutRecordToHistoryItem);
      setHistoryItems(items);
    } catch (err) {
      console.error('[HistoryScreen] Failed to load history:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [user, isGuest]);

  useEffect(() => {
    void loadHistory();
  }, [loadHistory]);

  function handleDelete(item: HistoryItem): void {
    if (!user) return;

    // Optimistic update — remove from local state immediately
    setHistoryItems((prev) => prev.filter((i) => i.id !== item.id));

    // Persist deletion
    const repo = getWorkoutRepo(isGuest);
    void repo.deleteWorkout(user.uid, item.originalID).catch((err) => {
      console.error('[HistoryScreen] Delete failed:', err);
      // Re-load on failure to restore accurate state
      void loadHistory();
    });
  }

  function handleCardPress(item: HistoryItem): void {
    router.push({
      pathname: '/workout-detail',
      params: { workoutId: item.originalID },
    });
  }

  // Apply source filter then group by date
  const filteredItems = filterHistoryBySource(historyItems, activeFilter);
  const sections: HistoryDateGroup[] = groupHistoryByDate(filteredItems);

  const sectionData = sections.map((group) => ({
    title: group.label,
    data: group.items,
  }));

  if (isLoading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={styles.root}>
      <View style={styles.container}>
        <SourceFilter activeFilter={activeFilter} onFilterChange={setActiveFilter} />

        {historyItems.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyIcon}>🏋️</Text>
            <Text style={styles.emptyTitle}>No workouts yet</Text>
            <Text style={styles.emptySubtitle}>
              Start your first one to see your history here.
            </Text>
            <TouchableOpacity
              style={styles.emptyButton}
              onPress={() => router.push('/timer-mode')}
              activeOpacity={0.8}
            >
              <Text style={styles.emptyButtonText}>Start Workout</Text>
            </TouchableOpacity>
          </View>
        ) : filteredItems.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyTitle}>No workouts match this filter</Text>
            <Text style={styles.emptySubtitle}>
              Try switching to "All" to see everything.
            </Text>
          </View>
        ) : (
          <SectionList
            sections={sectionData}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <HistoryCard
                item={item}
                onPress={handleCardPress}
                onDelete={handleDelete}
              />
            )}
            renderSectionHeader={({ section: { title } }) => (
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionHeaderText}>{title}</Text>
              </View>
            )}
            refreshControl={
              <RefreshControl
                refreshing={isRefreshing}
                onRefresh={() => void loadHistory(true)}
                tintColor={colors.ORANGE}
                colors={[colors.ORANGE]}
              />
            }
            contentContainerStyle={styles.listContent}
            stickySectionHeadersEnabled={false}
          />
        )}
      </View>
    </GestureHandlerRootView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
  },
  listContent: {
    paddingBottom: 24,
  },
  sectionHeader: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 6,
    backgroundColor: colors.CREAM,
  },
  sectionHeaderText: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.NAVY_MEDIUM,
    letterSpacing: 0.8,
    textTransform: 'uppercase',
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    gap: 12,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 8,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.NAVY,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 15,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
    lineHeight: 22,
  },
  emptyButton: {
    marginTop: 12,
    backgroundColor: colors.ORANGE,
    paddingHorizontal: 28,
    paddingVertical: 12,
    borderRadius: 24,
  },
  emptyButtonText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
});
