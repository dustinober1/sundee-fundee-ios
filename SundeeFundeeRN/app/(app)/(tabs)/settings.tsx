/**
 * app/(app)/(tabs)/settings.tsx — Settings screen.
 *
 * Per locked design decisions:
 * - "Create Account" button visible ONLY for guest users
 * - Sign-out requires confirmation dialog (Alert.alert)
 * - After sign-out: onAuthStateChanged triggers automatic redirect to /sign-in
 */

import React from 'react';
import { Alert, Platform, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import * as colors from '@/src/theme/colors';

export default function SettingsScreen(): React.JSX.Element {
  const { user, isGuest, signOut } = useSession();
  const router = useRouter();

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
    <View style={styles.container}>
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

      {/* App info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Version</Text>
          <Text style={styles.infoValue}>1.0.0 (Phase 1)</Text>
        </View>
      </View>

      {/* Spacer to push sign-out to bottom */}
      <View style={styles.spacer} />

      {/* Sign out (per locked decision: always at bottom with confirmation) */}
      <TouchableOpacity
        style={styles.signOutButton}
        onPress={handleSignOut}
        activeOpacity={0.7}
        testID="sign-out-button"
      >
        <Text style={styles.signOutText}>Sign Out</Text>
      </TouchableOpacity>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
    paddingHorizontal: 24,
    paddingTop: 24,
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
  spacer: {
    flex: 1,
  },
  signOutButton: {
    width: '100%',
    height: 52,
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: colors.RED,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
  },
  signOutText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.RED,
    letterSpacing: 0.5,
  },
});
