# Sundee-Fundee Mobile (Expo)

This folder contains the React Native rewrite (Expo managed) for Sundee-Fundee.

## Runtime and architecture

- Runtime: Expo managed workflow + TypeScript
- Navigation: React Navigation (native stack)
- Local-first storage: `expo-sqlite` via `src/lib/db.ts`
- Sync: Supabase auth + queued background sync (`src/lib/sync.ts`)
- Theme: Art Deco-inspired token system (`src/theme/tokens.ts`)

## Commands

```bash
npm install
npm run start
npm run typecheck
npm run test
```

## Flutter feature audit (source parity target)

Key Flutter sources audited:

- Screens: dashboard, programs, program detail, workout, progress, onboarding, auth, settings
- Data: Drift schema with users, active cycles, completed workouts/sets, one-rep maxes, personal records
- Services: sync queue + push/pull order for FK-safe syncing

Current RN coverage in this folder:

- Onboarding and auth entry flow
- Program browsing + program detail
- Workout session logging to local SQLite with sync queue
- Progress analytics (weekly volume + estimated 1RM)
- Background sync scheduler and native integrations (notifications/haptics)

## Supabase configuration

Provide these values through Expo config `extra` or environment variables:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Store publishing

This folder includes EAS config (`eas.json`) and Expo app config (`app.config.ts`) for iOS/Android builds.
Before submission:

1. Set final iOS bundle identifier and Android package.
2. Configure App Store Connect / Play Console credentials in EAS.
3. Build with `npm run build` from this directory.
