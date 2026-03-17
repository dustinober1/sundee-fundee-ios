/**
 * injuries/body-map.tsx — Body map screen for creating a new injury profile.
 *
 * Step 1: User taps a body region on the BodyMap component.
 * Step 2: Bottom sheet appears with phase picker, optional notes, and Save button.
 *
 * On save: creates InjuryProfileRecord with uuid(), saves via InjuryRepo,
 *          navigates back to injury list.
 *
 * UID is threaded from useSession() — never hardcoded.
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Modal,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getInjuryRepo } from '@/src/repositories/InjuryRepo';
import { BodyMap } from '@/src/components/injury/BodyMap';
import type { BodyLocation, RecoveryPhase } from '@/src/domain/types/index';
import * as colors from '@/src/theme/colors';

// ─── Phase picker options (no "resolved" on create) ──────────────────────────

interface PhaseOption {
  phase: RecoveryPhase;
  label: string;
  description: string;
}

const PHASE_OPTIONS: PhaseOption[] = [
  { phase: 'acute',         label: 'Acute',          description: 'Initial injury phase — rest & protect' },
  { phase: 'rehab',         label: 'Rehab',          description: 'Active recovery exercises, limited load' },
  { phase: 'lightLoad',     label: 'Light Load',     description: 'Progressing load, monitor pain carefully' },
  { phase: 'returnToPlay',  label: 'Return to Play', description: 'Near full capacity, sport-specific prep' },
];

// ─── Utility: generate a UUID-like string ────────────────────────────────────

function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// ─── BodyMapScreen ────────────────────────────────────────────────────────────

export default function BodyMapScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const router = useRouter();

  const [selectedLocation, setSelectedLocation] = useState<BodyLocation | null>(null);
  const [selectedPhase, setSelectedPhase] = useState<RecoveryPhase>('acute');
  const [notes, setNotes] = useState('');
  const [showSheet, setShowSheet] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  function handleLocationSelect(location: BodyLocation): void {
    setSelectedLocation(location);
    setShowSheet(true);
  }

  async function handleSave(): Promise<void> {
    if (!user || !selectedLocation) return;
    setIsSaving(true);

    try {
      const repo = getInjuryRepo(isGuest);
      const id = generateUUID();
      await repo.saveInjury(user.uid, {
        id,
        uid: user.uid,
        bodyLocation: selectedLocation,
        recoveryPhase: selectedPhase,
        injuryDate: new Date().toISOString(),
        notes: notes.trim() || undefined,
        location: selectedLocation,
      });
      router.back();
    } catch (err) {
      console.error('[BodyMapScreen] Failed to save injury:', err);
      setIsSaving(false);
    }
  }

  function handleCloseSheet(): void {
    setShowSheet(false);
    setSelectedLocation(null);
    setSelectedPhase('acute');
    setNotes('');
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => router.back()}
          style={styles.cancelBtn}
          accessibilityLabel="Cancel"
        >
          <Text style={styles.cancelBtnText}>Cancel</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Where's the injury?</Text>
        <View style={styles.cancelBtn} />
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent}>
        <Text style={styles.instruction}>
          Tap a body region to mark your injury location.
        </Text>
        <BodyMap
          onSelectLocation={handleLocationSelect}
          selectedLocation={selectedLocation}
        />
      </ScrollView>

      {/* Bottom sheet modal */}
      <Modal
        visible={showSheet}
        transparent
        animationType="slide"
        onRequestClose={handleCloseSheet}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.overlay}
        >
          <TouchableOpacity style={styles.overlayDismiss} onPress={handleCloseSheet} />
          <View style={styles.sheet}>
            {/* Sheet header */}
            <View style={styles.sheetHandle} />
            <Text style={styles.sheetTitle}>
              {selectedLocation ? BodyMap.locationLabel(selectedLocation) : ''} Injury
            </Text>

            {/* Phase picker */}
            <Text style={styles.sectionLabel}>Recovery Phase</Text>
            <View style={styles.phaseChips}>
              {PHASE_OPTIONS.map((option) => (
                <TouchableOpacity
                  key={option.phase}
                  style={[
                    styles.phaseChip,
                    selectedPhase === option.phase && styles.phaseChipSelected,
                  ]}
                  onPress={() => setSelectedPhase(option.phase)}
                  activeOpacity={0.75}
                  accessibilityRole="radio"
                  accessibilityState={{ checked: selectedPhase === option.phase }}
                >
                  <Text
                    style={[
                      styles.phaseChipText,
                      selectedPhase === option.phase && styles.phaseChipTextSelected,
                    ]}
                  >
                    {option.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            {/* Phase description */}
            {(() => {
              const option = PHASE_OPTIONS.find((o) => o.phase === selectedPhase);
              return option ? (
                <Text style={styles.phaseDescription}>{option.description}</Text>
              ) : null;
            })()}

            {/* Notes input */}
            <Text style={styles.sectionLabel}>Notes (optional)</Text>
            <TextInput
              style={styles.notesInput}
              value={notes}
              onChangeText={setNotes}
              placeholder="e.g. ACL sprain, dull ache on extension..."
              placeholderTextColor={colors.GREY}
              multiline
              maxLength={200}
            />

            {/* Save button */}
            <TouchableOpacity
              style={[styles.saveBtn, isSaving && styles.saveBtnDisabled]}
              onPress={() => void handleSave()}
              disabled={isSaving}
              activeOpacity={0.85}
              accessibilityRole="button"
            >
              <Text style={styles.saveBtnText}>
                {isSaving ? 'Saving...' : 'Save Injury'}
              </Text>
            </TouchableOpacity>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  header: {
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
  cancelBtn: {
    width: 60,
  },
  cancelBtnText: {
    color: colors.ORANGE,
    fontSize: 16,
    fontWeight: '600',
  },
  headerTitle: {
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
  },
  instruction: {
    fontSize: 15,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
    marginBottom: 16,
    lineHeight: 22,
  },
  overlay: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  overlayDismiss: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    backgroundColor: colors.CREAM,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 24,
    paddingBottom: 40,
    gap: 12,
  },
  sheetHandle: {
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.GREY_LIGHT,
    alignSelf: 'center',
    marginBottom: 8,
  },
  sheetTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.NAVY,
    textAlign: 'center',
    marginBottom: 4,
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.NAVY_MEDIUM,
    letterSpacing: 0.6,
    textTransform: 'uppercase',
    marginTop: 4,
  },
  phaseChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  phaseChip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: colors.GREY_LIGHT,
    backgroundColor: colors.CREAM_LIGHT,
  },
  phaseChipSelected: {
    backgroundColor: colors.NAVY,
    borderColor: colors.NAVY,
  },
  phaseChipText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.NAVY,
  },
  phaseChipTextSelected: {
    color: colors.CREAM,
  },
  phaseDescription: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
    marginTop: -4,
  },
  notesInput: {
    backgroundColor: colors.CREAM_LIGHT,
    borderWidth: 1.5,
    borderColor: colors.GREY_LIGHT,
    borderRadius: 10,
    padding: 12,
    fontSize: 15,
    color: colors.NAVY,
    minHeight: 72,
    textAlignVertical: 'top',
  },
  saveBtn: {
    backgroundColor: colors.ORANGE,
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 8,
  },
  saveBtnDisabled: {
    opacity: 0.6,
  },
  saveBtnText: {
    color: colors.CREAM,
    fontSize: 17,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
});
