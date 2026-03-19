# Phase 20: Notification Infrastructure - Research

**Researched:** 2026-03-18
**Domain:** expo-notifications (local), @react-native-firebase/messaging (FCM token), AppSettings extension, cycle-phase copy
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Permission Prompt Timing**
- Show permission prompt after the user completes their first workout — not during onboarding or cold launch
- Custom Art Deco styled modal before the OS dialog: explains rest timer alerts, workout reminders, WOD drops
- Two buttons: "Enable" (fires OS dialog) / "Not now" (dismisses, no re-prompt)
- Never re-prompt automatically after dismissal — user can enable from Settings at any time
- Guest users see the same permission flow as authenticated users (local notifications work without an account)
- Current useRestTimer eagerly requests permission on first rest start — refactor to remove that; permission only through the post-first-workout modal

**Notification Preferences UI**
- New "Notifications" section in Settings screen (between Rest Timer and Subscription sections)
- Four independent on/off toggles matching NOTIF-06: Rest Timer Alerts, Workout Reminders, WOD Alerts, Subscription Alerts
- Persist in AppSettings (merged into Firestore /users/{uid} for authenticated, AsyncStorage for guests) — extend the existing SettingsRepo pattern, replace single `notificationsEnabled` boolean with granular fields
- When OS notification permission is denied: toggles visible but disabled/grayed out, banner says "Notifications are disabled in your device settings" with a button that deep-links to OS settings page

**Rest Timer Notification**
- Keep current copy: title "Rest complete!", body "Time to lift." — no change needed
- Default system notification sound (sound: true) — no custom audio asset
- Tapping the notification deep-links back to the active workout session screen
- Respects the "Rest Timer Alerts" toggle — if disabled, visual countdown still works but no background notification is scheduled

**Daily Reminder + Cycle Copy**
- Simple native time picker in Settings under the Workout Reminders toggle (default 7:00 AM)
- Local notification via expo-notifications repeating trigger — scheduled on-device, works offline, no Cloud Function needed
- Fires every day at the chosen time (not just training days)
- Cycle-phase-aware copy when cycle tracking is enabled: encouraging + informative tone (e.g., "Follicular phase — great day for strength PRs!" / "Luteal phase — listen to your body today.")
- Without cycle tracking: generic motivational copy that rotates through 3–5 variations (e.g., "Time to train!", "Your workout is waiting.")
- Cycle phase data read from local cycle repo at notification schedule time

### Claude's Discretion
- FCM token registration and storage implementation details
- Notification deep-link routing implementation
- Exact cycle-phase copy variations
- How to re-schedule the daily reminder when the user changes their preferred time
- Notification channel configuration on Android
- How to handle the transition from the current eager permission request in useRestTimer to the new deferred flow

### Deferred Ideas (OUT OF SCOPE)
- Remote push for new WOD published — Phase 21 (NOTIF-04, requires Cloud Function)
- Remote push for subscription expiry — Phase 21 (NOTIF-05, requires Cloud Function)
- Rich media notifications — v2 (NOTIF-10)
- A/B testing notification copy via Remote Config — v2 (NOTIF-11)
- Streak notifications — v2 (NOTIF-09)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| NOTIF-01 | User receives local push when rest timer expires while app is backgrounded | useRestTimer already schedules via expo-notifications TIME_INTERVAL trigger; refactor removes eager permission request, adds toggle guard |
| NOTIF-02 | User can grant notification permission via deferred prompt after first workout | First-workout detection via AsyncStorage flag; custom modal before OS requestPermissionsAsync; two call sites to remove (useRestTimer + workout-session.tsx) |
| NOTIF-03 | App registers FCM push token and stores it in Firestore under user document | messaging().getToken() via RNFB, store to /users/{uid} with merge: true; skip on web + guest; token refresh listener |
| NOTIF-06 | User can configure notification preferences per type in Settings | Extend AppSettings with 4 boolean fields + reminderHour/reminderMinute; new "Notifications" section in settings.tsx |
| NOTIF-07 | Workout reminder notifications include cycle-phase-aware copy when cycle tracking enabled | Read CycleSettings from CycleRepo at schedule time; inferCurrentPhase(); branch copy by CyclePhase union type |
| NOTIF-08 | User can schedule daily workout reminder at a preferred time | DailyTriggerInput with hour + minute + repeats: true; persist chosen time in AppSettings; cancel-and-reschedule pattern on time change |
</phase_requirements>

