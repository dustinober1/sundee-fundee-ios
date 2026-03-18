/**
 * PaywallModal — full-screen paywall with premium feature list and purchase flow.
 *
 * - Mobile (iOS/Android): fetches RevenueCat offerings, purchases via purchasePackage
 * - Web: shows Stripe pricing, calls createCheckoutSession Cloud Function
 * - Guest users: shows "Create Account to Subscribe" CTA
 *
 * Annual plan is pre-selected with "Best Value" badge per UX decision.
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  Modal,
  View,
  Text,
  Pressable,
  ScrollView,
  StyleSheet,
  Platform,
  ActivityIndicator,
  Linking,
} from 'react-native';
import { router } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { logEvent } from '@/src/firebase/analytics';
import {
  CREAM,
  CREAM_LIGHT,
  NAVY,
  NAVY_DARK,
  ORANGE,
  ORANGE_DARK,
  ORANGE_LIGHT,
  GREY,
  GREY_LIGHT,
} from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

interface RCPackage {
  identifier: string;
  packageType: string;
  product: {
    identifier: string;
    priceString: string;
    price: number;
  };
}

interface RCOfferings {
  current: {
    availablePackages: RCPackage[];
    monthly: RCPackage | null;
    annual: RCPackage | null;
  } | null;
}

export interface PaywallModalProps {
  visible: boolean;
  onDismiss: () => void;
  onSubscribed: () => void;
}

// ─── Feature list ─────────────────────────────────────────────────────────────

const PREMIUM_FEATURES = [
  {
    icon: '🤖',
    title: 'AI Workouts',
    description: 'Personalized AI-generated workouts',
  },
  {
    icon: '🌙',
    title: 'Cycle Adaptation',
    description: 'Auto-adjust training to your cycle',
  },
  {
    icon: '📋',
    title: 'Programs',
    description: 'Access the full program catalog',
  },
  {
    icon: '🩹',
    title: 'Injury Adaptation',
    description: 'Smart exercise substitutions',
  },
] as const;

// ─── Fallback pricing ─────────────────────────────────────────────────────────

const FALLBACK_MOBILE_MONTHLY = '$9.99/mo';
const FALLBACK_MOBILE_ANNUAL = '$59.99/yr';
const WEB_MONTHLY = '$7.99/mo';
const WEB_ANNUAL = '$47.99/yr';

// ─── Component ────────────────────────────────────────────────────────────────

export function PaywallModal({
  visible,
  onDismiss,
  onSubscribed,
}: PaywallModalProps): React.JSX.Element {
  const { user, isGuest } = useSession();

  const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'annual'>('annual');
  const [offerings, setOfferings] = useState<RCOfferings | null>(null);
  const [isPurchasing, setIsPurchasing] = useState(false);
  const [purchaseError, setPurchaseError] = useState<string | null>(null);

  // ── Fetch RevenueCat offerings on mobile ─────────────────────────────────

  useEffect(() => {
    if (!visible || Platform.OS === 'web') return;

    async function fetchOfferings(): Promise<void> {
      try {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const Purchases = require('react-native-purchases').default;
        const result = await Purchases.getOfferings();
        setOfferings(result);
      } catch {
        // Gracefully degrade to fallback pricing
        setOfferings(null);
      }
    }

    void fetchOfferings();
  }, [visible]);

  // ── Derive display prices ──────────────────────────────────────────────────

  const monthlyPrice =
    Platform.OS === 'web'
      ? WEB_MONTHLY
      : (offerings?.current?.monthly?.product?.priceString ?? FALLBACK_MOBILE_MONTHLY);

  const annualPrice =
    Platform.OS === 'web'
      ? WEB_ANNUAL
      : (offerings?.current?.annual?.product?.priceString ?? FALLBACK_MOBILE_ANNUAL);

  // ── Purchase handlers ──────────────────────────────────────────────────────

  const handleMobilePurchase = useCallback(async (): Promise<void> => {
    setPurchaseError(null);
    setIsPurchasing(true);

    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const Purchases = require('react-native-purchases').default;

      // Pick the selected package from offerings
      const pkg =
        selectedPlan === 'annual'
          ? (offerings?.current?.annual ?? offerings?.current?.availablePackages?.[0] ?? null)
          : (offerings?.current?.monthly ?? offerings?.current?.availablePackages?.[0] ?? null);

      if (!pkg) {
        // No package available — try purchaseProduct with fallback identifiers
        const productId =
          selectedPlan === 'annual'
            ? 'com.sundeefundee.premium.annual'
            : 'com.sundeefundee.premium.monthly';
        await Purchases.purchaseProduct(productId);
        void logEvent('subscription_started', { source: 'paywall' });
        onSubscribed();
        return;
      }

      const { customerInfo } = await Purchases.purchasePackage(pkg);
      const activeEntitlements = customerInfo?.entitlements?.active ?? {};

      if ('premium' in activeEntitlements) {
        void logEvent('subscription_started', { source: 'paywall' });
        onSubscribed();
      }
    } catch (error: unknown) {
      const rcError = error as { userCancelled?: boolean; message?: string };
      if (rcError?.userCancelled) {
        // User dismissed the native purchase sheet — not an error
        return;
      }
      setPurchaseError(rcError?.message ?? 'Purchase failed. Please try again.');
    } finally {
      setIsPurchasing(false);
    }
  }, [selectedPlan, offerings, onSubscribed]);

  const handleWebCheckout = useCallback(async (): Promise<void> => {
    setPurchaseError(null);
    setIsPurchasing(true);

    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const { getFunctions, httpsCallable } = require('firebase/functions');
      const functions = getFunctions();
      const createCheckoutSession = httpsCallable(functions, 'createCheckoutSession');

      const successUrl = 'https://sundeefundee.com/subscription/success';
      const cancelUrl =
        typeof window !== 'undefined' ? window.location.href : 'https://sundeefundee.com';

      const result = await createCheckoutSession({
        plan: selectedPlan,
        successUrl,
        cancelUrl,
      });

      const { url } = result.data as { url: string };

      if (typeof window !== 'undefined') {
        window.open(url, '_blank');
      } else {
        await Linking.openURL(url);
      }
    } catch (error: unknown) {
      const err = error as { message?: string };
      setPurchaseError(err?.message ?? 'Could not start checkout. Please try again.');
    } finally {
      setIsPurchasing(false);
    }
  }, [selectedPlan]);

  const handleSubscribeTap = useCallback(async (): Promise<void> => {
    if (isGuest) {
      router.push('/sign-in');
      return;
    }

    if (Platform.OS === 'web') {
      await handleWebCheckout();
    } else {
      await handleMobilePurchase();
    }
  }, [isGuest, handleMobilePurchase, handleWebCheckout]);

  // ── CTA label ──────────────────────────────────────────────────────────────

  const ctaLabel = isGuest
    ? 'Create Account to Subscribe'
    : 'Start 7-Day Free Trial';

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={onDismiss}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          {/* Header */}
          <View style={styles.header}>
            <Text style={styles.headerTitle}>Unlock Premium</Text>
            <Pressable
              testID="paywall-close-btn"
              style={styles.closeBtn}
              onPress={onDismiss}
              accessibilityLabel="Close paywall"
            >
              <Text style={styles.closeBtnText}>✕</Text>
            </Pressable>
          </View>

          <ScrollView
            style={styles.scrollView}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
          >
            {/* Feature list */}
            <View style={styles.featuresSection}>
              <Text style={styles.sectionTitle}>Everything you need</Text>
              {PREMIUM_FEATURES.map((feature) => (
                <View key={feature.title} style={styles.featureRow}>
                  <Text style={styles.featureIcon}>{feature.icon}</Text>
                  <View style={styles.featureText}>
                    <Text style={styles.featureTitle}>{feature.title}</Text>
                    <Text style={styles.featureDescription}>{feature.description}</Text>
                  </View>
                </View>
              ))}
            </View>

            {/* Pricing cards */}
            <View style={styles.pricingSection}>
              <Text style={styles.sectionTitle}>Choose your plan</Text>

              {/* Annual card — pre-selected */}
              <Pressable
                style={[
                  styles.planCard,
                  selectedPlan === 'annual' && styles.planCardSelected,
                ]}
                onPress={() => setSelectedPlan('annual')}
                accessibilityLabel="Annual plan"
              >
                <View style={styles.planCardBadgeRow}>
                  <Text style={styles.planName}>Annual</Text>
                  <View style={styles.bestValueBadge}>
                    <Text style={styles.bestValueText}>Best Value - Save 50%</Text>
                  </View>
                </View>
                <Text style={styles.planPrice}>{annualPrice}</Text>
              </Pressable>

              {/* Monthly card */}
              <Pressable
                style={[
                  styles.planCard,
                  styles.planCardSecondary,
                  selectedPlan === 'monthly' && styles.planCardSelected,
                ]}
                onPress={() => setSelectedPlan('monthly')}
                accessibilityLabel="Monthly plan"
              >
                <Text style={styles.planName}>Monthly</Text>
                <Text style={[styles.planPrice, styles.planPriceSecondary]}>
                  {monthlyPrice}
                </Text>
              </Pressable>
            </View>

            {/* Error message */}
            {purchaseError && (
              <Text style={styles.errorText}>{purchaseError}</Text>
            )}

            {/* CTA */}
            <Pressable
              testID="paywall-subscribe-btn"
              style={[styles.ctaBtn, isPurchasing && styles.ctaBtnDisabled]}
              onPress={handleSubscribeTap}
              disabled={isPurchasing}
              accessibilityLabel={ctaLabel}
            >
              {isPurchasing ? (
                <ActivityIndicator color={CREAM} />
              ) : (
                <Text style={styles.ctaBtnText}>{ctaLabel}</Text>
              )}
            </Pressable>

            {/* Fine print */}
            {!isGuest && (
              <Text style={styles.finePrint}>
                {Platform.OS === 'web'
                  ? 'Cancel anytime. Billed via Stripe.'
                  : 'Free trial, then auto-renews. Cancel anytime in App Store settings.'}
              </Text>
            )}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(13, 26, 64, 0.7)', // NAVY at 70% opacity
    justifyContent: 'flex-end',
  },
  container: {
    backgroundColor: CREAM,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '90%',
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: NAVY_DARK,
    paddingHorizontal: 20,
    paddingVertical: 18,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: CREAM,
    letterSpacing: 0.5,
  },
  closeBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(244, 240, 223, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeBtnText: {
    fontSize: 14,
    color: CREAM,
    fontWeight: '600',
  },
  scrollView: {
    flexGrow: 0,
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 32,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: GREY,
    letterSpacing: 0.8,
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  featuresSection: {
    marginBottom: 24,
  },
  featureRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 14,
    gap: 12,
  },
  featureIcon: {
    fontSize: 20,
    width: 28,
    textAlign: 'center',
  },
  featureText: {
    flex: 1,
  },
  featureTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: NAVY,
    marginBottom: 2,
  },
  featureDescription: {
    fontSize: 13,
    color: GREY,
  },
  pricingSection: {
    marginBottom: 20,
  },
  planCard: {
    backgroundColor: CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: ORANGE,
    padding: 16,
    marginBottom: 10,
  },
  planCardSelected: {
    borderColor: ORANGE,
    backgroundColor: ORANGE_LIGHT,
  },
  planCardSecondary: {
    borderColor: GREY_LIGHT,
  },
  planCardBadgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  planName: {
    fontSize: 16,
    fontWeight: '700',
    color: NAVY,
  },
  bestValueBadge: {
    backgroundColor: ORANGE,
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  bestValueText: {
    fontSize: 11,
    fontWeight: '700',
    color: CREAM,
    letterSpacing: 0.2,
  },
  planPrice: {
    fontSize: 18,
    fontWeight: '700',
    color: NAVY,
  },
  planPriceSecondary: {
    fontSize: 16,
    color: GREY,
  },
  errorText: {
    fontSize: 13,
    color: '#C0392B',
    textAlign: 'center',
    marginBottom: 12,
  },
  ctaBtn: {
    backgroundColor: ORANGE,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 4,
  },
  ctaBtnDisabled: {
    backgroundColor: ORANGE_DARK,
    opacity: 0.7,
  },
  ctaBtnText: {
    fontSize: 16,
    fontWeight: '700',
    color: CREAM,
    letterSpacing: 0.3,
  },
  finePrint: {
    fontSize: 11,
    color: GREY,
    textAlign: 'center',
    marginTop: 12,
  },
});
