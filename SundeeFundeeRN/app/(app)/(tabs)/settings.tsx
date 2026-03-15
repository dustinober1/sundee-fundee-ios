/**
 * app/(app)/(tabs)/settings.tsx — Settings screen.
 *
 * Per locked design decisions:
 * - "Create Account" button visible ONLY for guest users
 * - Sign-out requires confirmation dialog (Alert.alert)
 * - After sign-out: onAuthStateChanged triggers automatic redirect to /sign-in
 *
 * Phase 4 additions:
 * - Rest Timer section: default rest duration picker (30–300 seconds)
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getSettingsRepo, DEFAULT_SETTINGS, type AppSettings } from '@/src/repositories/SettingsRepo';
import * as colors from '@/src/theme/colors';

/** Allowed rest duration values in seconds. */
const REST_DURATION_OPTIONS = [30, 45, 60, 90, 120, 150, 180, 240, 300];

/** Format seconds as a human-readable duration label. */
export function formatRestDuration(seconds: number): string {
  if (seconds < 60) {
    return `${seconds} seconds`;
  }
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  if (secs === 0) {
    return `${mins} minute${mins !== 1 ? 's' : ''}`;
  }
  return `${mins}m ${secs}s`;
}

export default function SettingsScreen(): React.JSX.Element {
  const { user, isGuest, signOut } = useSession();
  const router = useRouter();
  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [showRestPicker, setShowRestPicker] = useState(false);

  const loadSettings = useCallback(async (): Promise<void> => {
    if (!user) return;
    try {
      const repo = getSettingsRepo(isGuest);
      const stored = await repo.getSettings(user.uid);
      if (stored) {
        setSettings({ ...DEFAULT_SETTINGS, ...stored });
      }
    } catch {
      // Keep defaults on error
    }
  }, [user, isGuest]);

  useEffect(() => {
    void loadSettings();
  }, [loadSettings]);

  async function handleSelectRestDuration(seconds: number): Promise<void> {
    setShowRestPicker(false);
    if (!user) return;
    const updated: AppSettings = { ...settings, defaultRestDuration: seconds };
    setSettings(updated);
    try {
      const repo = getSettingsRepo(isGuest);
      await repo.saveSettings(user.uid, updated);
    } catch {
      // Revert on save error
      setSettings(settings);
    }
  }

  function handleSignOut(): void {
    if (Platform.OS === 'web') {
      // Alert.alert is a no-op on web — use window.confirm instead
      const confirmed = window.confirm('Are you sure you want to sign out?');
      if (confirmed) {
        void signOut();
      }
      return;
    }

    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Sign Out',
          style: 'destructive',
          onPress: () => {
            void signOut();
          },
        },
      ],
      { cancelable: true }
    );
  }

  function handleCreateAccount(): void {
    router.push('/sign-in');
  }

  const displayName = isGuest
    ? 'Guest User'
    : (user?.displayName ?? user?.email ?? 'Account');

  return (
    <ScrollView
      style={styles.scrollView}
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* User info section */}
      <View style={styles.userCard}>
        <View style={styles.avatarPlaceholder}>
          <Text style={styles.avatarText}>
            {isGuest ? 'G' : (displayName[0]?.toUpperCase() ?? 'U')}
          </Text>
        </View>
        <View style={styles.userInfo}>
          <Text style={styles.userName}>{displayName}</Text>
          {!isGuest && user?.email != null && (
            <Text style={styles.userEmail}>{user.email}</Text>
          )}
          {isGuest && (
            <Text style={styles.guestLabel}>Guest — data stored locally</Text>
          )}
        </View>
      </View>

      {/* Create Account — visible only for guest users (per locked decision) */}
      {isGuest && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Account</Text>
          <TouchableOpacity
            style={styles.createAccountButton}
            onPress={handleCreateAccount}
            activeOpacity={0.8}
            testID="create-account-button"
          >
            <Text style={styles.createAccountText}>Create Account</Text>
          </TouchableOpacity>
          <Text style={styles.createAccountSubtext}>
            Sync your data across devices
          </Text>
        </View>
      )}

      {/* Rest Timer section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Rest Timer</Text>
        <View style={styles.settingRow}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>Default Rest Duration</Text>
            <Text style={styles.settingHint}>
              Time between sets before the next reminder
            </Text>
          </View>
          <TouchableOpacity
            style={styles.settingValue}
            onPress={() => setShowRestPicker(true)}
            activeOpacity={0.7}
            testID="rest-duration-picker-trigger"
          >
            <Text style={styles.settingValueText}>
              {formatRestDuration(settings.defaultRestDuration ?? DEFAULT_SETTINGS.defaultRestDuration)}
            </Text>
            <Text style={styles.chevron}>›</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* App info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Version</Text>
          <Text style={styles.infoValue}>1.0.0 (Phase 4)</Text>
        </View>
      </View>

      {/* Sign out (per locked decision: always at bottom with confirmation) */}
      <TouchableOpacity
        style={styles.signOutButton}
        onPress={handleSignOut}
        activeOpacity={0.7}
        testID="sign-out-button"
      >
        <Text style={styles.signOutText}>Sign Out</Text>
      </TouchableOpacity>

      {/* Rest duration picker modal */}
      <Modal
        visible={showRestPicker}
        transparent
        animationType="slide"
        onRequestClose={() => setShowRestPicker(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowRestPicker(false)}
        >
          <View style={styles.pickerSheet}>
            <Text style={styles.pickerTitle}>Default Rest Duration</Text>
            {REST_DURATION_OPTIONS.map((seconds) => {
              const isSelected =
                (settings.defaultRestDuration ?? DEFAULT_SETTINGS.defaultRestDuration) === seconds;
              return (
                <TouchableOpacity
                  key={seconds}
                  style={[styles.pickerOption, isSelected && styles.pickerOptionSelected]}
                  onPress={() => void handleSelectRestDuration(seconds)}
                  activeOpacity={0.7}
                  testID={`rest-duration-option-${seconds}`}
                >
                  <Text
                    style={[
                      styles.pickerOptionText,
                      isSelected && styles.pickerOptionTextSelected,
                    ]}
                  >
                    {formatRestDuration(seconds)}
                  </Text>
                  {isSelected && (
                    <Text style={styles.pickerCheckmark}>✓</Text>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        </TouchableOpacity>
      </Modal>
    </ScrollView>
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
    paddingTop: 24,
    paddingBottom: 40,
  },
  userCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 16,
    marginBottom: 24,
  },
  avatarPlaceholder: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.NAVY,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
  },
  avatarText: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.CREAM,
  },
  userInfo: {
    flex: 1,
  },
  userName: {
    fontSize: 17,
    fontWeight: '600',
    color: colors.NAVY,
    marginBottom: 2,
  },
  userEmail: {
    fontSize: 13,
    color: colors.GREY,
  },
  guestLabel: {
    fontSize: 12,
    color: colors.GREY,
    fontStyle: 'italic',
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  createAccountButton: {
    backgroundColor: colors.NAVY,
    borderRadius: 8,
    paddingVertical: 14,
    alignItems: 'center',
    marginBottom: 8,
  },
  createAccountText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
  createAccountSubtext: {
    fontSize: 12,
    color: colors.GREY,
    textAlign: 'center',
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    paddingVertical: 12,
    paddingHorizontal: 14,
  },
  settingInfo: {
    flex: 1,
  },
  settingLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.NAVY,
    marginBottom: 2,
  },
  settingHint: {
    fontSize: 11,
    color: colors.GREY,
    lineHeight: 14,
  },
  settingValue: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  settingValueText: {
    fontSize: 14,
    color: colors.ORANGE,
    fontWeight: '600',
  },
  chevron: {
    fontSize: 18,
    color: colors.GREY,
    marginTop: -1,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.GREY_LIGHT,
  },
  infoLabel: {
    fontSize: 14,
    color: colors.NAVY,
  },
  infoValue: {
    fontSize: 14,
    color: colors.GREY,
  },
  signOutButton: {
    width: '100%',
    height: 52,
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: colors.RED,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
    marginBottom: 8,
  },
  signOutText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.RED,
    letterSpacing: 0.5,
  },
  // Modal / picker styles
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'flex-end',
  },
  pickerSheet: {
    backgroundColor: colors.CREAM,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingHorizontal: 24,
    paddingTop: 20,
    paddingBottom: 40,
  },
  pickerTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.5,
    marginBottom: 16,
    textAlign: 'center',
  },
  pickerOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
    paddingHorizontal: 12,
    borderRadius: 8,
    marginBottom: 4,
  },
  pickerOptionSelected: {
    backgroundColor: colors.ORANGE_LIGHT,
  },
  pickerOptionText: {
    fontSize: 15,
    color: colors.NAVY,
  },
  pickerOptionTextSelected: {
    fontWeight: '700',
    color: colors.ORANGE,
  },
  pickerCheckmark: {
    fontSize: 16,
    color: colors.ORANGE,
    fontWeight: '700',
  },
});