---

## Summary

Phase 20 is entirely local-notifications-first. All six requirements (NOTIF-01, 02, 03, 06, 07, 08) are achievable with expo-notifications ~55.0.12 (already installed, already mocked in `__mocks__/expo-notifications.ts`) plus the existing @react-native-firebase/messaging ^23.8.8 for FCM token retrieval only. No new native modules need to be installed; no new EAS build is required for the core notification work, because both packages are already native-linked from Phase 18.

The main engineering work is: (1) removing two eager permission calls (in `useRestTimer.ts` and `workout-session.tsx`), (2) detecting first-workout completion via an AsyncStorage flag and showing the custom permission modal, (3) extending `AppSettings` with per-type toggle fields and a reminder time, (4) wiring the four toggles in the Settings screen, (5) scheduling/rescheduling the daily reminder with cycle-aware copy, and (6) registering the FCM token after permission is granted and saving it to Firestore.

**Primary recommendation:** Build in this order — AppSettings extension first (unblocks all other work), then permission modal + first-workout detection, then rest timer toggle guard, then FCM token registration, then daily reminder scheduling with cycle copy. Each step is independently testable.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| expo-notifications | ~55.0.12 | Schedule/cancel local notifications, request permission, get device token | Already installed Phase 18; owns all notification display per architecture decision |
| @react-native-firebase/messaging | ^23.8.8 | FCM token retrieval + token refresh listener | Already installed Phase 18; handles background data messages |
| AsyncStorage | (existing) | Persist first-workout-seen flag, guest notification prefs | Already used throughout app for local-first storage |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| expo-notifications (DailyTriggerInput) | ~55.0.12 | Repeating daily reminder at chosen hour:minute | NOTIF-08 daily workout reminder |
| Linking (React Native built-in) | built-in | Deep-link user to OS notification settings | When permission denied, Settings banner button |

### No New Installs Needed
All required libraries are already native-linked. No `expo install` or EAS rebuild is required for this phase.

**Installation:** None required. All packages already in `package.json` and linked in `app.json` plugins.

---

## Architecture Patterns

### Recommended Project Structure Changes
```
src/
├── repositories/
│   ├── SettingsRepo.ts          # Extend AppSettings interface (add 4 toggles + reminderHour/Minute)
│   ├── FirestoreSettingsRepo.ts # No change needed (uses merge: true, new fields auto-included)
│   └── LocalSettingsRepo.ts     # No change needed (serializes full AppSettings to AsyncStorage)
├── hooks/
│   ├── useRestTimer.ts          # Remove eager permission; add restTimerAlerts toggle guard
│   └── useNotificationPermission.ts  # NEW: check permission status, expose to Settings screen
├── services/
│   └── notificationService.ts   # NEW: schedule/cancel daily reminder, register FCM token
├── components/
│   └── notifications/
│       └── NotificationPermissionModal.tsx  # NEW: Art Deco pre-OS-dialog modal
app/
├── (app)/
│   ├── workout-session.tsx       # Remove eager permission; add post-completion modal trigger
│   └── (tabs)/settings.tsx      # Add Notifications section with 4 toggles + time picker
```

### Pattern 1: AppSettings Extension

**What:** Add per-type notification fields and reminder time to AppSettings interface, replacing the single `notificationsEnabled` boolean.
**When to use:** This is Wave 0 work — all other notification code depends on the new fields.

