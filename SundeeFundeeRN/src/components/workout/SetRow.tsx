/**
 * SetRow — a single row for logging weight and reps for one set.
 *
 * Features:
 * - Set number label, weight input (numeric), reps input (numeric), checkmark button
 * - Ghost text from previous workout values for this exercise
 * - Checkmark tap calls onCompleteSet with entered weight and reps
 * - PR badge: small orange "PR" badge if set.isPersonalRecord
 * - Disabled state for already-completed sets (grayed, values locked)
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import type { LoggedSet } from '../../domain/workout-session/session-types';
import type { WeightUnit } from '../../domain/types';
import { formatWeightNumeric, parseWeightInput } from '../../utils/formatWeight';
import {
  CREAM,
  CREAM_LIGHT,
  NAVY,
  NAVY_MEDIUM,
  ORANGE,
  ORANGE_LIGHT,
  GREY,
  GREY_LIGHT,
} from '../../theme/colors';

// ─── Props ────────────────────────────────────────────────────────────────────

interface SetRowProps {
  set: LoggedSet;
  setNumber: number;
  previousWeight?: number;
  previousReps?: number;
  onCompleteSet: (setId: string, weight: number, reps: number) => void;
  /** User's preferred weight unit — determines input suffix and parsing. Defaults to 'lb'. */
  weightUnit?: WeightUnit;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function SetRow({
  set,
  setNumber,
  previousWeight,
  previousReps,
  onCompleteSet,
  weightUnit = 'lb',
}: SetRowProps): React.JSX.Element {
  // Display stored lbs in user's preferred unit when set is completed
  const displayCompletedWeight = set.completed
    ? String(formatWeightNumeric(set.weight, weightUnit))
    : '';
  const [weight, setWeight] = useState(displayCompletedWeight);
  const [reps, setReps] = useState(set.completed ? String(set.reps) : '');

  const isDisabled = set.completed;

  const handleComplete = (): void => {
    // parseWeightInput converts user's unit input back to stored lbs
    const w = parseWeightInput(weight, weightUnit) || 0;
    const r = parseInt(reps, 10) || 0;
    onCompleteSet(set.id, w, r);
  };

  const canComplete = weight.trim().length > 0 && reps.trim().length > 0 && !isDisabled;

  return (
    <View style={[styles.row, isDisabled && styles.rowCompleted]}>
      {/* Set number */}
      <View style={styles.setNumberContainer}>
        <Text style={styles.setNumber}>{setNumber}</Text>
      </View>

      {/* Weight input */}
      <View style={styles.inputContainer}>
        <TextInput
          style={[styles.input, isDisabled && styles.inputDisabled]}
          value={weight}
          onChangeText={setWeight}
          placeholder={
            previousWeight !== undefined
              ? String(formatWeightNumeric(previousWeight, weightUnit))
              : '-'
          }
          placeholderTextColor={GREY}
          keyboardType="decimal-pad"
          editable={!isDisabled}
          accessibilityLabel={`Set ${setNumber} weight`}
          returnKeyType="next"
        />
        <Text style={styles.inputUnit}>{weightUnit === 'kg' ? 'kg' : 'lbs'}</Text>
      </View>

      {/* Reps input */}
      <View style={styles.inputContainer}>
        <TextInput
          style={[styles.input, isDisabled && styles.inputDisabled]}
          value={reps}
          onChangeText={setReps}
          placeholder={previousReps !== undefined ? String(previousReps) : '-'}
          placeholderTextColor={GREY}
          keyboardType="number-pad"
          editable={!isDisabled}
          accessibilityLabel={`Set ${setNumber} reps`}
          returnKeyType="done"
        />
        <Text style={styles.inputUnit}>reps</Text>
      </View>

      {/* PR badge */}
      {set.isPersonalRecord && (
        <View style={styles.prBadge} accessibilityLabel="Personal Record">
          <Text style={styles.prBadgeText}>PR</Text>
        </View>
      )}

      {/* Checkmark button */}
      <TouchableOpacity
        style={[
          styles.checkButton,
          isDisabled && styles.checkButtonCompleted,
          !canComplete && !isDisabled && styles.checkButtonDisabled,
        ]}
        onPress={handleComplete}
        disabled={!canComplete}
        accessibilityRole="button"
        accessibilityLabel={`Complete set ${setNumber}`}
        accessibilityState={{ disabled: !canComplete }}
      >
        <Text style={[styles.checkIcon, isDisabled && styles.checkIconCompleted]}>
          {isDisabled ? '✓' : '○'}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    gap: 8,
    backgroundColor: CREAM,
    borderBottomWidth: 1,
    borderBottomColor: GREY_LIGHT,
  },
  rowCompleted: {
    backgroundColor: CREAM_LIGHT,
    opacity: 0.85,
  },
  setNumberContainer: {
    width: 28,
    alignItems: 'center',
  },
  setNumber: {
    fontSize: 14,
    fontWeight: '700',
    color: NAVY_MEDIUM,
  },
  inputContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: CREAM_LIGHT,
    borderWidth: 1,
    borderColor: GREY_LIGHT,
    borderRadius: 6,
    paddingHorizontal: 8,
    height: 40,
  },
  input: {
    flex: 1,
    fontSize: 16,
    color: NAVY,
    textAlign: 'center',
  },
  inputDisabled: {
    color: NAVY_MEDIUM,
  },
  inputUnit: {
    fontSize: 11,
    color: GREY,
    marginLeft: 2,
  },
  prBadge: {
    backgroundColor: ORANGE,
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  prBadgeText: {
    fontSize: 10,
    fontWeight: '800',
    color: CREAM,
    letterSpacing: 0.5,
  },
  checkButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: ORANGE_LIGHT,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    borderColor: ORANGE,
  },
  checkButtonCompleted: {
    backgroundColor: ORANGE,
  },
  checkButtonDisabled: {
    opacity: 0.4,
  },
  checkIcon: {
    fontSize: 18,
    color: ORANGE,
    fontWeight: '700',
  },
  checkIconCompleted: {
    color: CREAM,
  },
});
