# Rest Timer Feature Design

**Date:** 2026-02-16
**Status:** Approved
**Approach:** Visibility API + Web Notifications

## Overview

A rest timer feature for the Strength workout tracking app that auto-starts after logging sets and can be manually triggered anytime. Uses a floating pill UI with expandable controls, background notifications via Web Notifications API, and user-configurable alert preferences.

## User Stories

1. As a user logging a set, I want a rest timer to auto-start with the prescribed rest time so I don't have to think about it
2. As a user, I want to manually start a rest timer anytime so I can rest when I choose
3. As a user who steps away during rest, I want a notification when my rest is complete
4. As a user, I want to adjust my rest time mid-countdown if I feel ready early or need more time
5. As a user, I want to configure how I'm notified (sound, vibration, or both)

## Component Architecture

```
src/
├── components/
│   └── rest-timer/
│       ├── RestTimer.tsx          # Main container, handles state
│       ├── RestTimerPill.tsx      # Collapsed floating pill
│       ├── RestTimerExpanded.tsx  # Expanded controls overlay
│       └── RestTimerSettings.tsx  # Settings panel (sound/vibrate)
├── hooks/
│   └── useRestTimer.ts            # Timer logic, visibility API, notifications
├── contexts/
│   └── RestTimerContext.tsx       # Global timer state (auto-start from workout)
└── types/
    └── rest-timer.ts              # Timer-related types
```

The `RestTimerContext` wraps the app so the workout logger can trigger auto-start, while the pill component mounts in the workout page layout.

## State Management

### Types

```typescript
// types/rest-timer.ts
interface RestTimerState {
  status: 'idle' | 'running' | 'paused' | 'complete';
  durationSeconds: number;      // Total rest time
  remainingSeconds: number;     // Time left
  startedAt: number | null;     // Timestamp when started (for drift correction)
  isExpanded: boolean;          // UI state
  exerciseName?: string;        // Current exercise for display
}

interface RestTimerSettings {
  notificationType: 'sound' | 'vibrate' | 'both' | 'none';
  defaultRestSeconds: number;   // Fallback when no program rest time
  autoStartEnabled: boolean;    // Toggle auto-start after set logging
}
```

### Context API

- `state` — current timer state
- `settings` — user preferences
- `startRest(seconds, exerciseName?)` — begin countdown
- `pause()` / `resume()` — control playback
- `addTime(seconds)` / `subtractTime(seconds)` — adjust duration
- `cancel()` — dismiss timer entirely
- `skip()` — end rest early, mark as complete

### Auto-Start Flow

1. User logs completed set in `WorkoutLogger`
2. Logger calls `startRest(exercise.restMinutes * 60, exercise.name)`
3. Timer context updates state, pill appears
4. Logging a new set automatically dismisses any running timer

## Timer Logic

### Timing Mechanism

- Uses `setInterval` for UI updates every second
- Stores `startedAt` timestamp when timer begins
- On each tick: `remainingSeconds = durationSeconds - (now - startedAt) / 1000`
- Timestamp-based calculation prevents drift during tab switches

### Visibility API Handling

```typescript
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    // App backgrounded — record timestamp, stop interval
    hiddenAt = Date.now();
    clearInterval(intervalId);
  } else {
    // App foregrounded — recalculate remaining time, resume interval
    const elapsed = (Date.now() - hiddenAt) / 1000;
    remainingSeconds = Math.max(0, remainingSeconds - elapsed);
    startInterval();
  }
});
```

### Notification Flow

1. On timer start: request notification permission if not granted
2. When timer reaches 0: check `document.visibilityState`
3. If hidden: show Web Notification with "Rest complete!" message
4. If visible: play sound/vibrate in-app, no notification needed
5. On notification click: focus the browser tab

### Audio & Vibration

- Sound: Small embedded audio file (`/public/audio/chime.mp3`)
- Vibration: `navigator.vibrate([200, 100, 200])` pattern
- Both respect user's notification settings

## UI Design

### Collapsed Pill (RestTimerPill)

```
┌─────────────────────────────────┐
│  ⏱ 1:30  Rest: Back Squat  ▼  │
└─────────────────────────────────┘
```

- Fixed position, bottom-center, above bottom navigation
- Circular progress indicator + remaining time
- Current exercise name
- Tap to expand, swipe down to dismiss
- Pulsing animation when < 10 seconds remaining

### Expanded Overlay (RestTimerExpanded)

```
┌────────────────────────────────────┐
│            ⏱ 1:30                  │
│         ━━━━━━━━━━━━━━             │
│                                    │
│         Rest: Back Squat           │
│         Prescribed: 3 min          │
│                                    │
│    [-30s]   [Edit]   [+30s]        │
│                                    │
│      [Pause]     [Skip]            │
│                                    │
│            [Cancel]                │
└────────────────────────────────────┘
```

- Full-screen overlay with backdrop blur
- Large circular countdown with progress ring
- Quick time adjustments (-30s / +30s)
- Edit button opens duration picker
- Pause/Resume toggle, Skip ends early
- Cancel dismisses timer entirely

## Settings

### Storage

- Stored in `localStorage` under `restTimerSettings` key
- Accessible from RestTimerExpanded → Settings gear icon
- Also available in global Settings page

### Options

| Setting | Type | Default |
|---------|------|---------|
| notificationType | 'sound' \| 'vibrate' \| 'both' \| 'none' | 'both' |
| defaultRestSeconds | number | 180 (3 min) |
| autoStartEnabled | boolean | true |

### Permission Handling

- First timer start: prompt for notification permission
- If denied: show toast "Enable notifications in browser settings for rest alerts"
- Gracefully degrade to in-app only if permissions unavailable

## Edge Cases

- **User logs set before timer ends:** Timer is dismissed automatically
- **User closes tab during rest:** Notification fires if permission granted, timer resets on return
- **No program rest time specified:** Use `defaultRestSeconds` from settings
- **Vibration not supported:** Silently skip vibration, use sound only
- **Notification permission denied:** Show in-app alert only

## Out of Scope

- Rest time history/analytics
- Social features (sharing rest times)
- Custom sound uploads
- Apple Watch / Wear OS integration
