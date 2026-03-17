/**
 * app/(app)/goodbye.tsx — Post-account-deletion farewell screen.
 *
 * Shown after a user successfully deletes their account.
 * Art Deco styling: cream background, navy text, orange accent button.
 * "Done" button navigates to sign-in, replacing the stack so the user
 * cannot navigate back into authenticated routes.
 */

import React from 'react';
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import * as colors from '@/src/theme/colors';

export default function GoodbyeScreen(): React.JSX.Element {
  const router = useRouter();

  function handleDone(): void {
    router.replace('/sign-in');
  }

  return (
    <View style={styles.container} testID="goodbye-screen">
      <View style={styles.content}>
        <Text style={styles.heading}>Account Deleted</Text>
        <Text style={styles.subtext}>
          Your data has been removed. Thank you for using Sundee Fundee.
        </Text>
      </View>

      <TouchableOpacity
        style={styles.doneButton}
        onPress={handleDone}
        activeOpacity={0.8}
        testID="goodbye-done-button"
      >
        <Text style={styles.doneButtonText}>Done</Text>
      </TouchableOpacity>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
    paddingHorizontal: 32,
    paddingVertical: 60,
    justifyContent: 'center',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  heading: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.5,
    textAlign: 'center',
    marginBottom: 20,
  },
  subtext: {
    fontSize: 15,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
    lineHeight: 22,
    maxWidth: 300,
  },
  doneButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 10,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 16,
  },
  doneButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
});