```typescript
// Source: existing SettingsRepo.ts pattern
export interface AppSettings {
  weightUnit: 'lb' | 'kg';
  defaultRestDuration: number;
  // Replace: notificationsEnabled: boolean
  restTimerAlertsEnabled: boolean;
  workoutRemindersEnabled: boolean;
  wodAlertsEnabled: boolean;
  subscriptionAlertsEnabled: boolean;
  reminderHour: number;    // 0–23, default 7
  reminderMinute: number;  // 0–59, default 0
}

export const DEFAULT_SETTINGS: AppSettings = {
  weightUnit: 'lb',
  defaultRestDuration: 90,
  restTimerAlertsEnabled: true,
  workoutRemindersEnabled: false,
  wodAlertsEnabled: true,
  subscriptionAlertsEnabled: true,
  reminderHour: 7,
  reminderMinute: 0,
};
```

**Migration note:** `notificationsEnabled` was a boolean used by nothing in the current UI. Removing it is safe. The Firestore merge: true pattern means old docs missing the new fields will just get DEFAULT_SETTINGS values on first save.

### Pattern 2: First-Workout Detection

**What:** Track whether the user has completed their first workout with an AsyncStorage flag. Post-completion, show the permission modal if permission has never been granted or denied.
**When to use:** In the workout completion handler in `workout-session.tsx`.

```typescript
// Source: project AsyncStorage pattern (consistent with TRIAL_ENDED_MODAL_SHOWN_KEY)
const FIRST_WORKOUT_DONE_KEY = '@sundee/first_workout_done';
const NOTIF_PERMISSION_ASKED_KEY = '@sundee/notif_permission_asked';

// After workout save in handleFinishWorkout:
const firstWorkoutDone = await AsyncStorage.getItem(FIRST_WORKOUT_DONE_KEY);
if (!firstWorkoutDone) {
  await AsyncStorage.setItem(FIRST_WORKOUT_DONE_KEY, 'true');
  // Check if we've asked before
  const alreadyAsked = await AsyncStorage.getItem(NOTIF_PERMISSION_ASKED_KEY);
  if (!alreadyAsked) {
    setShowNotifPermissionModal(true); // triggers Art Deco modal
  }
}
```

### Pattern 3: Deferred Permission Request

**What:** Permission modal shows after first workout. "Enable" fires OS dialog; "Not now" sets the asked flag and closes. Never auto-re-prompt.

```typescript
// Source: expo-notifications API (verified via official docs)
async function handleEnableNotifications(): Promise<void> {
  await AsyncStorage.setItem(NOTIF_PERMISSION_ASKED_KEY, 'true');
  setShowNotifPermissionModal(false);
  const { status } = await Notifications.requestPermissionsAsync();
  if (status === 'granted') {
    // Register FCM token now that we have permission
    void registerFCMToken(uid, isGuest);
  }
}

function handleNotNow(): void {
  void AsyncStorage.setItem(NOTIF_PERMISSION_ASKED_KEY, 'true');
  setShowNotifPermissionModal(false);
  // No re-prompt — user can go to Settings > Notifications manually
}
```

### Pattern 4: FCM Token Registration

**What:** Get FCM token via @react-native-firebase/messaging after permission is granted; save to /users/{uid} with merge: true. Skip on web and guest users.
**When to use:** After requestPermissionsAsync returns 'granted'. Also wire onTokenRefresh listener in app/_layout.tsx after auth resolves.

