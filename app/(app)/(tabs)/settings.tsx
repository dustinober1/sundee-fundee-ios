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
 *
 * Phase 7 additions:
 * - Data section: Export Data (CSV zip or JSON) with share sheet / browser download
 * - Danger Zone section: Delete Account (authenticated) or Clear Local Data (guest)
 * - Delete Account: two-step confirmation with "DELETE" text input, Cloud Function call
 * - Goodbye screen on successful deletion
 *
 * Phase 20 additions:
 * - Notifications section: 4 independent toggles (Rest Timer Alerts, Workout Reminders,
 *   WOD Alerts, Subscription Alerts), time picker for daily reminder, OS permission banner
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Linking,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useFocusEffect } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { useEntitlementContext } from '@/src/entitlements/EntitlementContext';
import { getSettingsRepo, DEFAULT_SETTINGS, type AppSettings } from '@/src/repositories/SettingsRepo';
import { PaywallModal } from '@/src/components/paywall/PaywallModal';
import { TrialEndedModal } from '@/src/components/paywall/TrialEndedModal';
import { exportUserData } from '@/src/export/exportData';
import { getWorkoutRepo } from '@/src/repositories/WorkoutRepo';
import { getExerciseMaxRepo } from '@/src/repositories/ExerciseMaxRepo';
import { getBenchmarkRepo } from '@/src/repositories/BenchmarkRepo';
import { getCycleRepo } from '@/src/repositories/CycleRepo';
import { getInjuryRepo } from '@/src/repositories/InjuryRepo';
import { getReadinessRepo } from '@/src/repositories/ReadinessRepo';
import { callCloudFunction } from '@/src/services/callCloudFunction';
import { scheduleDailyReminder, cancelDailyReminder } from '@/src/services/notificationService';
import { useNotificationPermission } from '@/src/hooks/useNotificationPermission';
import { calculateCycleStatus } from '@/src/domain/cycle/cycle-calculations';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as colors from '@/src/theme/colors';

/** Allowed rest duration values in seconds. */
const REST_DURATION_OPTIONS = [30, 45, 60, 90, 120, 150, 180, 240, 300];

/** Hour options for the reminder time picker (0–23). */
const HOUR_OPTIONS = Array.from({ length: 24 }, (_, i) => i);

/** Minute options for the reminder time picker (quarter-hour steps). */
const MINUTE_OPTIONS = [0, 15, 30, 45];

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

