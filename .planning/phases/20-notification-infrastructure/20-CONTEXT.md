# Phase 20: Notification Infrastructure - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Users receive a local push notification when their rest timer expires in the background, can grant notification permission after their first workout (not cold launch), have their FCM push token stored in Firestore, and can configure notification preferences per type in Settings — including a daily workout reminder with cycle-phase-aware copy.

</domain>

<decisions>
## Implementation Decisions

### Permission Prompt Timing
- Show permission prompt after the user completes their first workout — not during onboarding or cold launch
- Custom Art Deco styled modal before the OS dialog: explains rest timer alerts, workout reminders, WOD drops
- Two buttons: "Enable" (fires OS dialog) / "Not now" (dismisses, no re-prompt)
- Never re-prompt automatically after dismissal — user can enable from Settings at any time
- Guest users see the same permission flow as authenticated users (local notifications work without an account)
- Current useRestTimer eagerly requests permission on first rest start — refactor to remove that; permission only through the post-first-workout modal

### Notification Preferences UI
- New "Notifications" section in Settings screen (between Rest Timer and Subscription sections)
- Four independent on/off toggles matching NOTIF-06: Rest Timer Alerts, Workout Reminders, WOD Alerts, Subscription Alerts
- Persist in AppSettings (merged into Firestore /users/{uid} for authenticated, AsyncStorage for guests) — extend the existing SettingsRepo pattern, replace single `notificationsEnabled` boolean with granular fields
- When OS notification permission is denied: toggles visible but disabled/grayed out, banner says "Notifications are disabled in your device settings" with a button that deep-links to OS settings page

### Rest Timer Notification
- Keep current copy: title "Rest complete!", body "Time to lift." — no change needed
- Default system notification sound (sound: true) — no custom audio asset
- Tapping the notification deep-links back to the active workout session screen
- Respects the "Rest Timer Alerts" toggle — if disabled, visual countdown still works but no background notification is scheduled

### Daily Reminder + Cycle Copy
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

</decisions>

<specifics>
## Specific Ideas

- The permission modal should feel like a value proposition, not a permission nag — "Stay on track" framing
- Cycle copy should be brief and actionable, not a paragraph — one line max
- Rest timer notification is already partially working in useRestTimer — extend rather than rewrite

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `useRestTimer` (src/hooks/useRestTimer.ts): Already schedules local notifications via expo-notifications. Needs refactoring: remove eager permission request, add toggle check, keep notification scheduling logic
- `RestTimerBar` (src/components/workout/RestTimerBar.tsx): Visual rest timer countdown — unaffected by notification changes
- `SettingsRepo` (src/repositories/SettingsRepo.ts): AppSettings interface with `notificationsEnabled` boolean — extend with per-type fields
- `initMessaging` (src/firebase/messaging.ts): RNFB messaging module initialized at startup, explicitly defers permission/token to Phase 20
- Settings screen (app/(app)/(tabs)/settings.tsx): Already has Rest Timer section, Subscription section — insert Notifications section between them
- `getCycleRepo` (src/repositories/CycleRepo.ts): Access to cycle phase data for reminder copy

### Established Patterns
- Firebase modules use try/catch with require() for safe initialization (consistent with initAnalytics/initCrashlytics)
- Settings merged into /users/{uid} Firestore doc (not separate subcollection)
- Guest vs authenticated branching via `getSettingsRepo(isGuest)` factory
- Fire-and-forget pattern for non-critical operations (void prefix)
- expo-notifications already imported and used in useRestTimer and useWorkoutTimer

### Integration Points
- workout-session.tsx: Where rest timer runs — notification toggle check needed here
- Workout completion flow: Where first-workout permission prompt triggers
- Settings screen: New Notifications section with toggles + time picker
- app/_layout.tsx: Where FCM token registration would initialize (after auth state resolves)
- AppSettings interface: Needs new fields for per-type notification preferences + reminder time

</code_context>

<deferred>
## Deferred Ideas

- Remote push for new WOD published — Phase 21 (NOTIF-04, requires Cloud Function)
- Remote push for subscription expiry — Phase 21 (NOTIF-05, requires Cloud Function)
- Rich media notifications — v2 (NOTIF-10)
- A/B testing notification copy via Remote Config — v2 (NOTIF-11)
- Streak notifications — v2 (NOTIF-09)

</deferred>

---

*Phase: 20-notification-infrastructure*
*Context gathered: 2026-03-18*
