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
 *
 * Phase 6 additions:
 * - Subscription section: plan info for subscribed users, Unlock Premium for free users
 * - Manage Subscription deep-link (iOS: App Store, Android: Play Store, Web: sundeefundee.com)
 * - Restore Purchases button (mobile only — required by Apple/Google App Review)
 * - TrialEndedModal shown once after trial expiry
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Linking,
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
import { useEntitlementContext } from '@/src/entitlements/EntitlementContext';
import { getSettingsRepo, DEFAULT_SETTINGS, type AppSettings } from '@/src/repositories/SettingsRepo';
import { PaywallModal } from '@/src/components/paywall/PaywallModal';
import { TrialEndedModal } from '@/src/components/paywall/TrialEndedModal';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as colors from '@/src/theme/colors';

/** Allowed rest duration values in seconds. */
const REST_DURATION_OPTIONS = [30, 45, 60, 90, 120, 150, 180, 240, 300];

/** Weight unit display options. */
const WEIGHT_UNIT_OPTIONS: Array<{ value: 'lb' | 'kg'; label: string }> = [
  { value: 'lb', label: 'lbs' },
  { value: 'kg', label: 'kg' },
];

/** AsyncStorage key to track trial ended modal shown state. */
const TRIAL_ENDED_MODAL_SHOWN_KEY = 'trialEndedModalShown';

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

/** Subscription info loaded from RevenueCat on mobile */
interface SubscriptionInfo {
  planName: string;
  renewalDate: string | null;
  isTrialing: boolean;
  managementURL: string | null;
}