```typescript
// Source: rnfirebase.io/messaging/usage
async function registerFCMToken(uid: string, isGuest: boolean): Promise<void> {
  if (Platform.OS === 'web') return;
  if (isGuest) return; // no Firestore for guests
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const messaging = require('@react-native-firebase/messaging').default;
    const token = await messaging().getToken();
    if (token) {
      const db = getFirestoreInstance();
      await db.collection('users').doc(uid).set(
        { fcmToken: token, fcmTokenUpdatedAt: new Date().toISOString() },
        { merge: true }
      );
    }
  } catch (err) {
    console.warn('[FCM] Token registration failed:', err);
  }
}

// Token refresh listener — wire in app/_layout.tsx handleUserSignIn
const unsubscribe = messaging().onTokenRefresh(async (token) => {
  if (uid && !isGuest) {
    void registerFCMToken(uid, isGuest);
  }
});
```

### Pattern 5: Daily Reminder with DailyTriggerInput

**What:** Schedule a repeating daily notification at the user's chosen time. Cancel previous before rescheduling.
**When to use:** When user enables Workout Reminders toggle or changes their preferred time.

```typescript
// Source: docs.expo.dev/versions/latest/sdk/notifications/
const DAILY_REMINDER_KEY = '@sundee/daily_reminder_id';

async function scheduleDailyReminder(
  hour: number,
  minute: number,
  cyclePhase: CyclePhase | null
): Promise<void> {
  // Cancel existing reminder first
  const existingId = await AsyncStorage.getItem(DAILY_REMINDER_KEY);
  if (existingId) {
    await Notifications.cancelScheduledNotificationAsync(existingId);
  }

  const body = cyclePhase
    ? getCycleAwareCopy(cyclePhase)
    : getGenericCopy();

  const id = await Notifications.scheduleNotificationAsync({
    content: {
      title: "Time to train",
      body,
      sound: true,
    },
    trigger: {
      type: Notifications.SchedulableTriggerInputTypes.DAILY,
      hour,
      minute,
      repeats: true,
    },
  });
  await AsyncStorage.setItem(DAILY_REMINDER_KEY, id);
}

async function cancelDailyReminder(): Promise<void> {
  const existingId = await AsyncStorage.getItem(DAILY_REMINDER_KEY);
  if (existingId) {
    await Notifications.cancelScheduledNotificationAsync(existingId);
    await AsyncStorage.removeItem(DAILY_REMINDER_KEY);
  }
}
```

**Important:** DailyTriggerInput uses `hour` (0–23) and `minute` (0–59), not a Date object. The `repeats: true` field is required for repeating behavior. On iOS, daily triggers fire reliably without repeats issues. On Android, the notification channel must be configured (see below).

### Pattern 6: Android Notification Channel

**What:** Android 8+ (API 26+) requires a notification channel. Must be created before scheduling any notification. Importance level controls how the notification appears.
**When to use:** In app/(app)/_layout.tsx alongside the existing setNotificationHandler call (module-level).

```typescript
// Source: docs.expo.dev/versions/latest/sdk/notifications/ (setNotificationChannelAsync)
// Already mocked in __mocks__/expo-notifications.ts

if (Platform.OS === 'android') {
  // Rest timer channel — high priority, makes sound
  await Notifications.setNotificationChannelAsync('rest-timer', {
    name: 'Rest Timer',
    importance: Notifications.AndroidImportance.HIGH,
    sound: 'default',
    vibrationPattern: [0, 250, 250, 250],
    lightColor: '#F2731A', // ORANGE theme color
  });

  // Daily reminder channel — default priority
  await Notifications.setNotificationChannelAsync('reminders', {
    name: 'Workout Reminders',
    importance: Notifications.AndroidImportance.DEFAULT,
    sound: 'default',
  });
}
```

To associate a notification with a channel, add `android: { channelId: 'rest-timer' }` to the notification content.

### Pattern 7: Cycle-Phase Copy Selection

**What:** At schedule time, read the current cycle phase from CycleRepo and select copy. This is pure domain logic with no network dependency.
**When to use:** In scheduleDailyReminder() before constructing the notification content.

