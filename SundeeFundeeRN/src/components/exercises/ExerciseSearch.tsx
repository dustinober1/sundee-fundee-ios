/**
 * ExerciseSearch — search input + filtered exercise list with inline custom creation.
 *
 * - TextInput with search icon, CREAM background, NAVY text
 * - Calls filterExercises on text change, filtered against provided exercises
 * - Renders FlatList of matching exercises
 * - When no matches and query non-empty: shows "Create [query]" button
 * - Create button opens inline form: name (pre-filled) + muscle group picker
 * - On exercise tap: calls onSelectExercise callback
 */

import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { filterExercises } from '../../domain/exercises/exercise-filter';
import { MUSCLE_GROUPS } from '../../domain/exercises/exercise-types';
import type { Exercise, MuscleGroup } from '../../domain/exercises/exercise-types';
import {
  CREAM,
  CREAM_LIGHT,
  NAVY,
  NAVY_MEDIUM,
  ORANGE,
  GREY_LIGHT,
  GREY,
} from '../../theme/colors';

// ─── Props ────────────────────────────────────────────────────────────────────

interface ExerciseSearchProps {
  exercises: Exercise[];
  filterMuscleGroup?: MuscleGroup | null;
  onSelectExercise: (exercise: Exercise) => void;
  onCreateExercise?: (exercise: Omit<Exercise, 'id'>) => Promise<Exercise>;
  isCreating?: boolean;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function ExerciseSearch({
  exercises,
  filterMuscleGroup,
  onSelectExercise,
  onCreateExercise,
  isCreating = false,
}: ExerciseSearchProps): React.JSX.Element {
  const [query, setQuery] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newExerciseName, setNewExerciseName] = useState('');
  const [newMuscleGroup, setNewMuscleGroup] = useState<MuscleGroup>('Chest');

  const filteredExercises = useMemo(
    () => filterExercises(exercises, query, filterMuscleGroup ?? undefined),
    [exercises, query, filterMuscleGroup],
  );

  const showCreateButton =
    query.trim().length > 0 && filteredExercises.length === 0 && onCreateExercise !== undefined;

  const handleCreatePress = (): void => {
    setNewExerciseName(query.trim());
    setShowCreateForm(true);
  };

  const handleCreateSubmit = async (): Promise<void> => {
    if (!onCreateExercise || !newExerciseName.trim()) return;
    const created = await onCreateExercise({
      name: newExerciseName.trim(),
      muscleGroup: newMuscleGroup,
      isCustom: true,
    });
    onSelectExercise(created);
    setShowCreateForm(false);
    setQuery('');
  };

  const handleCancelCreate = (): void => {
    setShowCreateForm(false);
    setNewExerciseName('');
  };

