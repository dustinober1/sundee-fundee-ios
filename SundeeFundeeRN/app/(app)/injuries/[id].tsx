/**
 * injuries/[id].tsx — Injury profile screen.
 *
 * Shows full injury detail with pain logging, pain trend chart, phase
 * transition advice banner, rehab session generation, and exercise substitutions.
 *
 * Sections (ScrollView):
 *   1. Header: location, phase badge, date, notes
 *   2. Pain Logging: 1-10 slider + "Log Pain" button
 *   3. Pain Trend Chart: PainTrendChart with trend result from analyzeTrend()
 *   4. Phase Transition Advice: banner with "Update Phase" button if suggested
 *   5. Rehab Session: "Generate Rehab Session" button -> exercise list
 *   6. Exercise Substitutions: InjurySubstitutionCard
 *
 * UID threaded from useSession() — never hardcoded.
 */

import React, { useCallback, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Slider,
} from 'react-native';
import { useFocusEffect, useRouter, useLocalSearchParams } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { useEntitlementContext } from '@/src/entitlements/EntitlementContext';
import {
  getInjuryRepo,
  recordToInjuryProfile,
  injuryProfileToRecord,
  recordToPainLog,
  type InjuryProfileRecord,
  type PainLogRecord,
} from '@/src/repositories/InjuryRepo';
import { PainTrendChart } from '@/src/components/injury/PainTrendChart';
import {
  InjurySubstitutionCard,
  type SubstitutionPair,
} from '@/src/components/injury/InjurySubstitutionCard';
import { BodyMap } from '@/src/components/injury/BodyMap';
import { PaywallModal } from '@/src/components/paywall/PaywallModal';
import { PremiumBadge } from '@/src/components/paywall/PremiumBadge';
import {
  analyzeTrend,
  evaluateTransition,
  generateSession,
  adaptProgramWithMetadata,
} from '@/src/domain/injury/index';
import type { InjuryProfile, ProgramSession, RecoveryPhase } from '@/src/domain/types/index';
import {
  recoveryPhaseLabel,
  recoveryPhaseColor,
} from './index';
import * as colors from '@/src/theme/colors';

// ─── Utility: generate a UUID-like string ────────────────────────────────────

function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// ─── Sample exercises for substitution card ───────────────────────────────────

const SAMPLE_EXERCISES = [
  { id: 'back-squat',     name: 'Back Squat' },
  { id: 'deadlift',       name: 'Conventional Deadlift (No Straps)' },
  { id: 'bench-press',    name: 'Flat Barbell Bench Press' },
  { id: 'strict-press',   name: 'Strict Press / Military Press' },
  { id: 'romanian-dl',    name: 'Romanian Deadlift (No Straps)' },
  { id: 'walking-lunges', name: 'Walking Lunges' },
  { id: 'pull-up',        name: 'Pull-Up' },
  { id: 'barbell-row',    name: 'Barbell Row' },
];

// ─── PHASE_ORDER label helpers (re-use from index, expose locally) ─────────────

const PHASE_DISPLAY_LABELS: Record<RecoveryPhase, string> = {
  acute: 'Acute',
  rehab: 'Rehab',
  lightLoad: 'Light Load',
  returnToPlay: 'Return to Play',
  resolved: 'Resolved',
};

// ─── InjuryProfileScreen ─────────────────────────────────────────────────────