```typescript
// Source: src/domain/cycle/index.ts (inferCurrentPhase, CyclePhase union type)
// CyclePhase = 'menstrual' | 'follicular' | 'ovulation' | 'luteal'

const CYCLE_COPY: Record<CyclePhase, string> = {
  menstrual:  "Menstrual phase — gentle movement counts. You've got this.",
  follicular: "Follicular phase — great day for strength PRs.",
  ovulation:  "Peak energy today — make it count.",
  luteal:     "Luteal phase — listen to your body. Consistent beats heroic.",
};

const GENERIC_COPY = [
  "Time to train.",
  "Your workout is waiting.",
  "Show up today.",
  "Strength is built one session at a time.",
];

function getCycleAwareCopy(phase: CyclePhase): string {
  return CYCLE_COPY[phase];
}

function getGenericCopy(): string {
  return GENERIC_COPY[Math.floor(Math.random() * GENERIC_COPY.length)];
}
```

**Limitation:** Generic copy rotation is seeded at schedule time, not delivery time. The body is baked into the notification content at scheduling. This is the correct approach for local notifications — you cannot compute dynamic content at delivery time without a server.

**For cycle-aware copy:** Read CycleSettings + PeriodLogs from CycleRepo, call `calculateCycleStatus()` to get the current phase, then select copy. Re-schedule whenever the user updates their cycle data (future enhancement) or when they change their reminder time (Phase 20 scope).

### Anti-Patterns to Avoid

- **Eagerly requesting permission on timer start or app launch:** Removed from useRestTimer and workout-session.tsx. Permission flows only through the post-first-workout modal.
- **Scheduling the daily reminder without canceling the previous one:** Always cancel-and-reschedule using the stored notification ID from AsyncStorage.
- **Using a TIME_INTERVAL trigger for the daily reminder:** DailyTriggerInput is the correct trigger. TIME_INTERVAL does not repeat reliably for long intervals.
- **Calling messaging().getToken() on web:** Guard with `Platform.OS !== 'web'` — RNFB messaging has no web implementation.
- **Storing FCM token for guest users:** Skip entirely for anonymous users — no Firestore doc to write to.
- **Calling messaging().requestPermission() for Android API <33:** On Android, POST_NOTIFICATIONS permission is only required for API 33+. expo-notifications requestPermissionsAsync handles this correctly across platforms.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Daily repeating trigger | Custom setInterval or date-based scheduler | `DailyTriggerInput` in expo-notifications | OS-managed; survives app restart and backgrounding |
| Android notification channels | Manual Android-specific code | `setNotificationChannelAsync` from expo-notifications | Already mocked in `__mocks__/expo-notifications.ts`; handles all channel lifecycle |
| FCM token retrieval | REST call to FCM endpoint | `messaging().getToken()` from RNFB | Handles token rotation, APNs bridge on iOS, background token refresh |
| OS settings deep-link | Platform-specific URL construction | `Linking.openSettings()` | Built-in React Native API; correct URL on all platforms |
| Permission status check | Polling or custom state | `Notifications.getPermissionsAsync()` | Returns current OS status including 'denied' vs 'undetermined' |

**Key insight:** All notification scheduling primitives (timers, channels, daily repeating) must be OS-managed. Custom JS timers do not survive backgrounding or phone lock on iOS.

---

## Common Pitfalls

### Pitfall 1: Duplicate Permission Requests

**What goes wrong:** Both `useRestTimer.ts` (line 99–101) and `workout-session.tsx` (lines 270–279) currently call `requestPermissionsAsync`. After refactoring, if either site is left in place, users will see the OS dialog before their first workout or before the custom Art Deco modal.
**Why it happens:** These were added incrementally in earlier phases before the deferred permission decision was made.
**How to avoid:** Remove BOTH eager permission blocks as the first change in Wave 0. The custom modal becomes the single permission entry point.
**Warning signs:** If `requestPermissionsAsync` appears anywhere except the modal's "Enable" handler — flag it.

### Pitfall 2: Daily Trigger ID Not Persisted

