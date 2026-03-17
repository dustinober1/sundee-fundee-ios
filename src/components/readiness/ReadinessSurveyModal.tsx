/**
 * ReadinessSurveyModal — 4-slider daily readiness survey.
 *
 * Sliders (per locked decision, READ-01):
 *   1. Sleep Quality (1–10)
 *   2. Energy Level  (1–10)
 *   3. Stress Level  (1–10, higher = more stressed)
 *   4. Body Soreness / Motivation (1–10, higher = more soreness)
 *
 * On submit: calls calculateReadinessScore, saves via getReadinessRepo,
 * shows result for 2 seconds, then auto-dismisses.
 *
 * Threads uid from useSession(). Uses date-fns format() for the date key
 * (local time, per pitfall 4 — avoids UTC date boundary issues).
 */

import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { format } from 'date-fns';
import { useSession } from '@/src/auth/AuthContext';
import { getReadinessRepo } from '@/src/repositories/ReadinessRepo';
import {
  calculateReadinessScore,
  tierDisplayName,
  type ReadinessResult,
} from '@/src/domain/readiness/readiness-survey';
import * as colors from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface ReadinessSurveyModalProps {
  visible: boolean;
  /** Called after survey is saved and result screen dismissed. */
  onComplete: (result: ReadinessResult) => void;
  /** Called when user closes without submitting. */
  onDismiss: () => void;
}

// ─── Static helpers (testable without mounting) ───────────────────────────────

/** Formats a ReadinessResult into a display string. e.g. "7/10 (Prime)" */
export function formatReadinessResult(result: ReadinessResult): string {
  const rounded = Math.round(result.score * 10) / 10;
  return `${rounded}/10 (${tierDisplayName(result.tier)})`;
}

/** Returns the tier color for a result badge. */
export function tierColor(tier: ReadinessResult['tier']): string {
  switch (tier) {
    case 'high': return colors.ORANGE;
    case 'low': return colors.NAVY_MEDIUM;
    case 'neutral': return colors.NAVY;
  }
}

// ─── SliderRow sub-component ──────────────────────────────────────────────────

interface SliderRowProps {
  label: string;
  value: number;
  onDecrement: () => void;
  onIncrement: () => void;
  testIDPrefix: string;
}