export default function InjuryProfileScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const { isPremium } = useEntitlementContext();
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();

  const [injuryRecord, setInjuryRecord] = useState<InjuryProfileRecord | null>(null);
  const [painLogs, setPainLogs] = useState<PainLogRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [painSliderValue, setPainSliderValue] = useState(5);
  const [isLoggingPain, setIsLoggingPain] = useState(false);
  const [isUpdatingPhase, setIsUpdatingPhase] = useState(false);
  const [rehabSession, setRehabSession] = useState<ProgramSession | null>(null);
  const [showRehabSession, setShowRehabSession] = useState(false);
  const [substitutions, setSubstitutions] = useState<SubstitutionPair[]>([]);
  const [showPaywall, setShowPaywall] = useState(false);

  const loadData = useCallback(async (): Promise<void> => {
    if (!user || !id) return;
    setIsLoading(true);
    try {
      const repo = getInjuryRepo(isGuest);
      const [allInjuries, logs] = await Promise.all([
        repo.getInjuries(user.uid),
        repo.getPainLogs(user.uid, id),
      ]);
      const record = allInjuries.find((r) => r.id === id) ?? null;
      setInjuryRecord(record);
      setPainLogs(logs);

      if (record) {
        // Build substitution pairs
        const injury = recordToInjuryProfile(record);
        const sampleProgram = {
          id: 'sample',
          name: 'Sample',
          sessions: [{
            id: 'session-1',
            name: 'Sample Session',
            exercises: SAMPLE_EXERCISES.map((ex) => ({
              id: ex.id,
              name: ex.name,
              sets: 3,
              reps: { kind: 'fixed' as const, value: 8 },
            })),
          }],
        };
        const result = adaptProgramWithMetadata(sampleProgram, [injury]);
        const pairs: SubstitutionPair[] = Object.entries(result.adaptedExercises).map(
          ([replacement, original]) => ({ original, replacement }),
        );
        setSubstitutions(pairs);
      }
    } catch (err) {
      console.error('[InjuryProfileScreen] Failed to load data:', err);
    } finally {
      setIsLoading(false);
    }
  }, [user, isGuest, id]);

  useFocusEffect(
    useCallback(() => {
      void loadData();
    }, [loadData]),
  );

  async function handleLogPain(): Promise<void> {
    if (!user || !injuryRecord) return;
    setIsLoggingPain(true);
    try {
      const repo = getInjuryRepo(isGuest);
      const logId = generateUUID();
      await repo.savePainLog(user.uid, {
        id: logId,
        uid: user.uid,
        injuryId: id,
        date: new Date().toISOString(),
        painLevel: Math.round(painSliderValue),
      });
      // Reload pain logs
      const updated = await repo.getPainLogs(user.uid, id);
      setPainLogs(updated);
    } catch (err) {
      console.error('[InjuryProfileScreen] Failed to log pain:', err);
    } finally {
      setIsLoggingPain(false);
    }
  }

  async function handleUpdatePhase(newPhase: RecoveryPhase): Promise<void> {
    if (!user || !injuryRecord) return;
    setIsUpdatingPhase(true);
    try {
      const repo = getInjuryRepo(isGuest);
      const updated: InjuryProfileRecord = {
        ...injuryRecord,
        recoveryPhase: newPhase,
      };
      await repo.saveInjury(user.uid, updated);
      setInjuryRecord(updated);
    } catch (err) {
      console.error('[InjuryProfileScreen] Failed to update phase:', err);
    } finally {
      setIsUpdatingPhase(false);
    }
  }

  function handleGenerateRehab(): void {
    if (!injuryRecord) return;
    const injury = recordToInjuryProfile(injuryRecord);
    const session = generateSession([injury]);
    setRehabSession(session);
    setShowRehabSession(true);
  }

  function handleStartRehabSession(): void {
    if (!rehabSession) return;
    router.push({
      pathname: '/(app)/workout-session',
      params: {
        sessionId: rehabSession.id,
        sessionName: rehabSession.name,
        exercisesJson: JSON.stringify(rehabSession.exercises),
      },
    });
  }

  if (isLoading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  if (!injuryRecord) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>Injury not found</Text>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.backLink}>Go back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const injury = recordToInjuryProfile(injuryRecord);
  const domainLogs = painLogs.map(recordToPainLog);
  const trendResult = analyzeTrend(domainLogs);
  const transition = evaluateTransition(injuryRecord.id, injuryRecord.recoveryPhase, domainLogs);

  const locationLabel = BodyMap.locationLabel(injuryRecord.bodyLocation);
  const phaseLabel = PHASE_DISPLAY_LABELS[injuryRecord.recoveryPhase];
  const phaseColor = recoveryPhaseColor(injuryRecord.recoveryPhase);

  const injuryDate = new Date(injuryRecord.injuryDate);
  const dateLabel = injuryDate.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });

  return (
    <View style={styles.container}>
      {/* Header nav */}
      <View style={styles.navHeader}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backBtnText}>Back</Text>
        </TouchableOpacity>
        <Text style={styles.navTitle}>Injury Profile</Text>
        <View style={styles.backBtn} />
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent}>

        {/* ── Section 1: Header ── */}
        <View style={styles.card}>
          <View style={styles.locationRow}>
            <Text style={styles.locationTitle}>{locationLabel}</Text>
            <View style={[styles.phaseBadge, { backgroundColor: phaseColor }]}>
              <Text style={styles.phaseText}>{phaseLabel}</Text>
            </View>
          </View>
          <Text style={styles.dateText}>Injured: {dateLabel}</Text>
          {injuryRecord.notes ? (
            <Text style={styles.notesText}>{injuryRecord.notes}</Text>
          ) : null}
        </View>

        {/* ── Section 4: Phase Transition Advice (shown if suggested) ── */}
        {transition !== null && (
          <View style={styles.transitionBanner}>
            <Text style={styles.transitionTitle}>Ready to Progress?</Text>
            <Text style={styles.transitionText}>
              Based on your pain trends, you may be ready to advance from{' '}
              <Text style={styles.transitionBold}>{PHASE_DISPLAY_LABELS[transition.currentPhase]}</Text>{' '}
              to{' '}
              <Text style={styles.transitionBold}>{PHASE_DISPLAY_LABELS[transition.suggestedPhase]}</Text>.
            </Text>
            <TouchableOpacity
              style={[styles.updatePhaseBtn, isUpdatingPhase && styles.updatePhaseBtnDisabled]}
              onPress={() => void handleUpdatePhase(transition.suggestedPhase)}
              disabled={isUpdatingPhase}
              activeOpacity={0.85}
            >
              <Text style={styles.updatePhaseBtnText}>
                {isUpdatingPhase ? 'Updating...' : `Update to ${PHASE_DISPLAY_LABELS[transition.suggestedPhase]}`}
              </Text>
            </TouchableOpacity>
          </View>
        )}

        {/* ── Section 2: Pain Logging ── */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>How's your {locationLabel} feeling?</Text>
          <View style={styles.sliderRow}>
            <Text style={styles.sliderLabel}>1</Text>
            <View style={styles.sliderContainer}>
              <Slider
                style={styles.slider}
                minimumValue={1}
                maximumValue={10}
                step={1}
                value={painSliderValue}
                onValueChange={setPainSliderValue}
                minimumTrackTintColor={colors.ORANGE}
                maximumTrackTintColor={colors.GREY_LIGHT}
                thumbTintColor={colors.ORANGE}
                accessibilityLabel="Pain level slider"
              />
            </View>
            <Text style={styles.sliderLabel}>10</Text>
          </View>
          <Text style={styles.currentPainLabel}>
            Pain level: <Text style={styles.currentPainValue}>{Math.round(painSliderValue)}/10</Text>
          </Text>
          {painLogs.length > 0 && (
            <Text style={styles.lastLoggedText}>
              Last logged: {painLogs[0].painLevel}/10
            </Text>
          )}
          <TouchableOpacity
            style={[styles.logPainBtn, isLoggingPain && styles.logPainBtnDisabled]}
            onPress={() => void handleLogPain()}
            disabled={isLoggingPain}
            activeOpacity={0.85}
          >
            <Text style={styles.logPainBtnText}>
              {isLoggingPain ? 'Logging...' : 'Log Pain'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* ── Section 3: Pain Trend Chart ── */}
        <PainTrendChart painLogs={painLogs} trendResult={trendResult} />

        {/* ── Section 5: Rehab Session ── */}
        {(injuryRecord.recoveryPhase === 'rehab' || injuryRecord.recoveryPhase === 'lightLoad') && (
          <View style={styles.card}>
            <Text style={styles.sectionTitle}>Rehab Session</Text>
            <Text style={styles.sectionSubtitle}>
              Generate a 10-15 minute recovery session tailored to your {locationLabel} injury.
            </Text>
            <TouchableOpacity
              style={styles.generateBtn}
              onPress={handleGenerateRehab}
              activeOpacity={0.85}
            >
              <Text style={styles.generateBtnText}>Generate Rehab Session</Text>
            </TouchableOpacity>

            {showRehabSession && rehabSession !== null && (
              <View style={styles.rehabList}>
                <Text style={styles.rehabTitle}>{rehabSession.name}</Text>
                {rehabSession.exercises.map((ex, idx) => (
                  <View key={ex.id} style={styles.rehabExerciseRow}>
                    <Text style={styles.rehabExerciseIdx}>{idx + 1}.</Text>
                    <View style={styles.rehabExerciseContent}>
                      <Text style={styles.rehabExerciseName}>{ex.name}</Text>
                      <Text style={styles.rehabExerciseDetail}>
                        {ex.sets} sets ×{' '}
                        {ex.reps.kind === 'fixed'
                          ? `${ex.reps.value} reps`
                          : ex.reps.kind === 'range'
                          ? `${ex.reps.lo}-${ex.reps.hi} reps`
                          : 'AMRAP'}
                      </Text>
                    </View>
                  </View>
                ))}
                <TouchableOpacity
                  style={styles.startSessionBtn}
                  onPress={handleStartRehabSession}
                  activeOpacity={0.85}
                >
                  <Text style={styles.startSessionBtnText}>Start Session</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        )}

        {/* ── Section 6: Adaptation / Exercise Substitutions — Premium only ── */}
        {isPremium ? (
          <InjurySubstitutionCard injury={injury} substitutions={substitutions} />
        ) : (
          <TouchableOpacity
            style={styles.adaptationGate}
            onPress={() => setShowPaywall(true)}
            activeOpacity={0.7}
            testID="injury-adaptation-gate"
          >
            <View style={styles.adaptationGateHeader}>
              <Text style={styles.adaptationGateTitle}>Exercise Adaptation</Text>
              <PremiumBadge />
            </View>
            <Text style={styles.adaptationGateBody}>
              Unlock Premium to get smart exercise substitutions tailored to your {locationLabel} injury.
            </Text>
          </TouchableOpacity>
        )}

        {/* Paywall for non-premium users */}
        <PaywallModal
          visible={showPaywall}
          onDismiss={() => setShowPaywall(false)}
          onSubscribed={() => setShowPaywall(false)}
        />

        <View style={styles.bottomSpacer} />
      </ScrollView>
    </View>
  );
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
    gap: 12,
  },
  errorText: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.NAVY,
  },
  backLink: {
    color: colors.ORANGE,
    fontSize: 16,
    fontWeight: '600',
  },
  navHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 56,
    paddingBottom: 12,
    backgroundColor: colors.CREAM,
    borderBottomWidth: 1,
    borderBottomColor: colors.GREY_LIGHT,
  },
  backBtn: {
    width: 60,
  },
  backBtnText: {
    color: colors.ORANGE,
    fontSize: 16,
    fontWeight: '600',
  },
  navTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
    gap: 14,
  },
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E8E4D6',
    gap: 8,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  locationTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
    flex: 1,
  },
  phaseBadge: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 12,
  },
  phaseText: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  dateText: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
  },
  notesText: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    fontStyle: 'italic',
    lineHeight: 20,
  },
  // Transition banner
  transitionBanner: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1.5,
    borderColor: colors.ORANGE,
    gap: 10,
  },
  transitionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
  },
  transitionText: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    lineHeight: 20,
  },
  transitionBold: {
    fontWeight: '700',
    color: colors.NAVY,
  },
  updatePhaseBtn: {
    backgroundColor: colors.NAVY,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  updatePhaseBtnDisabled: {
    opacity: 0.6,
  },
  updatePhaseBtnText: {
    color: colors.CREAM,
    fontSize: 15,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  // Pain logging
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.2,
  },
  sectionSubtitle: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
    marginTop: -4,
  },
  sliderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 8,
  },
  sliderLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.NAVY_MEDIUM,
    width: 16,
    textAlign: 'center',
  },
  sliderContainer: {
    flex: 1,
  },
  slider: {
    width: '100%',
    height: 40,
  },
  currentPainLabel: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
  },
  currentPainValue: {
    fontWeight: '700',
    color: colors.NAVY,
    fontSize: 16,
  },
  lastLoggedText: {
    fontSize: 13,
    color: colors.GREY,
    textAlign: 'center',
  },
  logPainBtn: {
    backgroundColor: colors.ORANGE,
    paddingVertical: 13,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 4,
  },
  logPainBtnDisabled: {
    opacity: 0.6,
  },
  logPainBtnText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  // Rehab session
  generateBtn: {
    backgroundColor: colors.NAVY,
    paddingVertical: 13,
    borderRadius: 10,
    alignItems: 'center',
  },
  generateBtnText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  rehabList: {
    marginTop: 12,
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
    paddingTop: 12,
    gap: 8,
  },
  rehabTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 4,
  },
  rehabExerciseRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    paddingVertical: 6,
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
  },
  rehabExerciseIdx: {
    fontSize: 13,
    color: colors.GREY,
    fontWeight: '600',
    width: 20,
    marginTop: 1,
  },
  rehabExerciseContent: {
    flex: 1,
    gap: 2,
  },
  rehabExerciseName: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.NAVY,
  },
  rehabExerciseDetail: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
  },
  startSessionBtn: {
    backgroundColor: colors.ORANGE,
    paddingVertical: 13,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 8,
  },
  startSessionBtnText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  bottomSpacer: {
    height: 40,
  },
  adaptationGate: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 16,
    gap: 8,
  },
  adaptationGateHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  adaptationGateTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
  },
  adaptationGateBody: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
  },
});
