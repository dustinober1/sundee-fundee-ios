/**
 * app/(app)/(tabs)/index.tsx — Dashboard placeholder.
 *
 * Phase 1: Shows welcome message with user's name or "Guest".
 * Full training dashboard built in later phases.
 *
 * Guest users see a contextual upgrade nudge per locked decision:
 * "Create Account option always visible in settings, plus contextual nudges elsewhere"
 */

import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import * as colors from '@/src/theme/colors';

export default function DashboardScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const router = useRouter();

  const displayName = isGuest
    ? 'Guest'
    : (user?.displayName ?? user?.email ?? 'Athlete');

  return (
    <View style={styles.container}>
      {/* Welcome */}
      <View style={styles.welcomeSection}>
        <Text style={styles.greeting}>Welcome back,</Text>
        <Text style={styles.displayName}>{displayName}</Text>
        {!isGuest && user?.email != null && (
          <Text style={styles.email}>{user.email}</Text>
        )}
      </View>

      {/* Training dashboard placeholder */}
      <View style={styles.placeholderCard}>
        <Text style={styles.placeholderText}>
          Your training dashboard will appear here
        </Text>
        <Text style={styles.placeholderSubtext}>
          Program selection, today's workout, and cycle-aware recommendations
          are coming in Phase 3.
        </Text>
      </View>

      {/* Guest upgrade nudge (per locked decision) */}
      {isGuest && (
        <View style={styles.upgradeNudge}>
          <Text style={styles.nudgeTitle}>Save Your Progress</Text>
          <Text style={styles.nudgeBody}>
            Create an account to sync your data across devices and never lose
            your training history.
          </Text>
          <TouchableOpacity
            style={styles.nudgeButton}
            onPress={() => router.push('/sign-in')}
            activeOpacity={0.8}
            testID="create-account-nudge"
          >
            <Text style={styles.nudgeButtonText}>Create Account</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
    paddingHorizontal: 24,
    paddingTop: 32,
  },
  welcomeSection: {
    marginBottom: 32,
  },
  greeting: {
    fontSize: 16,
    color: colors.NAVY_MEDIUM,
    marginBottom: 4,
  },
  displayName: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.5,
    marginBottom: 4,
  },
  email: {
    fontSize: 13,
    color: colors.GREY,
    marginTop: 2,
  },
  placeholderCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 24,
    alignItems: 'center',
    marginBottom: 24,
  },
  placeholderText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.NAVY,
    textAlign: 'center',
    marginBottom: 8,
  },
  placeholderSubtext: {
    fontSize: 13,
    color: colors.GREY,
    textAlign: 'center',
    lineHeight: 18,
  },
  upgradeNudge: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.ORANGE,
    padding: 20,
  },
  nudgeTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 8,
  },
  nudgeBody: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
    marginBottom: 16,
  },
  nudgeButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
  },
  nudgeButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
});