export default function SettingsScreen(): React.JSX.Element {
  const { user, isGuest, signOut } = useSession();
  const { isPremium } = useEntitlementContext();
  const router = useRouter();
  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [showRestPicker, setShowRestPicker] = useState(false);
  const [showWeightUnitPicker, setShowWeightUnitPicker] = useState(false);
  const [subscriptionInfo, setSubscriptionInfo] = useState<SubscriptionInfo | null>(null);
  const [isRestoring, setIsRestoring] = useState(false);
  const [showPaywall, setShowPaywall] = useState(false);
  const [showTrialEndedModal, setShowTrialEndedModal] = useState(false);

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

  const loadSubscriptionInfo = useCallback(async (): Promise<void> => {
    if (!user || isGuest || Platform.OS === 'web') return;

    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Purchases = require('react-native-purchases').default;
      const customerInfo = await Purchases.getCustomerInfo();
      const premiumEntitlement = customerInfo?.entitlements?.active?.premium;

      if (premiumEntitlement) {
        const productId = premiumEntitlement.productIdentifier ?? '';
        const planName = productId.includes('annual') ? 'Premium Annual' : 'Premium Monthly';
        const expirationDate = premiumEntitlement.expirationDate;
        const renewalDate = expirationDate
          ? new Date(expirationDate).toLocaleDateString('en-US', {
              month: 'long',
              day: 'numeric',
              year: 'numeric',
            })
          : null;

        setSubscriptionInfo({
          planName,
          renewalDate,
          isTrialing: premiumEntitlement.periodType === 'TRIAL',
          managementURL: customerInfo?.managementURL ?? null,
        });
      }
    } catch {
      // RevenueCat unavailable — gracefully degrade
    }
  }, [user, isGuest]);

  const checkTrialEndedModal = useCallback(async (): Promise<void> => {
    if (!user || isGuest || Platform.OS === 'web') return;

    try {
      // Already shown?
      const alreadyShown = await AsyncStorage.getItem(TRIAL_ENDED_MODAL_SHOWN_KEY);
      if (alreadyShown === 'true') return;

      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Purchases = require('react-native-purchases').default;
      const customerInfo = await Purchases.getCustomerInfo();
      const premiumEntitlement = customerInfo?.entitlements?.active?.premium;

      // Trial ended = had premium entitlement that was TRIAL, but no longer active
      // OR: check all entitlements for expired trial
      const allPremium = customerInfo?.entitlements?.all?.premium;
      if (
        allPremium &&
        !premiumEntitlement && // not currently active
        allPremium.periodType === 'TRIAL'
      ) {
        setShowTrialEndedModal(true);
      }
    } catch {
      // Non-critical
    }
  }, [user, isGuest]);

  useEffect(() => {
    void loadSettings();
    void loadSubscriptionInfo();
    void checkTrialEndedModal();
  }, [loadSettings, loadSubscriptionInfo, checkTrialEndedModal]);

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

  async function handleSelectWeightUnit(unit: 'lb' | 'kg'): Promise<void> {
    setShowWeightUnitPicker(false);
    if (!user) return;
    const updated: AppSettings = { ...settings, weightUnit: unit };
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

  async function handleManageSubscription(): Promise<void> {
    if (Platform.OS === 'ios') {
      await Linking.openURL('itms-apps://apps.apple.com/account/subscriptions');
    } else if (Platform.OS === 'android' && subscriptionInfo?.managementURL) {
      await Linking.openURL(subscriptionInfo.managementURL);
    }
    // Web: show static text in UI (handled in render)
  }

  async function handleRestorePurchases(): Promise<void> {
    if (isRestoring) return;
    setIsRestoring(true);
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Purchases = require('react-native-purchases').default;
      const customerInfo = await Purchases.restorePurchases();
      const hasActive = Object.keys(customerInfo?.entitlements?.active ?? {}).length > 0;

      Alert.alert(
        'Restore Purchases',
        hasActive
          ? 'Your purchases have been restored successfully.'
          : 'No purchases found to restore.',
        [{ text: 'OK' }]
      );
    } catch {
      Alert.alert(
        'Restore Failed',
        'Could not restore purchases. Please try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setIsRestoring(false);
    }
  }

  async function handleDismissTrialEndedModal(): Promise<void> {
    try {
      await AsyncStorage.setItem(TRIAL_ENDED_MODAL_SHOWN_KEY, 'true');
    } catch {
      // Non-critical
    }
    setShowTrialEndedModal(false);
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

      {/* Weight Unit section — between Rest Timer and Subscription */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Weight Unit</Text>
        <View style={styles.settingRow}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>Display Unit</Text>
            <Text style={styles.settingHint}>
              Weights shown throughout the app in your chosen unit
            </Text>
          </View>
          <TouchableOpacity
            style={styles.settingValue}
            onPress={() => setShowWeightUnitPicker(true)}
            activeOpacity={0.7}
            testID="weight-unit-picker-trigger"
          >
            <Text style={styles.settingValueText}>
              {settings.weightUnit === 'kg' ? 'kg' : 'lbs'}
            </Text>
            <Text style={styles.chevron}>›</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Subscription section — between Rest Timer and About */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Subscription</Text>

        {isPremium ? (
          /* Subscribed state */
          <View style={styles.subscriptionCard}>
            <View style={styles.subscriptionPlanRow}>
              <Text style={styles.subscriptionPlanName}>
                {subscriptionInfo?.isTrialing
                  ? 'Free Trial'
                  : (subscriptionInfo?.planName ?? 'Premium')}
              </Text>
              <View style={styles.activeBadge}>
                <Text style={styles.activeBadgeText}>Active</Text>
              </View>
            </View>
            {subscriptionInfo?.renewalDate != null && (
              <Text style={styles.subscriptionRenewal}>
                {subscriptionInfo.isTrialing ? 'Expires' : 'Renews'}: {subscriptionInfo.renewalDate}
              </Text>
            )}

            {/* Manage Subscription — platform-specific */}
            {Platform.OS !== 'web' ? (
              <TouchableOpacity
                style={styles.manageRow}
                onPress={() => void handleManageSubscription()}
                activeOpacity={0.7}
                testID="manage-subscription-row"
              >
                <Text style={styles.manageLabel}>Manage Subscription</Text>
                <Text style={styles.chevron}>›</Text>
              </TouchableOpacity>
            ) : (
              <View style={styles.manageRow} testID="manage-subscription-row">
                <Text style={styles.manageLabel}>Manage on sundeefundee.com</Text>
              </View>
            )}
          </View>
        ) : (
          /* Non-subscribed state */
          <View style={styles.unlockCard}>
            <Text style={styles.unlockTitle}>Unlock Premium</Text>
            <Text style={styles.unlockBody}>
              AI Workouts, Cycle Adaptation, Programs, and Injury Adaptation — all in one.
            </Text>
            <TouchableOpacity
              style={styles.viewPlansButton}
              onPress={() => setShowPaywall(true)}
              activeOpacity={0.8}
              testID="view-plans-button"
            >
              <Text style={styles.viewPlansText}>View Plans</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Restore Purchases — mobile only (required by Apple/Google App Review) */}
        {Platform.OS !== 'web' && (
          <TouchableOpacity
            style={[styles.restoreButton, isRestoring && styles.restoreButtonDisabled]}
            onPress={() => void handleRestorePurchases()}
            activeOpacity={0.7}
            disabled={isRestoring}
            testID="restore-purchases-button"
          >
            <Text style={styles.restoreText}>
              {isRestoring ? 'Restoring…' : 'Restore Purchases'}
            </Text>
          </TouchableOpacity>
        )}
      </View>

      {/* App info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Version</Text>
          <Text style={styles.infoValue}>1.0.0 (Phase 6)</Text>
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

      {/* Weight unit picker modal */}
      <Modal
        visible={showWeightUnitPicker}
        transparent
        animationType="slide"
        onRequestClose={() => setShowWeightUnitPicker(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowWeightUnitPicker(false)}
        >
          <View style={styles.pickerSheet}>
            <Text style={styles.pickerTitle}>Weight Unit</Text>
            {WEIGHT_UNIT_OPTIONS.map((option) => {
              const isSelected = settings.weightUnit === option.value;
              return (
                <TouchableOpacity
                  key={option.value}
                  style={[styles.pickerOption, isSelected && styles.pickerOptionSelected]}
                  onPress={() => void handleSelectWeightUnit(option.value)}
                  activeOpacity={0.7}
                  testID={`weight-unit-option-${option.value}`}
                >
                  <Text
                    style={[
                      styles.pickerOptionText,
                      isSelected && styles.pickerOptionTextSelected,
                    ]}
                  >
                    {option.label}
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

      {/* Paywall modal */}
      <PaywallModal
        visible={showPaywall}
        onDismiss={() => setShowPaywall(false)}
        onSubscribed={() => setShowPaywall(false)}
      />

      {/* Trial Ended modal — shown once after trial expiry */}
      <TrialEndedModal
        visible={showTrialEndedModal}
        onDismiss={() => void handleDismissTrialEndedModal()}
        onSubscribe={() => {
          setShowTrialEndedModal(false);
          setShowPaywall(true);
        }}
      />
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
  // Subscription section
  subscriptionCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 14,
    marginBottom: 10,
    gap: 8,
  },
  subscriptionPlanRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  subscriptionPlanName: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
  },
  activeBadge: {
    backgroundColor: '#27AE60',
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  activeBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#fff',
    letterSpacing: 0.3,
  },
  subscriptionRenewal: {
    fontSize: 13,
    color: colors.GREY,
  },
  manageRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
    marginTop: 4,
  },
  manageLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.ORANGE,
  },
  unlockCard: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    padding: 14,
    marginBottom: 10,
    gap: 8,
  },
  unlockTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
  },
  unlockBody: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
  },
  viewPlansButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 4,
  },
  viewPlansText: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.3,
  },
  restoreButton: {
    paddingVertical: 12,
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    backgroundColor: colors.CREAM_LIGHT,
  },
  restoreButtonDisabled: {
    opacity: 0.6,
  },
  restoreText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.GREY,
  },
  // App info
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
