/**
 * exercise-picker.tsx — Modal exercise browser.
 *
 * Combines MuscleGroupGrid and ExerciseSearch:
 * - Top: search bar (always visible)
 * - Below: if no search query, show muscle group grid; if searching, show filtered results
 * - On exercise select: navigate back with selected exercise params
 * - Presented as modal (Stack.Screen with presentation: 'modal' in parent _layout)
 *
 * Accepts optional `muscleGroup` search param for pre-filtered views.
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
} from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { MuscleGroupGrid } from '@/src/components/exercises/MuscleGroupGrid';
import { ExerciseSearch } from '@/src/components/exercises/ExerciseSearch';
import { useSession } from '@/src/auth/AuthContext';
import { getExerciseRepo } from '@/src/repositories/ExerciseRepo';
import type { Exercise, MuscleGroup } from '@/src/domain/exercises/exercise-types';
import exercises from '@/src/resources/exercises.json';
import { CREAM, NAVY, NAVY_MEDIUM, ORANGE, GREY_LIGHT } from '@/src/theme/colors';

// Cast bundled exercises to the right type
const BUNDLED_EXERCISES = exercises as Exercise[];

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function ExercisePickerScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const params = useLocalSearchParams<{ muscleGroup?: string }>();

  const [customExercises, setCustomExercises] = useState<Exercise[]>([]);
  const [loadingCustom, setLoadingCustom] = useState(true);
  const [selectedMuscleGroup, setSelectedMuscleGroup] = useState<MuscleGroup | null>(
    (params.muscleGroup as MuscleGroup) ?? null,
  );
  const [isCreating, setIsCreating] = useState(false);

  // Combine bundled + custom exercises
  const allExercises: Exercise[] = [...BUNDLED_EXERCISES, ...customExercises];

  // Load custom exercises on mount
  useEffect(() => {
    async function loadCustom(): Promise<void> {
      try {
        const repo = getExerciseRepo(isGuest);
        const uid = user?.uid ?? '';
        const customs = await repo.getCustomExercises(uid);
        setCustomExercises(customs);
      } catch {
        // Non-fatal — custom exercises unavailable
      } finally {
        setLoadingCustom(false);
      }
    }
    void loadCustom();
  }, [user, isGuest]);

  const handleSelectExercise = (exercise: Exercise): void => {
    // Navigate back with selected exercise as params
    router.back();
    // Use router.setParams to pass data back — parent polls via focus event
    // Pass as query params since Expo Router doesn't have native "result passing"
    router.setParams({
      selectedExerciseId: exercise.id,
      selectedExerciseName: exercise.name,
      selectedMuscleGroup: exercise.muscleGroup,
    });
  };

  const handleCreateExercise = async (
    draft: Omit<Exercise, 'id'>,
  ): Promise<Exercise> => {
    setIsCreating(true);
    try {
      const repo = getExerciseRepo(isGuest);
      const uid = user?.uid ?? '';
      const newExercise: Exercise = {
        ...draft,
        id: `custom-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
      };
      await repo.saveCustomExercise(uid, newExercise);
      setCustomExercises((prev) => [...prev, newExercise]);
      return newExercise;
    } finally {
      setIsCreating(false);
    }
  };

  const handleMuscleGroupSelect = (group: MuscleGroup): void => {
    setSelectedMuscleGroup((prev) => (prev === group ? null : group));
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Add Exercise</Text>
        <TouchableOpacity
          style={styles.closeButton}
          onPress={() => router.back()}
          accessibilityRole="button"
          accessibilityLabel="Close exercise picker"
        >
          <Text style={styles.closeText}>Cancel</Text>
        </TouchableOpacity>
      </View>

      {/* Muscle group filter chips (shown when no muscle group selected) */}
      {selectedMuscleGroup && (
        <View style={styles.filterRow}>
          <TouchableOpacity
            style={styles.activeFilter}
            onPress={() => setSelectedMuscleGroup(null)}
            accessibilityRole="button"
            accessibilityLabel={`Clear ${selectedMuscleGroup} filter`}
          >
            <Text style={styles.activeFilterText}>{selectedMuscleGroup} ✕</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Loading indicator */}
      {loadingCustom && (
        <View style={styles.loadingRow}>
          <ActivityIndicator size="small" color={ORANGE} />
        </View>
      )}

      {/* Search-first layout: ExerciseSearch handles both list and "no query" state */}
      <ExerciseSearch
        exercises={allExercises}
        filterMuscleGroup={selectedMuscleGroup}
        onSelectExercise={handleSelectExercise}
        onCreateExercise={handleCreateExercise}
        isCreating={isCreating}
      />

      {/* Muscle group grid — shown below search when no muscle group filter active */}
      {!selectedMuscleGroup && (
        <View style={styles.muscleGroupSection}>
          <Text style={styles.sectionTitle}>Browse by Muscle Group</Text>
          <MuscleGroupGrid
            selectedGroup={selectedMuscleGroup}
            onSelectMuscleGroup={handleMuscleGroupSelect}
          />
        </View>
      )}
    </SafeAreaView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: CREAM,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: GREY_LIGHT,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: NAVY,
  },
  closeButton: {
    padding: 4,
  },
  closeText: {
    fontSize: 16,
    color: ORANGE,
    fontWeight: '500',
  },
  filterRow: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 8,
    gap: 8,
  },
  activeFilter: {
    backgroundColor: ORANGE,
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  activeFilterText: {
    fontSize: 13,
    fontWeight: '600',
    color: CREAM,
  },
  loadingRow: {
    paddingVertical: 8,
    alignItems: 'center',
  },
  muscleGroupSection: {
    flex: 1,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: NAVY_MEDIUM,
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 4,
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
});