  return (
    <View style={styles.container}>
      {/* Search input */}
      <View style={styles.searchRow}>
        <Text style={styles.searchIcon}>🔍</Text>
        <TextInput
          style={styles.searchInput}
          placeholder="Search exercises..."
          placeholderTextColor={GREY}
          value={query}
          onChangeText={setQuery}
          autoCapitalize="none"
          autoCorrect={false}
          clearButtonMode="while-editing"
          accessibilityLabel="Search exercises"
        />
      </View>

      {/* Inline create form */}
      {showCreateForm && (
        <View style={styles.createForm}>
          <Text style={styles.createFormTitle}>New Exercise</Text>
          <TextInput
            style={styles.createInput}
            value={newExerciseName}
            onChangeText={setNewExerciseName}
            placeholder="Exercise name"
            placeholderTextColor={GREY}
            autoCapitalize="words"
            accessibilityLabel="New exercise name"
          />
          <Text style={styles.createFormLabel}>Muscle Group</Text>
          <View style={styles.muscleGroupPicker}>
            {MUSCLE_GROUPS.map((group) => (
              <TouchableOpacity
                key={group}
                style={[
                  styles.muscleGroupChip,
                  newMuscleGroup === group && styles.muscleGroupChipSelected,
                ]}
                onPress={() => setNewMuscleGroup(group)}
                accessibilityRole="button"
                accessibilityLabel={group}
                accessibilityState={{ selected: newMuscleGroup === group }}
              >
                <Text
                  style={[
                    styles.muscleGroupChipText,
                    newMuscleGroup === group && styles.muscleGroupChipTextSelected,
                  ]}
                >
                  {group}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <View style={styles.createFormActions}>
            <TouchableOpacity style={styles.cancelButton} onPress={handleCancelCreate}>
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.createButton,
                (!newExerciseName.trim() || isCreating) && styles.createButtonDisabled,
              ]}
              onPress={() => void handleCreateSubmit()}
              disabled={!newExerciseName.trim() || isCreating}
            >
              {isCreating ? (
                <ActivityIndicator size="small" color={CREAM} />
              ) : (
                <Text style={styles.createButtonText}>Create</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      )}

      {/* Exercise list */}
      {!showCreateForm && (
        <FlatList
          data={filteredExercises}
          keyExtractor={(item) => item.id}
          style={styles.list}
          keyboardShouldPersistTaps="handled"
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.exerciseRow}
              onPress={() => onSelectExercise(item)}
              accessibilityRole="button"
              accessibilityLabel={`${item.name}, ${item.muscleGroup}`}
            >
              <View style={styles.exerciseInfo}>
                <Text style={styles.exerciseName}>{item.name}</Text>
                <Text style={styles.muscleGroupText}>{item.muscleGroup}</Text>
              </View>
              {item.isCustom && (
                <View style={styles.customBadge}>
                  <Text style={styles.customBadgeText}>Custom</Text>
                </View>
              )}
            </TouchableOpacity>
          )}
          ListEmptyComponent={
            !showCreateButton ? (
              <View style={styles.emptyState}>
                <Text style={styles.emptyText}>
                  {query.trim() ? 'No exercises found.' : 'Start typing to search...'}
                </Text>
              </View>
            ) : null
          }
          ListFooterComponent={
            showCreateButton ? (
              <TouchableOpacity style={styles.createRowButton} onPress={handleCreatePress}>
                <Text style={styles.createRowButtonText}>
                  + Create &quot;{query.trim()}&quot;
                </Text>
              </TouchableOpacity>
            ) : null
          }
        />
      )}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  searchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: CREAM,
    borderWidth: 1,
    borderColor: GREY_LIGHT,
    borderRadius: 8,
    paddingHorizontal: 12,
    marginHorizontal: 16,
    marginVertical: 8,
  },
  searchIcon: {
    fontSize: 16,
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    height: 44,
    fontSize: 16,
    color: NAVY,
  },
  list: {
    flex: 1,
  },
  exerciseRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: GREY_LIGHT,
    backgroundColor: CREAM,
  },
  exerciseInfo: {
    flex: 1,
  },
  exerciseName: {
    fontSize: 16,
    fontWeight: '500',
    color: NAVY,
    marginBottom: 2,
  },
  muscleGroupText: {
    fontSize: 13,
    color: NAVY_MEDIUM,
  },
  customBadge: {
    backgroundColor: ORANGE,
    borderRadius: 4,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  customBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: CREAM,
  },
  emptyState: {
    padding: 24,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 14,
    color: GREY,
  },
  createRowButton: {
    padding: 16,
    alignItems: 'center',
    backgroundColor: CREAM_LIGHT,
    borderTopWidth: 1,
    borderTopColor: GREY_LIGHT,
  },
  createRowButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: ORANGE,
  },
  // Inline create form
  createForm: {
    margin: 16,
    padding: 16,
    backgroundColor: CREAM_LIGHT,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: GREY_LIGHT,
    gap: 12,
  },
  createFormTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: NAVY,
  },
  createInput: {
    borderWidth: 1,
    borderColor: GREY_LIGHT,
    borderRadius: 6,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
    color: NAVY,
    backgroundColor: CREAM,
  },
  createFormLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: NAVY_MEDIUM,
  },
  muscleGroupPicker: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  muscleGroupChip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: GREY_LIGHT,
    backgroundColor: CREAM,
  },
  muscleGroupChipSelected: {
    borderColor: ORANGE,
    backgroundColor: ORANGE,
  },
  muscleGroupChipText: {
    fontSize: 13,
    color: NAVY,
  },
  muscleGroupChipTextSelected: {
    color: CREAM,
    fontWeight: '600',
  },
  createFormActions: {
    flexDirection: 'row',
    gap: 12,
    justifyContent: 'flex-end',
  },
  cancelButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: GREY_LIGHT,
  },
  cancelButtonText: {
    fontSize: 14,
    color: NAVY_MEDIUM,
  },
  createButton: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: ORANGE,
  },
  createButtonDisabled: {
    opacity: 0.5,
  },
  createButtonText: {
    fontSize: 14,
    fontWeight: '700',
    color: CREAM,
  },
});
