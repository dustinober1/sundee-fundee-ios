/**
 * app/(app)/benchmarks/create.tsx — Custom Benchmark Creation screen.
 *
 * Form fields: Name, Category (picker), Description (multiline), Scoring Type (radio).
 * Saves via getBenchmarkRepo(isGuest).saveCustomBenchmark(uid, definition).
 * Navigates back to catalog on success.
 *
 * CLAUDE.md convention: Create button disabled when name is empty.
 */

import React, { useState } from 'react';
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getBenchmarkRepo } from '@/src/repositories/BenchmarkRepo';
import type { BenchmarkDefinition } from '@/src/repositories/BenchmarkRepo';
import {
  BENCHMARK_CATEGORY_ORDER,
} from '@/src/domain/benchmarks/benchmark-catalog';
import type { BenchmarkScoringType } from '@/src/domain/types';
import * as colors from '@/src/theme/colors';

const SCORING_OPTIONS: Array<{ type: BenchmarkScoringType; label: string; description: string }> = [
  { type: 'time', label: 'For Time', description: 'Race the clock — lower is better' },
  { type: 'reps', label: 'Max Reps', description: 'Accumulate as many reps as possible' },
  { type: 'roundsAndReps', label: 'AMRAP', description: 'Rounds and partial reps' },
  { type: 'weight', label: 'Max Load', description: 'Heaviest weight lifted' },
  { type: 'distance', label: 'Distance/Time', description: 'Timed fixed-distance event' },
];

const CATEGORY_OPTIONS = [...BENCHMARK_CATEGORY_ORDER];

export default function CreateBenchmarkScreen(): React.JSX.Element {
  const router = useRouter();
  const { user, isGuest } = useSession();

  const [name, setName] = useState('');
  const [category, setCategory] = useState(CATEGORY_OPTIONS[0] ?? 'Classic WODs');
  const [description, setDescription] = useState('');
  const [scoringType, setScoringType] = useState<BenchmarkScoringType>('time');
  const [saving, setSaving] = useState(false);

  const canCreate = name.trim().length > 0;

  async function handleCreate(): Promise<void> {
    if (!canCreate || saving) return;
    setSaving(true);
    try {
      const uid = user?.uid ?? '';
      const customId = `custom-${uid}-${Date.now()}`;

      const definition: BenchmarkDefinition = {
        id: customId,
        userID: uid,
        name: name.trim(),
        category,
        workoutDescription: description.trim(),
        scoringType,
        isPredefined: false,
        sortOrder: Date.now(),
      };

      await getBenchmarkRepo(isGuest).saveCustomBenchmark(uid, definition);
      router.back();
    } catch {
      Alert.alert('Error', 'Failed to create benchmark. Please try again.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        <Text style={styles.screenTitle}>Custom Benchmark</Text>

        {/* Name */}
        <View style={styles.fieldGroup}>
          <Text style={styles.label}>Benchmark Name *</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="e.g. 200m Sprint"
            placeholderTextColor={colors.GREY}
            autoCapitalize="words"
            testID="name-input"
          />
        </View>

        {/* Category */}
        <View style={styles.fieldGroup}>
          <Text style={styles.label}>Category</Text>
          <View style={styles.categoryGrid}>
            {CATEGORY_OPTIONS.map((cat) => (
              <TouchableOpacity
                key={cat}
                style={[
                  styles.categoryOption,
                  category === cat && styles.categoryOptionSelected,
                ]}
                onPress={() => setCategory(cat)}
                activeOpacity={0.75}
                testID={`category-${cat}`}
              >
                <Text
                  style={[
                    styles.categoryOptionText,
                    category === cat && styles.categoryOptionTextSelected,
                  ]}
                  numberOfLines={2}
                >
                  {cat}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Description */}
        <View style={styles.fieldGroup}>
          <Text style={styles.label}>Description</Text>
          <TextInput
            style={[styles.input, styles.descriptionInput]}
            value={description}
            onChangeText={setDescription}
            placeholder="Describe the workout, standards, and scoring..."
            placeholderTextColor={colors.GREY}
            multiline
            numberOfLines={4}
            textAlignVertical="top"
            testID="description-input"
          />
        </View>

        {/* Scoring Type */}
        <View style={styles.fieldGroup}>
          <Text style={styles.label}>Scoring Type</Text>
          <View style={styles.scoringGrid}>
            {SCORING_OPTIONS.map((opt) => (
              <TouchableOpacity
                key={opt.type}
                style={[
                  styles.scoringOption,
                  scoringType === opt.type && styles.scoringOptionSelected,
                ]}
                onPress={() => setScoringType(opt.type)}
                activeOpacity={0.75}
                testID={`scoring-${opt.type}`}
              >
                <Text
                  style={[
                    styles.scoringLabel,
                    scoringType === opt.type && styles.scoringLabelSelected,
                  ]}
                >
                  {opt.label}
                </Text>
                <Text
                  style={[
                    styles.scoringDesc,
                    scoringType === opt.type && styles.scoringDescSelected,
                  ]}
                  numberOfLines={2}
                >
                  {opt.description}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Create Button */}
        <TouchableOpacity
          style={[styles.createButton, !canCreate && styles.createButtonDisabled]}
          onPress={() => void handleCreate()}
          disabled={!canCreate || saving}
          activeOpacity={0.85}
          testID="create-button"
        >
          <Text style={styles.createButtonText}>
            {saving ? 'Creating...' : 'Create Benchmark'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  container: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 48,
    gap: 24,
  },
  screenTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: colors.NAVY,
    letterSpacing: 0.5,
    marginBottom: 8,
  },
  fieldGroup: {
    gap: 8,
  },
  label: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.NAVY_MEDIUM,
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  input: {
    backgroundColor: colors.CREAM_LIGHT,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 14,
    fontSize: 16,
    color: colors.NAVY,
  },
  descriptionInput: {
    minHeight: 88,
    textAlignVertical: 'top',
  },
  categoryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  categoryOption: {
    borderWidth: 1.5,
    borderColor: colors.GREY_LIGHT,
    borderRadius: 8,
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: colors.CREAM_LIGHT,
    maxWidth: '48%',
  },
  categoryOptionSelected: {
    borderColor: colors.NAVY,
    backgroundColor: colors.NAVY,
  },
  categoryOptionText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.NAVY_MEDIUM,
  },
  categoryOptionTextSelected: {
    color: colors.CREAM,
  },
  scoringGrid: {
    gap: 8,
  },
  scoringOption: {
    borderWidth: 1.5,
    borderColor: colors.GREY_LIGHT,
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 14,
    backgroundColor: colors.CREAM_LIGHT,
  },
  scoringOptionSelected: {
    borderColor: colors.ORANGE,
    backgroundColor: colors.ORANGE_LIGHT,
  },
  scoringLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 2,
  },
  scoringLabelSelected: {
    color: colors.ORANGE_DARK,
  },
  scoringDesc: {
    fontSize: 12,
    color: colors.GREY,
  },
  scoringDescSelected: {
    color: colors.NAVY_MEDIUM,
  },
  createButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    shadowColor: colors.ORANGE_DARK,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 5,
  },
  createButtonDisabled: {
    backgroundColor: colors.GREY,
    shadowOpacity: 0,
    elevation: 0,
  },
  createButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
});
