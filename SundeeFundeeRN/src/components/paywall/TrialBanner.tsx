/**
 * TrialBanner — subtle dismissable countdown banner for trial users.
 *
 * Renders only when:
 * - Platform is mobile (not web — web trial tracking needs Firestore field)
 * - User is on a TRIAL period type in RevenueCat
 * - Trial has <= 2 days remaining (covers days 6-7 of a 7-day trial)
 * - User has not previously dismissed it (AsyncStorage key: trialBannerDismissed)
 *
 * Art Deco styling: ORANGE_LIGHT background, NAVY text, ORANGE CTA.
 */
import React, { useEffect, useState } from 'react';
import {
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as colors from '@/src/theme/colors';

const DISMISSED_KEY = 'trialBannerDismissed';
const MAX_DAYS_TO_SHOW = 2;

interface TrialBannerProps {
  /** Called when user taps the Subscribe button */
  onSubscribe: () => void;
}

/**
 * Subtle banner shown during the final days of a free trial.
 * Renders null when not applicable — safe to include unconditionally in layouts.
 */
export function TrialBanner({ onSubscribe }: TrialBannerProps): React.JSX.Element | null {
  const [daysRemaining, setDaysRemaining] = useState<number | null>(null);
  const [dismissed, setDismissed] = useState(false);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    void checkTrialStatus();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function checkTrialStatus(): Promise<void> {
    // Web: do not render — trial tracking would need Firestore
    if (Platform.OS === 'web') {
      setChecked(true);
      return;
    }

    try {
      // Check if previously dismissed
      const wasDismissed = await AsyncStorage.getItem(DISMISSED_KEY);
      if (wasDismissed === 'true') {
        setDismissed(true);
        setChecked(true);
        return;
      }

      // Check RevenueCat trial status
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Purchases = require('react-native-purchases').default;
      const customerInfo = await Purchases.getCustomerInfo();
      const premiumEntitlement = customerInfo?.entitlements?.active?.premium;

      if (premiumEntitlement?.periodType === 'TRIAL' && premiumEntitlement?.expirationDate) {
        const expiryMs = new Date(premiumEntitlement.expirationDate).getTime();
        const nowMs = Date.now();
        const msRemaining = expiryMs - nowMs;
        const days = Math.ceil(msRemaining / (1000 * 60 * 60 * 24));

        if (days >= 0 && days <= MAX_DAYS_TO_SHOW) {
          setDaysRemaining(days);
        }
      }
    } catch {
      // RevenueCat unavailable — don't show banner
    } finally {
      setChecked(true);
    }
  }

  async function handleDismiss(): Promise<void> {
    try {
      await AsyncStorage.setItem(DISMISSED_KEY, 'true');
    } catch {
      // Non-critical — still dismiss locally
    }
    setDismissed(true);
  }

  // Only render after async check completes, if we have valid trial state
  if (!checked || dismissed || daysRemaining === null || Platform.OS === 'web') {
    return null;
  }

  const dayLabel = daysRemaining === 1 ? 'day' : 'days';

  return (
    <View style={styles.banner} testID="trial-banner">
      <View style={styles.content}>
        <Text style={styles.text}>
          Your trial ends in <Text style={styles.emphasis}>{daysRemaining} {dayLabel}</Text>.{' '}
          Subscribe to keep premium features.
        </Text>
        <Pressable
          style={styles.subscribeButton}
          onPress={onSubscribe}
          testID="trial-banner-subscribe"
        >
          <Text style={styles.subscribeText}>Subscribe</Text>
        </Pressable>
      </View>
      <Pressable
        style={styles.dismissButton}
        onPress={() => void handleDismiss()}
        testID="trial-banner-dismiss"
        accessibilityLabel="Dismiss trial banner"
      >
        <Text style={styles.dismissText}>✕</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    paddingVertical: 10,
    paddingHorizontal: 14,
    gap: 8,
  },
  content: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 8,
  },
  text: {
    flex: 1,
    fontSize: 13,
    color: colors.NAVY,
    lineHeight: 18,
  },
  emphasis: {
    fontWeight: '700',
    color: colors.NAVY,
  },
  subscribeButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  subscribeText: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.3,
  },
  dismissButton: {
    padding: 4,
  },
  dismissText: {
    fontSize: 12,
    color: colors.GREY,
    fontWeight: '600',
  },
});