/** Format hour + minute as a 12-hour time string, e.g. "7:00 AM". */
export function formatReminderTime(hour: number, minute: number): string {
  const period = hour < 12 ? 'AM' : 'PM';
  const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  const displayMinute = minute.toString().padStart(2, '0');
  return `${displayHour}:${displayMinute} ${period}`;
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

  // Export data state
  const [showExportPicker, setShowExportPicker] = useState(false);
  const [isExporting, setIsExporting] = useState(false);

  // Delete account state
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);

  // Notification permission and time picker state
  const { isDenied, checkPermission } = useNotificationPermission();
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [timePickerMode, setTimePickerMode] = useState<'hour' | 'minute'>('hour');

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

  // Re-check OS notification permission every time Settings screen comes into focus
  // (handles case where user navigated to OS Settings to grant/revoke permission)
  useFocusEffect(
    useCallback(() => {
      void checkPermission();
    }, [checkPermission])
  );

  /** Load current cycle phase from CycleRepo for personalised reminder copy. */
  async function getCurrentCyclePhase() {
    if (!user) return null;
    try {
      const cycleRepo = getCycleRepo(isGuest);
      const [cycleSettings, periodLogRecords] = await Promise.all([
        cycleRepo.getCycleSettings(user.uid),
        cycleRepo.getPeriodLogs(user.uid),
      ]);
      if (!cycleSettings || !periodLogRecords.length) return null;
      const periodLogs = periodLogRecords.map((r) => ({
        startDate: new Date(r.startDate),
        endDate: r.endDate ? new Date(r.endDate) : undefined,
      }));
      const status = calculateCycleStatus(periodLogs, cycleSettings);
      return status?.currentPhase ?? null;
    } catch {
      return null;
    }
  }

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

  async function handleToggleNotification(
    field: keyof Pick<AppSettings, 'restTimerAlertsEnabled' | 'workoutRemindersEnabled' | 'wodAlertsEnabled' | 'subscriptionAlertsEnabled'>,
    value: boolean
  ): Promise<void> {
    if (!user) return;
    const updated: AppSettings = { ...settings, [field]: value };
    setSettings(updated);
    try {
      const repo = getSettingsRepo(isGuest);
      await repo.saveSettings(user.uid, updated);
      // Wire daily reminder scheduling for Workout Reminders toggle
      if (field === 'workoutRemindersEnabled') {
        if (value) {
          const cyclePhase = await getCurrentCyclePhase();
          void scheduleDailyReminder(updated.reminderHour, updated.reminderMinute, cyclePhase);
        } else {
          void cancelDailyReminder();
        }
      }
    } catch {
      // Revert on save error
      setSettings(settings);
    }
  }

  async function handleSelectReminderTime(hour: number, minute: number): Promise<void> {
    if (!user) return;
    const updated: AppSettings = { ...settings, reminderHour: hour, reminderMinute: minute };
    setSettings(updated);
    setShowTimePicker(false);
    try {
      const repo = getSettingsRepo(isGuest);
      await repo.saveSettings(user.uid, updated);
      // Reschedule if reminders are on
      if (updated.workoutRemindersEnabled) {
        const cyclePhase = await getCurrentCyclePhase();
        void scheduleDailyReminder(hour, minute, cyclePhase);
      }
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

  async function handleExportData(format: 'csv' | 'json'): Promise<void> {
    setShowExportPicker(false);
    if (!user) return;

    setIsExporting(true);
    try {
      const repos = {
        workoutRepo: getWorkoutRepo(isGuest),
        maxRepo: getExerciseMaxRepo(isGuest),
        benchmarkRepo: getBenchmarkRepo(isGuest),
        cycleRepo: getCycleRepo(isGuest),
        injuryRepo: getInjuryRepo(isGuest),
        readinessRepo: getReadinessRepo(isGuest),
      };
      await exportUserData(user.uid, format, settings.weightUnit ?? 'lb', repos);
    } catch {
      Alert.alert(
        'Export Failed',
        'Could not export your data. Please try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setIsExporting(false);
    }
  }

  function handleOpenDeleteModal(): void {
    setDeleteConfirmText('');
    setShowDeleteModal(true);
  }

  function handleCancelDelete(): void {
    setShowDeleteModal(false);
    setDeleteConfirmText('');
  }

  async function handleConfirmDeleteAccount(): Promise<void> {
    if (deleteConfirmText !== 'DELETE' || !user) return;
    setIsDeleting(true);
    try {
      await callCloudFunction('deleteAccount', {});
      await AsyncStorage.clear();
      setShowDeleteModal(false);
      router.replace('/goodbye');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'An unexpected error occurred.';
      Alert.alert('Deletion Failed', message, [{ text: 'OK' }]);
      setIsDeleting(false);
    }
  }

  function handleClearLocalData(): void {
    if (Platform.OS === 'web') {
      const confirmed = window.confirm(
        'This will clear all your local workout data. This cannot be undone.'
      );
      if (confirmed) {
        void AsyncStorage.clear().then(() => router.replace('/sign-in'));
      }
      return;
    }

    Alert.alert(
      'Clear Local Data',
      'This will clear all your local workout data. This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear Data',
          style: 'destructive',
          onPress: () => {
            void AsyncStorage.clear().then(() => router.replace('/sign-in'));
          },
        },
      ],
      { cancelable: true }
    );
  }

  const displayName = isGuest
    ? 'Guest User'
    : (user?.displayName ?? user?.email ?? 'Account');

  const isDeleteConfirmed = deleteConfirmText === 'DELETE';

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

      {/* Notifications section — between Rest Timer and Weight Unit */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Notifications</Text>

        {/* OS Permission Denied Banner */}
        {isDenied && (
          <View style={styles.permissionBanner} testID="permission-denied-banner">
            <Text style={styles.permissionBannerText}>
              Notifications are disabled in your device settings
            </Text>
            <TouchableOpacity
              onPress={() => void Linking.openSettings()}
              activeOpacity={0.7}
              testID="open-os-settings-button"
            >
              <Text style={styles.permissionBannerLink}>Open Settings</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Rest Timer Alerts toggle */}
        <View style={[styles.toggleRow, isDenied && styles.toggleRowDisabled]}>
          <View style={styles.settingInfo}>
            <Text style={[styles.settingLabel, isDenied && styles.toggleLabelDisabled]}>
              Rest Timer Alerts
            </Text>
            <Text style={styles.settingHint}>Notify when rest timer completes</Text>
          </View>
          <Switch
            value={settings.restTimerAlertsEnabled ?? true}
            onValueChange={(value) => void handleToggleNotification('restTimerAlertsEnabled', value)}
            disabled={isDenied}
            trackColor={{ false: '#ccc', true: colors.ORANGE }}
            thumbColor="#fff"
            testID="rest-timer-alerts-toggle"
          />
        </View>

        {/* Workout Reminders toggle */}
        <View style={[styles.toggleRow, isDenied && styles.toggleRowDisabled]}>
          <View style={styles.settingInfo}>
            <Text style={[styles.settingLabel, isDenied && styles.toggleLabelDisabled]}>
              Workout Reminders
            </Text>
            <Text style={styles.settingHint}>Daily reminder to complete your training</Text>
          </View>
          <Switch
            value={settings.workoutRemindersEnabled ?? false}
            onValueChange={(value) => void handleToggleNotification('workoutRemindersEnabled', value)}
            disabled={isDenied}
            trackColor={{ false: '#ccc', true: colors.ORANGE }}
            thumbColor="#fff"
            testID="workout-reminders-toggle"
          />
        </View>

        {/* Reminder Time picker row — visible only when Workout Reminders is ON */}
        {(settings.workoutRemindersEnabled ?? false) && !isDenied && (
          <TouchableOpacity
            style={styles.reminderTimeRow}
            onPress={() => { setTimePickerMode('hour'); setShowTimePicker(true); }}
            activeOpacity={0.7}
            testID="reminder-time-picker-trigger"
          >
            <View style={styles.settingInfo}>
              <Text style={styles.settingLabel}>Reminder Time</Text>
              <Text style={styles.settingHint}>Time of day to receive your daily reminder</Text>
            </View>
            <View style={styles.settingValue}>
              <Text style={styles.settingValueText}>
                {formatReminderTime(
                  settings.reminderHour ?? DEFAULT_SETTINGS.reminderHour,
                  settings.reminderMinute ?? DEFAULT_SETTINGS.reminderMinute,
                )}
              </Text>
              <Text style={styles.chevron}>›</Text>
            </View>
          </TouchableOpacity>
        )}

        {/* WOD Alerts toggle */}
        <View style={[styles.toggleRow, isDenied && styles.toggleRowDisabled]}>
          <View style={styles.settingInfo}>
            <Text style={[styles.settingLabel, isDenied && styles.toggleLabelDisabled]}>
              WOD Alerts
            </Text>
            <Text style={styles.settingHint}>Notify when today's workout is available</Text>
          </View>
          <Switch
            value={settings.wodAlertsEnabled ?? true}
            onValueChange={(value) => void handleToggleNotification('wodAlertsEnabled', value)}
            disabled={isDenied}
            trackColor={{ false: '#ccc', true: colors.ORANGE }}
            thumbColor="#fff"
            testID="wod-alerts-toggle"
          />
        </View>

        {/* Subscription Alerts toggle */}
        <View style={[styles.toggleRow, isDenied && styles.toggleRowDisabled]}>
          <View style={styles.settingInfo}>
            <Text style={[styles.settingLabel, isDenied && styles.toggleLabelDisabled]}>
              Subscription Alerts
            </Text>
            <Text style={styles.settingHint}>Renewal and expiry reminders</Text>
          </View>
          <Switch
            value={settings.subscriptionAlertsEnabled ?? true}
            onValueChange={(value) => void handleToggleNotification('subscriptionAlertsEnabled', value)}
            disabled={isDenied}
            trackColor={{ false: '#ccc', true: colors.ORANGE }}
            thumbColor="#fff"
            testID="subscription-alerts-toggle"
          />
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

      {/* Data section — Export Data */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Data</Text>
        <TouchableOpacity
          style={styles.settingRow}
          onPress={() => setShowExportPicker(true)}
          activeOpacity={0.7}
          disabled={isExporting}
          testID="export-data-button"
        >
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>Export Data</Text>
            <Text style={styles.settingHint}>
              {isExporting ? 'Exporting…' : 'Download all your workout history and stats'}
            </Text>
          </View>
          <Text style={styles.chevron}>›</Text>
        </TouchableOpacity>
      </View>

      {/* App info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Version</Text>
          <Text style={styles.infoValue}>1.0.0 (Phase 7)</Text>
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

      {/* Danger Zone — Delete Account / Clear Local Data */}
      <View style={[styles.section, styles.dangerSection]}>
        <Text style={[styles.sectionTitle, styles.dangerSectionTitle]}>Danger Zone</Text>
        {isGuest ? (
          /* Guest: Clear Local Data */
          <TouchableOpacity
            style={styles.dangerButton}
            onPress={handleClearLocalData}
            activeOpacity={0.7}
            testID="clear-local-data-button"
          >
            <Text style={styles.dangerButtonText}>Clear Local Data</Text>
          </TouchableOpacity>
        ) : (
          /* Authenticated: Delete Account */
          <TouchableOpacity
            style={styles.dangerButton}
            onPress={handleOpenDeleteModal}
            activeOpacity={0.7}
            testID="delete-account-button"
          >
            <Text style={styles.dangerButtonText}>Delete Account</Text>
          </TouchableOpacity>
        )}
      </View>

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

      {/* Reminder time picker modal */}
      <Modal
        visible={showTimePicker}
        transparent
        animationType="slide"
        onRequestClose={() => setShowTimePicker(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowTimePicker(false)}
        >
          <View style={styles.pickerSheet}>
            <Text style={styles.pickerTitle}>Reminder Time</Text>
            <View style={styles.timePickerTabs}>
              <TouchableOpacity
                style={[styles.timePickerTab, timePickerMode === 'hour' && styles.timePickerTabActive]}
                onPress={() => setTimePickerMode('hour')}
                activeOpacity={0.7}
                testID="time-picker-hour-tab"
              >
                <Text style={[styles.timePickerTabText, timePickerMode === 'hour' && styles.timePickerTabTextActive]}>
                  Hour
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.timePickerTab, timePickerMode === 'minute' && styles.timePickerTabActive]}
                onPress={() => setTimePickerMode('minute')}
                activeOpacity={0.7}
                testID="time-picker-minute-tab"
              >
                <Text style={[styles.timePickerTabText, timePickerMode === 'minute' && styles.timePickerTabTextActive]}>
                  Minute
                </Text>
              </TouchableOpacity>
            </View>
            {timePickerMode === 'hour' ? (
              HOUR_OPTIONS.map((h) => {
                const period = h < 12 ? 'AM' : 'PM';
                const displayHour = h === 0 ? 12 : h > 12 ? h - 12 : h;
                const label = `${displayHour} ${period}`;
                const isSelected = (settings.reminderHour ?? DEFAULT_SETTINGS.reminderHour) === h;
                return (
                  <TouchableOpacity
                    key={h}
                    style={[styles.pickerOption, isSelected && styles.pickerOptionSelected]}
                    onPress={() => {
                      setSettings((prev) => ({ ...prev, reminderHour: h }));
                      setTimePickerMode('minute');
                    }}
                    activeOpacity={0.7}
                    testID={`time-picker-hour-${h}`}
                  >
                    <Text style={[styles.pickerOptionText, isSelected && styles.pickerOptionTextSelected]}>
                      {label}
                    </Text>
                    {isSelected && <Text style={styles.pickerCheckmark}>✓</Text>}
                  </TouchableOpacity>
                );
              })
            ) : (
              MINUTE_OPTIONS.map((m) => {
                const label = m.toString().padStart(2, '0');
                const isSelected = (settings.reminderMinute ?? DEFAULT_SETTINGS.reminderMinute) === m;
                return (
                  <TouchableOpacity
                    key={m}
                    style={[styles.pickerOption, isSelected && styles.pickerOptionSelected]}
                    onPress={() => void handleSelectReminderTime(settings.reminderHour ?? DEFAULT_SETTINGS.reminderHour, m)}
                    activeOpacity={0.7}
                    testID={`time-picker-minute-${m}`}
                  >
                    <Text style={[styles.pickerOptionText, isSelected && styles.pickerOptionTextSelected]}>
                      :{label}
                    </Text>
                    {isSelected && <Text style={styles.pickerCheckmark}>✓</Text>}
                  </TouchableOpacity>
                );
              })
            )}
          </View>
        </TouchableOpacity>
      </Modal>

      {/* Export format picker modal */}
      <Modal
        visible={showExportPicker}
        transparent
        animationType="slide"
        onRequestClose={() => setShowExportPicker(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowExportPicker(false)}
        >
          <View style={styles.pickerSheet}>
            <Text style={styles.pickerTitle}>Export Format</Text>
            <TouchableOpacity
              style={styles.pickerOption}
              onPress={() => void handleExportData('csv')}
              activeOpacity={0.7}
              testID="export-csv-option"
            >
              <View>
                <Text style={styles.pickerOptionText}>Export as CSV (zip)</Text>
                <Text style={styles.pickerOptionHint}>
                  7 CSV files: workouts, maxes, benchmarks, and more
                </Text>
              </View>
              <Text style={styles.chevron}>›</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.pickerOption}
              onPress={() => void handleExportData('json')}
              activeOpacity={0.7}
              testID="export-json-option"
            >
              <View>
                <Text style={styles.pickerOptionText}>Export as JSON</Text>
                <Text style={styles.pickerOptionHint}>
                  Single file with all your data
                </Text>
              </View>
              <Text style={styles.chevron}>›</Text>
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </Modal>

      {/* Delete Account confirmation modal */}
      <Modal
        visible={showDeleteModal}
        transparent
        animationType="slide"
        onRequestClose={handleCancelDelete}
      >
        <View style={styles.deleteModalOverlay}>
          <View style={styles.deleteModalSheet}>
            <Text style={styles.deleteModalTitle}>Delete Your Account?</Text>
            <Text style={styles.deleteModalBody}>
              This will permanently delete all your data, cancel any active subscriptions, and remove your account.
            </Text>

            {/* Export data suggestion */}
            <TouchableOpacity
              style={styles.deleteExportLink}
              onPress={() => {
                setShowDeleteModal(false);
                setShowExportPicker(true);
              }}
              activeOpacity={0.7}
              testID="delete-modal-export-link"
            >
              <Text style={styles.deleteExportLinkText}>
                Want to save your data first? Export it here.
              </Text>
            </TouchableOpacity>

            {/* Type DELETE confirmation */}
            <Text style={styles.deleteConfirmLabel}>Type DELETE to confirm</Text>
            <TextInput
              style={styles.deleteConfirmInput}
              value={deleteConfirmText}
              onChangeText={setDeleteConfirmText}
              placeholder="DELETE"
              placeholderTextColor={colors.GREY}
              autoCapitalize="characters"
              autoCorrect={false}
              testID="delete-confirm-input"
            />

            {/* Action buttons */}
            <View style={styles.deleteModalButtons}>
              <TouchableOpacity
                style={styles.deleteCancelButton}
                onPress={handleCancelDelete}
                activeOpacity={0.7}
                testID="delete-cancel-button"
              >
                <Text style={styles.deleteCancelText}>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.deleteConfirmButton,
                  !isDeleteConfirmed && styles.deleteConfirmButtonDisabled,
                ]}
                onPress={() => void handleConfirmDeleteAccount()}
                activeOpacity={0.7}
                disabled={!isDeleteConfirmed || isDeleting}
                testID="delete-confirm-button"
              >
                <Text style={styles.deleteConfirmText}>
                  {isDeleting ? 'Deleting…' : 'Delete Account'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
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
    marginBottom: 24,
  },
  signOutText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.RED,
    letterSpacing: 0.5,
  },
  // Danger Zone section
  dangerSection: {
    backgroundColor: '#FFF5F5',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FFCCCC',
    padding: 16,
    marginBottom: 8,
  },
  dangerSectionTitle: {
    color: colors.RED,
  },
  dangerButton: {
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: colors.RED,
    backgroundColor: '#FFF5F5',
  },
  dangerButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.RED,
    letterSpacing: 0.3,
  },
  // Notifications section
  permissionBanner: {
    backgroundColor: '#FFF3CD',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
    gap: 6,
  },
  permissionBannerText: {
    fontSize: 13,
    color: '#856404',
    lineHeight: 18,
  },
  permissionBannerLink: {
    fontSize: 13,
    fontWeight: '700',
    color: '#533F03',
    textDecorationLine: 'underline',
  },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    paddingVertical: 12,
    paddingHorizontal: 14,
    marginBottom: 8,
  },
  toggleRowDisabled: {
    opacity: 0.5,
  },
  toggleLabelDisabled: {
    color: colors.GREY,
  },
  reminderTimeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    paddingVertical: 12,
    paddingHorizontal: 14,
    marginBottom: 8,
    marginLeft: 16,
  },
  // Time picker tabs
  timePickerTabs: {
    flexDirection: 'row',
    marginBottom: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    overflow: 'hidden',
  },
  timePickerTab: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    backgroundColor: colors.CREAM_LIGHT,
  },
  timePickerTabActive: {
    backgroundColor: colors.ORANGE,
  },
  timePickerTabText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.NAVY,
  },
  timePickerTabTextActive: {
    color: colors.CREAM,
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
  pickerOptionHint: {
    fontSize: 11,
    color: colors.GREY,
    marginTop: 2,
  },
  pickerCheckmark: {
    fontSize: 16,
    color: colors.ORANGE,
    fontWeight: '700',
  },
  // Delete Account modal
  deleteModalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  deleteModalSheet: {
    backgroundColor: colors.CREAM,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingHorizontal: 24,
    paddingTop: 24,
    paddingBottom: 40,
    gap: 16,
  },
  deleteModalTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.NAVY,
    textAlign: 'center',
  },
  deleteModalBody: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    lineHeight: 20,
    textAlign: 'center',
  },
  deleteExportLink: {
    alignItems: 'center',
    paddingVertical: 4,
  },
  deleteExportLinkText: {
    fontSize: 13,
    color: colors.ORANGE,
    fontWeight: '600',
    textDecorationLine: 'underline',
  },
  deleteConfirmLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.NAVY,
  },
  deleteConfirmInput: {
    borderWidth: 1.5,
    borderColor: colors.GREY_LIGHT,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    color: colors.NAVY,
    backgroundColor: colors.CREAM_LIGHT,
    letterSpacing: 2,
  },
  deleteModalButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  deleteCancelButton: {
    flex: 1,
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    backgroundColor: colors.CREAM_LIGHT,
  },
  deleteCancelText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.GREY,
  },
  deleteConfirmButton: {
    flex: 1,
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 8,
    backgroundColor: colors.RED,
  },
  deleteConfirmButtonDisabled: {
    opacity: 0.4,
  },
  deleteConfirmText: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.CREAM,
  },
});