**What goes wrong:** If the daily reminder notification ID is not stored in AsyncStorage, canceling and rescheduling becomes impossible. The app accumulates stale reminders, the user gets duplicate notifications.
**Why it happens:** scheduleNotificationAsync returns a string ID that is only available at schedule time.
**How to avoid:** Always `AsyncStorage.setItem(DAILY_REMINDER_KEY, id)` immediately after scheduling. Always read and cancel before scheduling a new one.
**Warning signs:** Multiple daily reminder notifications delivered to the device.

### Pitfall 3: Android Channel Not Created Before Scheduling

**What goes wrong:** On Android, scheduling a notification without a matching channel causes it to be silently dropped. No error is thrown.
**Why it happens:** Android 8+ (API 26+) requires channels; expo-notifications does not auto-create them for you.
**How to avoid:** Create channels in `app/(app)/_layout.tsx` at module level alongside `setNotificationHandler`. Use `AndroidImportance.HIGH` for rest timer, `AndroidImportance.DEFAULT` for reminders.
**Warning signs:** Notifications work on iOS simulator but fail silently on Android physical device.

### Pitfall 4: DAILY Trigger Requires `repeats: true`

**What goes wrong:** Without `repeats: true` in the DailyTriggerInput, the notification fires once at the next matching hour:minute, then never again.
**Why it happens:** expo-notifications issue #30577 confirms the parameter is not optional even for DailyTriggerInput.
**How to avoid:** Always include `repeats: true` in the trigger object.

### Pitfall 5: FCM Token Unavailable Until Permission Granted (iOS)

**What goes wrong:** On iOS, `messaging().getToken()` may return undefined/null if APNs permission has not been granted, because FCM on iOS requires APNs behind the scenes.
**Why it happens:** FCM uses APNs as the delivery channel on iOS; without APNs permission, there is no token.
**How to avoid:** Call `registerFCMToken()` only after `requestPermissionsAsync` returns `status === 'granted'`. Also wire `onTokenRefresh` so the token is captured if it arrives later.
**Warning signs:** Empty FCM token in Firestore for iOS users despite permission granted.

### Pitfall 6: Settings Toggle Shows Stale OS Permission Status

**What goes wrong:** User denies OS notification permission, later re-enables it in device settings. The Settings screen shows toggles as still disabled because it cached the old status.
**Why it happens:** `getPermissionsAsync()` must be called on every Settings screen focus, not just on mount.
**How to avoid:** Use `useFocusEffect` or `AppState` change listener to re-check `Notifications.getPermissionsAsync()` when the Settings screen comes into view. This correctly handles users returning from OS settings.

### Pitfall 7: Deep-Link From Notification Tap Requires Navigation Context

**What goes wrong:** Tapping the rest timer notification after the app is backgrounded may not navigate to `workout-session` if Expo Router has not fully initialized.
**Why it happens:** `addNotificationResponseReceivedListener` fires before navigation is ready if registered at module load.
**How to avoid:** Register the notification response listener inside a `useEffect` with a navigation dependency, or use Expo Router's built-in notification URL pattern via the `url` field in notification content. The simpler approach: set `data: { url: '/workout-session' }` in the notification content and handle it via `addNotificationResponseReceivedListener` inside the app layout where navigation is ready.

---

## Code Examples

Verified patterns from official sources and existing project code:

### Remove Eager Permission (useRestTimer.ts)

```typescript
// BEFORE (remove these lines from start() in useRestTimer.ts):
const { status } = await Notifications.getPermissionsAsync();
if (status !== 'granted') {
  await Notifications.requestPermissionsAsync();
}

// AFTER: skip permission check; just try to schedule
// If permission is not granted, scheduleNotificationAsync will fail silently (caught)
```

### Check Permission Status for Settings Screen

