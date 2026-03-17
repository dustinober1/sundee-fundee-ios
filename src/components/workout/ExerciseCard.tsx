/**
 * ExerciseCard — displays an active exercise with its set rows.
 *
 * Features:
 * - Exercise name header with muscle group badge
 * - List of SetRow components
 * - "+Set" button at bottom
 * - Swipe-left gesture hint (parent handles delete via drag item)
 * - Long-press drag handle for DraggableFlatList reordering
 */

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { SetRow } from './SetRow';
import type { ActiveExercise } from '../../domain/workout-session/session-types';
import type { WeightUnit } from '../../domain/types';
import {
  CREAM,
  CREAM_LIGHT,
  NAVY,
  NAVY_MEDIUM,
  ORANGE,
  ORANGE_LIGHT,
  GREY_LIGHT,
  GREY,
} from '../../theme/colors';

// ─── Props ────────────────────────────────────────────────────────────────────

interface ExerciseCardProps {
  exercise: ActiveExercise;
  previousValues?: { weight: number; reps: number }[];
  onCompleteSet: (activeExerciseId: string, setId: string, weight: number, reps: number) => void;
  onAddSet: (activeExerciseId: string) => void;
  onRemoveExercise: (activeExerciseId: string) => void;
  /** Drag handle activation function from DraggableFlatList */
  drag?: () => void;
  isActive?: boolean;
  /** User's preferred weight unit — passed down to SetRow for display and parsing. */
  weightUnit?: WeightUnit;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function ExerciseCard({
  exercise,
  previousValues = [],
  onCompleteSet,
  onAddSet,
  onRemoveExercise,
  drag,
  isActive = false,
  weightUnit = 'lb',
}: ExerciseCardProps): React.JSX.Element {
  const completedCount = exercise.sets.filter((s) => s.completed).length;

  return (
    <View style={[styles.card, isActive && styles.cardDragging]}>
      {/* Header */}
      <View style={styles.header}>
        {/* Long-press drag handle */}
        <TouchableOpacity
          onLongPress={drag}
          delayLongPress={200}
          style={styles.dragHandle}
          accessibilityLabel={`Drag to reorder ${exercise.exerciseName}`}
          accessibilityRole="button"
        >
          <Text style={styles.dragIcon}>⠿</Text>
        </TouchableOpacity>

        {/* Exercise info */}
        <View style={styles.exerciseInfo}>
          <Text style={styles.exerciseName}>{exercise.exerciseName}</Text>
          <View style={styles.muscleBadge}>
            <Text style={styles.muscleBadgeText}>{exercise.muscleGroup}</Text>
          </View>
        </View>

        {/* Progress indicator */}
        <Text style={styles.setProgress}>
          {completedCount}/{exercise.sets.length}
        </Text>

        {/* Remove button */}
        <TouchableOpacity
          style={styles.removeButton}
          onPress={() => onRemoveExercise(exercise.id)}
          accessibilityRole="button"
          accessibilityLabel={`Remove ${exercise.exerciseName}`}
        >
          <Text style={styles.removeIcon}>✕</Text>
        </TouchableOpacity>
      </View>

      {/* Set headers */}
      <View style={styles.setHeader}>
        <Text style={[styles.setHeaderText, { width: 28 }]}>Set</Text>
        <Text style={[styles.setHeaderText, { flex: 1 }]}>Weight</Text>
        <Text style={[styles.setHeaderText, { flex: 1 }]}>Reps</Text>
        <View style={{ width: 48 }} />
      </View>

      {/* Set rows */}
      {exercise.sets.map((set, index) => (
        <SetRow
          key={set.id}
          set={set}
          setNumber={index + 1}
          previousWeight={previousValues[index]?.weight}
          previousReps={previousValues[index]?.reps}
          onCompleteSet={(setId, weight, reps) =>
            onCompleteSet(exercise.id, setId, weight, reps)
          }
          weightUnit={weightUnit}
        />
      ))}

      {/* Add set button */}
      <TouchableOpacity
        style={styles.addSetButton}
        onPress={() => onAddSet(exercise.id)}
        accessibilityRole="button"
        accessibilityLabel={`Add set to ${exercise.exerciseName}`}
      >
        <Text style={styles.addSetText}>+ Add Set</Text>
      </TouchableOpacity>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  card: {
    backgroundColor: CREAM,
    marginHorizontal: 16,
    marginVertical: 8,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: GREY_LIGHT,
    overflow: 'hidden',
  },
  cardDragging: {
    shadowColor: NAVY,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 8,
    opacity: 0.95,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: CREAM_LIGHT,
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 8,
    borderBottomWidth: 1,
    borderBottomColor: GREY_LIGHT,
  },
  dragHandle: {
    padding: 4,
  },
  dragIcon: {
    fontSize: 18,
    color: GREY,
  },
  exerciseInfo: {
    flex: 1,
    gap: 4,
  },
  exerciseName: {
    fontSize: 15,
    fontWeight: '700',
    color: NAVY,
  },
  muscleBadge: {
    alignSelf: 'flex-start',
    backgroundColor: ORANGE_LIGHT,
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  muscleBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: NAVY_MEDIUM,
  },
  setProgress: {
    fontSize: 13,
    fontWeight: '600',
    color: NAVY_MEDIUM,
    minWidth: 30,
    textAlign: 'right',
  },
  removeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  removeIcon: {
    fontSize: 16,
    color: GREY,
  },
  setHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: CREAM_LIGHT,
    borderBottomWidth: 1,
    borderBottomColor: GREY_LIGHT,
    gap: 8,
  },
  setHeaderText: {
    fontSize: 11,
    fontWeight: '600',
    color: GREY,
    textAlign: 'center',
  },
  addSetButton: {
    paddingVertical: 12,
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: GREY_LIGHT,
  },
  addSetText: {
    fontSize: 14,
    fontWeight: '600',
    color: ORANGE,
  },
});
