/**
 * OfflineBanner — Connectivity indicator.
 *
 * Uses expo-network to detect online/offline state.
 * When offline: renders a subtle banner at the top of the screen.
 * When online: renders nothing.
 *
 * Per locked design decision: not alarming — subtle, informational only.
 */

import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import * as Network from 'expo-network';
import * as colors from '@/src/theme/colors';

// ─── OfflineBanner ────────────────────────────────────────────────────────────

export function OfflineBanner(): React.JSX.Element | null {
  const [isOffline, setIsOffline] = useState(false);

  useEffect(() => {
    let isMounted = true;

    // Check initial network state
    void Network.getNetworkStateAsync().then((state) => {
      if (isMounted) {
        setIsOffline(state.isConnected === false || state.isInternetReachable === false);
      }
    });

    return () => {
      isMounted = false;
    };
  }, []);

  if (!isOffline) {
    return null;
  }

  return (
    <View style={styles.banner} testID="offline-banner">
      <Text style={styles.text}>
        You're offline. Sign in requires a connection.
      </Text>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  banner: {
    width: '100%',
    paddingVertical: 6,
    paddingHorizontal: 16,
    backgroundColor: colors.GREY_LIGHT,
    alignItems: 'center',
  },
  text: {
    fontSize: 12,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
  },
});