```typescript
// Source: docs.expo.dev/versions/latest/sdk/notifications/ (verified)
import * as Notifications from 'expo-notifications';

const { status } = await Notifications.getPermissionsAsync();
const isPermissionGranted = status === 'granted';
const isPermissionDenied = status === 'denied'; // user explicitly denied
const isPermissionUndetermined = status === 'undetermined'; // never asked
```

### Open OS Notification Settings (when denied)

```typescript
// Source: React Native built-in Linking API
import { Linking } from 'react-native';

await Linking.openSettings();
// Opens the app-specific settings page on both iOS and Android
```

### Schedule Rest Timer Notification with Channel

```typescript
// Source: expo-notifications scheduleNotificationAsync + useRestTimer.ts existing pattern
const notificationId = await Notifications.scheduleNotificationAsync({
  content: {
    title: 'Rest complete!',
    body: 'Time to lift.',
    sound: true,
    ...(Platform.OS === 'android' && { android: { channelId: 'rest-timer' } }),
  },
  trigger: {
    type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
    seconds: duration,
  },
});
```

### Register Notification Response Listener for Deep-Link

```typescript
// Source: existing mock in __mocks__/expo-notifications.ts (addNotificationResponseReceivedListener)
// Wire in app/(app)/_layout.tsx useEffect:
useEffect(() => {
  const sub = Notifications.addNotificationResponseReceivedListener((response) => {
    const url = response.notification.request.content.data?.url as string | undefined;
    if (url) {
      router.push(url as never);
    }
  });
  return () => sub.remove();
}, []);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Background fetch for rest timer | Scheduled local notification with absolute timestamp | Per REQUIREMENTS.md out-of-scope | Background fetch unreliable on iOS; current approach works |
| Single `notificationsEnabled` boolean | Per-type granular fields (4 toggles) | Phase 20 | Extends AppSettings interface; old Firestore docs get defaults on next save |
| requestPermissionsAsync in useRestTimer | Deferred post-first-workout modal | Phase 20 CONTEXT.md decision | Removes two eager permission call sites |
| expo-notifications without Android channels | Channels required for Android 8+ (API 26+) | Android OS requirement | Silent drop without channel; must create before scheduling |

**Deprecated/outdated in this project:**
- `notificationsEnabled: boolean` field in AppSettings — replaced by 4 granular toggle fields

---

## Open Questions

1. **Re-scheduling daily reminder when cycle phase changes**
   - What we know: cycle phase data can update when user logs period data on the cycle screen
   - What's unclear: whether to reschedule the daily reminder automatically when cycle data updates (would change the baked-in body text)
   - Recommendation: Out of scope for Phase 20. Schedule with current phase at reminder setup time. Re-schedule only when user changes their reminder time. A future enhancement can hook into CycleRepo writes.

2. **FCM token for guest-to-auth transition**
   - What we know: guest-to-auth migration is handled in `retryPendingMigration`
   - What's unclear: whether to register FCM token during migration (after user converts from guest to authenticated)
   - Recommendation: Wire FCM token registration in `handleUserSignIn` in `app/_layout.tsx` (after auth resolves, if platform is not web and user is not anonymous). This handles both fresh sign-up and migration upgrade automatically.

3. **`DAILY` trigger type string identifier**
   - What we know: `Notifications.SchedulableTriggerInputTypes.DAILY` is the enum value
   - What's unclear: exact string value — whether it's `'daily'` or `'DAILY'` in SDK 55
   - Recommendation: Always use the enum (`SchedulableTriggerInputTypes.DAILY`), never hardcode the string.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest (existing, 71 suites / 1327+ tests) |
| Config file | `jest.config.js` at repo root |
| Quick run command | `npx jest --passWithNoTests src/domain/__tests__/` |
| Full suite command | `npx jest --passWithNoTests` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-01 | Rest timer schedules notification only when restTimerAlertsEnabled=true | unit | `npx jest --passWithNoTests src/hooks/__tests__/useRestTimer.test.ts -x` | ❌ Wave 0 |
| NOTIF-02 | First-workout detection sets AsyncStorage flag; modal shows once only | unit | `npx jest --passWithNoTests src/domain/__tests__/notifications.test.ts -x` | ❌ Wave 0 |
| NOTIF-03 | FCM token saved to Firestore after permission granted (non-guest, non-web) | unit (mocked) | `npx jest --passWithNoTests src/services/__tests__/notificationService.test.ts -x` | ❌ Wave 0 |
| NOTIF-06 | AppSettings interface includes 4 toggle fields + reminderHour/Minute with correct defaults | unit | `npx jest --passWithNoTests src/repositories/__tests__/SettingsRepo.test.ts -x` | ❌ Wave 0 |
| NOTIF-07 | Cycle-phase copy selection returns correct string for each CyclePhase union member | unit | `npx jest --passWithNoTests src/domain/__tests__/notifications.test.ts -x` | ❌ Wave 0 |
| NOTIF-08 | Schedule daily reminder: cancels existing ID, schedules new DailyTrigger, stores new ID | unit (mocked) | `npx jest --passWithNoTests src/services/__tests__/notificationService.test.ts -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `npx jest --passWithNoTests src/domain/__tests__/ src/repositories/__tests__/ -x`
- **Per wave merge:** `npx jest --passWithNoTests`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `src/hooks/__tests__/useRestTimer.test.ts` — covers NOTIF-01 (toggle guard, no permission call)
- [ ] `src/domain/__tests__/notifications.test.ts` — covers NOTIF-02 (first-workout detection logic), NOTIF-07 (cycle copy map completeness)
- [ ] `src/services/__tests__/notificationService.test.ts` — covers NOTIF-03 (FCM registration guard), NOTIF-08 (schedule/cancel/reschedule flow)
- [ ] `src/repositories/__tests__/SettingsRepo.test.ts` — covers NOTIF-06 (AppSettings schema and defaults)
- [ ] Note: `__mocks__/expo-notifications.ts` already exists with all required stubs (scheduleNotificationAsync, cancelScheduledNotificationAsync, getPermissionsAsync, requestPermissionsAsync, setNotificationChannelAsync, AndroidImportance). No mock gaps.

