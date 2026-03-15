/**
 * maxes.tsx — Maxes tab: exercise list with best estimated 1RM.
 *
 * Data flow:
 *   ExerciseMaxRepo.getAllMaxes(uid) → ExerciseMax[]
 *   → group by exerciseId → compute best estimated1RM per exercise
 *   → searchable/alphabetically sorted FlatList
 *   → tap → exercise-detail screen
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getExerciseMaxRepo } from '@/src/repositories/ExerciseMaxRepo';
import type { ExerciseMax } from '@/src/domain/pr-detection/pr-types';
import * as colors from '@/src/theme/colors';

// ─── ExerciseSummary — best 1RM per exercise ─────────────────────────────────

export interface ExerciseSummary {
  exerciseId: string;
  exerciseName: string;
  best1RM: number;
  lastAchievedAt: string;
}

/**
 * Groups ExerciseMax records by exerciseId and computes the best estimated1RM per exercise.
 * Returns alphabetically sorted list.
 */
export function buildExerciseSummaries(maxes: ExerciseMax[]): ExerciseSummary[] {
  const map = new Map<string, ExerciseSummary>();

  for (const max of maxes) {
    const existing = map.get(max.exerciseId);
    if (!existing) {
      map.set(max.exerciseId, {
        exerciseId: max.exerciseId,
        exerciseName: max.exerciseName,
        best1RM: max.estimated1RM,
        lastAchievedAt: max.achievedAt,
      });
    } else if (max.estimated1RM > existing.best1RM) {
      existing.best1RM = max.estimated1RM;
      existing.lastAchievedAt = max.achievedAt;
    }
  }

  return Array.from(map.values()).sort((a, b) =>
    a.exerciseName.localeCompare(b.exerciseName)
  );
}

// ─── MaxesScreen ──────────────────────────────────────────────────────────────

export default function MaxesScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const router = useRouter();

  const [allMaxes, setAllMaxes] = useState<ExerciseMax[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const loadMaxes = useCallback(async (showRefreshing = false): Promise<void> => {
    if (!user) return;
    if (showRefreshing) setIsRefreshing(true);

    try {
      const repo = getExerciseMaxRepo(isGuest);
      const maxes = await repo.getAllMaxes(user.uid);
      setAllMaxes(maxes);
    } catch (err) {
      console.error('[MaxesScreen] Failed to load maxes:', err);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [user, isGuest]);

  useEffect(() => {
    void loadMaxes();
  }, [loadMaxes]);

  const summaries = buildExerciseSummaries(allMaxes);

  const filtered =
    searchQuery.trim() === ''
      ? summaries
      : summaries.filter((s) =>
          s.exerciseName.toLowerCase().includes(searchQuery.toLowerCase())
        );

  function handleExerciseTap(summary: ExerciseSummary): void {
    router.push({
      pathname: '/exercise-detail',
      params: { exerciseId: summary.exerciseId, exerciseName: summary.exerciseName },
    });
  }

  if (isLoading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Search bar */}
      <View style={styles.searchContainer}>
        <TextInput
          style={styles.searchInput}
          placeholder="Search exercises..."
          placeholderTextColor={colors.GREY}
          value={searchQuery}
          onChangeText={setSearchQuery}
          clearButtonMode="while-editing"
          autoCapitalize="none"
          autoCorrect={false}
        />
      </View>

      {summaries.length === 0 ? (
        <View style={styles.emptyState}>
          <Text style={styles.emptyIcon}>🏆</Text>
          <Text style={styles.emptyTitle}>No maxes tracked yet</Text>
          <Text style={styles.emptySubtitle}>
            Complete a workout to start tracking personal records.
          </Text>
        </View>
      ) : filtered.length === 0 ? (
        <View style={styles.emptyState}>
          <Text style={styles.emptyTitle}>No exercises match "{searchQuery}"</Text>
        </View>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(item) => item.exerciseId}
          renderItem={({ item }) => (
            <ExerciseRow summary={item} onPress={handleExerciseTap} />
          )}
          refreshControl={
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={() => void loadMaxes(true)}
              tintColor={colors.ORANGE}
              colors={[colors.ORANGE]}
            />
          }
          contentContainerStyle={styles.listContent}
          ItemSeparatorComponent={() => <View style={styles.separator} />}
        />
      )}
    </View>
  );
}

// ─── ExerciseRow ──────────────────────────────────────────────────────────────

function ExerciseRow({
  summary,
  onPress,
}: {
  summary: ExerciseSummary;
  onPress: (s: ExerciseSummary) => void;
}): React.JSX.Element {
  return (
    <TouchableOpacity
      style={styles.exerciseRow}
      onPress={() => onPress(summary)}
      activeOpacity={0.7}
    >
      <View style={styles.exerciseInfo}>
        <Text style={styles.exerciseName}>{summary.exerciseName}</Text>
        <Text style={styles.exerciseDate}>
          Last PR: {formatDate(summary.lastAchievedAt)}
        </Text>
      </View>
      <View style={styles.rmContainer}>
        <Text style={styles.rmValue}>{Math.round(summary.best1RM)}</Text>
        <Text style={styles.rmUnit}>lbs 1RM</Text>
      </View>
      <Text style={styles.chevron}>›</Text>
    </TouchableOpacity>
  );
}

function formatDate(isoStr: string): string {
  const date = new Date(isoStr.includes('T') ? isoStr : isoStr + 'T12:00:00');
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
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
  searchContainer: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: colors.CREAM,
    borderBottomWidth: 1,
    borderBottomColor: '#E8E4D6',
  },
  searchInput: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 9,
    fontSize: 15,
    color: colors.NAVY,
    borderWidth: 1,
    borderColor: '#E0DCD0',
  },
  listContent: {
    paddingBottom: 24,
  },
  exerciseRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    backgroundColor: colors.CREAM,
    gap: 12,
  },
  exerciseInfo: {
    flex: 1,
    gap: 3,
  },
  exerciseName: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
  },
  exerciseDate: {
    fontSize: 12,
    color: colors.GREY,
    fontWeight: '500',
  },
  rmContainer: {
    alignItems: 'flex-end',
    gap: 1,
  },
  rmValue: {
    fontSize: 22,
    fontWeight: '800',
    color: colors.ORANGE,
  },
  rmUnit: {
    fontSize: 11,
    color: colors.NAVY_MEDIUM,
    fontWeight: '600',
    letterSpacing: 0.3,
  },
  chevron: {
    fontSize: 20,
    color: colors.GREY,
    fontWeight: '300',
  },
  separator: {
    height: 1,
    backgroundColor: '#E8E4D6',
    marginLeft: 16,
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
});