function SliderRow({
  label,
  value,
  onDecrement,
  onIncrement,
  testIDPrefix,
}: SliderRowProps): React.JSX.Element {
  return (
    <View style={sliderStyles.row}>
      <Text style={sliderStyles.label}>{label}</Text>
      <View style={sliderStyles.controls}>
        <TouchableOpacity
          style={[sliderStyles.stepButton, value <= 1 && sliderStyles.stepButtonDisabled]}
          onPress={onDecrement}
          disabled={value <= 1}
          testID={`${testIDPrefix}-decrement`}
          activeOpacity={0.7}
        >
          <Text style={sliderStyles.stepButtonText}>−</Text>
        </TouchableOpacity>

        <View style={sliderStyles.valueContainer}>
          <Text style={sliderStyles.valueText} testID={`${testIDPrefix}-value`}>
            {value}
          </Text>
          <Text style={sliderStyles.maxText}>/10</Text>
        </View>

        <TouchableOpacity
          style={[sliderStyles.stepButton, value >= 10 && sliderStyles.stepButtonDisabled]}
          onPress={onIncrement}
          disabled={value >= 10}
          testID={`${testIDPrefix}-increment`}
          activeOpacity={0.7}
        >
          <Text style={sliderStyles.stepButtonText}>+</Text>
        </TouchableOpacity>
      </View>

      {/* Visual track */}
      <View style={sliderStyles.track}>
        <View style={[sliderStyles.fill, { flex: value }]} />
        <View style={{ flex: 10 - value }} />
      </View>
    </View>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function ReadinessSurveyModal({
  visible,
  onComplete,
  onDismiss,
}: ReadinessSurveyModalProps): React.JSX.Element {
  const { user, isGuest } = useSession();

  const [sleepQuality, setSleepQuality] = useState(7);
  const [energyLevel, setEnergyLevel] = useState(7);
  const [stressLevel, setStressLevel] = useState(3);
  const [sorenessLevel, setSorenessLevel] = useState(3);

  const [isSaving, setIsSaving] = useState(false);
  const [savedResult, setSavedResult] = useState<ReadinessResult | null>(null);

  const handleSubmit = useCallback(async (): Promise<void> => {
    if (!user) return;
    setIsSaving(true);

    try {
      const result = calculateReadinessScore(
        sleepQuality,
        stressLevel,
        sorenessLevel,
        energyLevel,
      );

      const date = format(new Date(), 'yyyy-MM-dd');
      const record = {
        id: date,
        uid: user.uid,
        date,
        sleepQuality,
        energyLevel,
        stressLevel,
        sorenessLevel,
        result,
      };

      await getReadinessRepo(isGuest).saveSurvey(user.uid, record);
      setSavedResult(result);

      // Auto-dismiss after showing result for 2 seconds
      setTimeout(() => {
        setSavedResult(null);
        resetSliders();
        onComplete(result);
      }, 2000);
    } catch {
      // Graceful degradation — dismiss without blocking the user
      setSavedResult(null);
      onDismiss();
    } finally {
      setIsSaving(false);
    }
  }, [user, isGuest, sleepQuality, energyLevel, stressLevel, sorenessLevel, onComplete, onDismiss]);

  function resetSliders(): void {
    setSleepQuality(7);
    setEnergyLevel(7);
    setStressLevel(3);
    setSorenessLevel(3);
  }

  function handleDismiss(): void {
    resetSliders();
    setSavedResult(null);
    onDismiss();
  }

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleDismiss}
      testID="readiness-survey-modal"
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerLeft}>
            <View style={styles.accentBar} />
            <Text style={styles.headerLabel}>DAILY CHECK-IN</Text>
          </View>
          <TouchableOpacity
            onPress={handleDismiss}
            hitSlop={{ top: 8, right: 8, bottom: 8, left: 8 }}
            testID="survey-modal-close"
          >
            <Text style={styles.closeText}>✕</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.title}>How are you feeling today?</Text>
        <Text style={styles.subtitle}>
          Rate each on a scale of 1–10. This takes about 15 seconds.
        </Text>

        {/* Result view (shown after save) */}
        {savedResult != null ? (
          <View style={styles.resultContainer} testID="readiness-result-view">
            <Text style={styles.resultLabel}>Your readiness</Text>
            <Text
              style={[styles.resultValue, { color: tierColor(savedResult.tier) }]}
              testID="readiness-result-text"
            >
              {formatReadinessResult(savedResult)}
            </Text>
            <Text style={styles.resultNote}>Saved. Adjusting your workout...</Text>
          </View>
        ) : (
          <>
            {/* Sliders */}
            <View style={styles.slidersContainer}>
              <SliderRow
                label="Sleep Quality"
                value={sleepQuality}
                onDecrement={() => setSleepQuality((v) => Math.max(1, v - 1))}
                onIncrement={() => setSleepQuality((v) => Math.min(10, v + 1))}
                testIDPrefix="slider-sleep"
              />
              <SliderRow
                label="Energy Level"
                value={energyLevel}
                onDecrement={() => setEnergyLevel((v) => Math.max(1, v - 1))}
                onIncrement={() => setEnergyLevel((v) => Math.min(10, v + 1))}
                testIDPrefix="slider-energy"
              />
              <SliderRow
                label="Stress Level"
                value={stressLevel}
                onDecrement={() => setStressLevel((v) => Math.max(1, v - 1))}
                onIncrement={() => setStressLevel((v) => Math.min(10, v + 1))}
                testIDPrefix="slider-stress"
              />
              <SliderRow
                label="Body Soreness / Motivation"
                value={sorenessLevel}
                onDecrement={() => setSorenessLevel((v) => Math.max(1, v - 1))}
                onIncrement={() => setSorenessLevel((v) => Math.min(10, v + 1))}
                testIDPrefix="slider-soreness"
              />
            </View>

            {/* Submit button */}
            <TouchableOpacity
              style={[styles.submitButton, isSaving && styles.submitButtonDisabled]}
              onPress={() => { void handleSubmit(); }}
              disabled={isSaving}
              activeOpacity={0.85}
              testID="readiness-submit-button"
            >
              {isSaving ? (
                <ActivityIndicator color={colors.CREAM} size="small" />
              ) : (
                <Text style={styles.submitText}>Submit</Text>
              )}
            </TouchableOpacity>
          </>
        )}
      </ScrollView>
    </Modal>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  container: {
    paddingHorizontal: 24,
    paddingTop: 32,
    paddingBottom: 48,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  accentBar: {
    width: 3,
    height: 14,
    backgroundColor: colors.ORANGE,
    borderRadius: 2,
  },
  headerLabel: {
    fontSize: 10,
    fontWeight: '700',
    color: colors.ORANGE,
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
  closeText: {
    fontSize: 16,
    color: colors.GREY,
    fontWeight: '600',
    padding: 4,
  },
  title: {
    fontSize: 24,
    fontWeight: '800',
    color: colors.NAVY,
    letterSpacing: 0.3,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    lineHeight: 20,
    marginBottom: 28,
  },
  slidersContainer: {
    gap: 24,
    marginBottom: 36,
  },
  submitButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 14,
    paddingVertical: 18,
    alignItems: 'center',
    shadowColor: colors.ORANGE_DARK,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  submitButtonDisabled: {
    opacity: 0.7,
  },
  submitText: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
  resultContainer: {
    alignItems: 'center',
    paddingVertical: 40,
    gap: 12,
  },
  resultLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.GREY,
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  resultValue: {
    fontSize: 32,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  resultNote: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
  },
});

const sliderStyles = StyleSheet.create({
  row: {
    gap: 10,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.NAVY,
    marginBottom: 2,
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  stepButton: {
    width: 42,
    height: 42,
    borderRadius: 10,
    backgroundColor: colors.CREAM_LIGHT,
    borderWidth: 1.5,
    borderColor: colors.NAVY,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepButtonDisabled: {
    borderColor: colors.GREY_LIGHT,
    backgroundColor: colors.CREAM,
  },
  stepButtonText: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.NAVY,
    lineHeight: 24,
  },
  valueContainer: {
    flexDirection: 'row',
    alignItems: 'baseline',
    gap: 2,
  },
  valueText: {
    fontSize: 28,
    fontWeight: '800',
    color: colors.NAVY,
    minWidth: 32,
    textAlign: 'center',
  },
  maxText: {
    fontSize: 14,
    color: colors.GREY,
    fontWeight: '500',
  },
  track: {
    flexDirection: 'row',
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.GREY_LIGHT,
    overflow: 'hidden',
  },
  fill: {
    backgroundColor: colors.ORANGE,
    borderRadius: 3,
  },
});