---

## Sources

### Primary (HIGH confidence)
- `docs.expo.dev/versions/latest/sdk/notifications/` — DailyTriggerInput API (hour, minute, repeats), setNotificationChannelAsync, requestPermissionsAsync, getPermissionsAsync, cancelScheduledNotificationAsync
- `rnfirebase.io/messaging/usage` — messaging().getToken(), onTokenRefresh listener pattern
- Existing codebase: `src/hooks/useRestTimer.ts`, `app/(app)/_layout.tsx`, `app/(app)/(tabs)/settings.tsx`, `src/repositories/SettingsRepo.ts`, `src/repositories/FirestoreSettingsRepo.ts`, `src/repositories/CycleRepo.ts`, `__mocks__/expo-notifications.ts`
- `package.json` — confirmed versions: expo-notifications ~55.0.12, @react-native-firebase/messaging ^23.8.8, expo ~55.0.6

### Secondary (MEDIUM confidence)
- expo/expo issue #30577 — confirms `repeats: true` required for DailyTriggerInput (verified by multiple community references)
- `docs.expo.dev/push-notifications/sending-notifications-custom/` — FCM token vs Expo push token distinction (we use native device token via RNFB, not Expo push token)

### Tertiary (LOW confidence)
- Medium articles on FCM token storage patterns — cross-verified against official rnfirebase.io docs

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already installed and verified in package.json from Phase 18
- Architecture: HIGH — all integration points confirmed by reading actual source files
- Pitfalls: HIGH — Android channel and DAILY repeats confirmed via official docs; eager permission sites confirmed by reading source

**Research date:** 2026-03-18
**Valid until:** 2026-06-18 (expo-notifications SDK 55 stable; unlikely to change for 90 days)
