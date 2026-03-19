/**
 * useNotificationPermission — hook for reading and refreshing OS notification permission status.
 *
 * Checks permission on mount.
 * Exposes checkPermission() for consumers to re-check (e.g., via useFocusEffect after
 * the user returns from Settings).
 *
 * Returns:
 *   - status:        'granted' | 'denied' | 'undetermined'
 *   - isGranted:     true when status === 'granted'
 *   - isDenied:      true when status === 'denied'
 *   - checkPermission: async function to re-read permission from OS
 */

import { useState, useEffect, useCallback } from 'react';
import * as Notifications from 'expo-notifications';

// ─── Types ────────────────────────────────────────────────────────────────────

export type NotificationPermissionStatus = 'granted' | 'denied' | 'undetermined';

export interface UseNotificationPermissionReturn {
  status: NotificationPermissionStatus;
  isGranted: boolean;
  isDenied: boolean;
  checkPermission: () => Promise<void>;
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

export function useNotificationPermission(): UseNotificationPermissionReturn {
  const [status, setStatus] = useState<NotificationPermissionStatus>('undetermined');

  const checkPermission = useCallback(async (): Promise<void> => {
    try {
      const { status: permStatus } = await Notifications.getPermissionsAsync();
      if (permStatus === 'granted' || permStatus === 'denied') {
        setStatus(permStatus);
      } else {
        setStatus('undetermined');
      }
    } catch {
      // Permission check failed — leave status as undetermined
    }
  }, []);

  useEffect(() => {
    void checkPermission();
  }, [checkPermission]);

  return {
    status,
    isGranted: status === 'granted',
    isDenied: status === 'denied',
    checkPermission,
  };
}
