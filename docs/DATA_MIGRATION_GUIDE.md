# Data Migration Guide: v1.1 → v2.0 (Flutter)

This guide explains how your workout data transfers from the Next.js app (v1.1) to the Flutter app (v2.0).

## Overview

The v2.0 Flutter app uses a different local storage engine (SQLite via Drift) than v1.1 (IndexedDB via Dexie). Data does NOT automatically transfer between these storage engines, even on the same device.

## Migration Paths

### Path 1: Supabase Cloud Sync (Recommended)

If you use Supabase cloud sync:

1. **In v1.1**: Ensure you're signed in and synced (green "Synced" badge)
2. **In v2.0 Flutter**: Sign in with the same Supabase account
3. **Automatic**: Your workout history downloads automatically via `syncPull()`

**What transfers:**
- Completed workouts and sets
- Active training cycles
- 1RM records
- Personal records

**Your data is safe.** Supabase retains all synced data. Sign in on any platform to restore.

### Path 2: Local-Only Users (Fresh Start)

If you never enabled Supabase sync:

- Your v1.1 data remains in browser IndexedDB
- The Flutter app starts with a clean local database
- **Your v1.1 data is NOT automatically imported**

**Options:**
1. **Enable Supabase sync in v1.1 first**: Sign up, wait for sync to complete, then migrate via Path 1
2. **Accept fresh start**: Begin new workout history in Flutter app
3. **Keep using v1.1**: The Next.js app remains available during transition

## In-App Messaging (Recommended for Future Releases)

Future releases are recommended to display contextual guidance:

- **First launch (no user)**: "Sign in to restore your workout history from cloud backup"
- **After onboarding (no sync)**: "Enable cloud sync in Settings to back up your progress"

*Note: This messaging is not implemented in v2.0 launch. It is a recommended enhancement for future versions.*

## What Doesn't Transfer

- **User preferences**: Re-enter during onboarding (minimal friction)
- **Local-only workout data**: Unless synced to Supabase first

## Technical Details

| Version | Storage Engine | Database Name |
|---------|----------------|---------------|
| v1.1 (Next.js) | IndexedDB (Dexie) | StrengthApp |
| v2.0 (Flutter Web) | SQLite (Drift via sql.js) | sundee_fundee |
| v2.0 (Flutter Mobile) | SQLite (Drift native) | sundee_fundee |

These are completely separate databases. Cross-storage import would require a dedicated migration tool (out of scope for v2.0 launch).

## FAQ

**Q: Will I lose my data if I switch to the Flutter app?**
A: No, if you have Supabase sync enabled. Sign in to restore everything.

**Q: Can I use both apps during transition?**
A: Yes. Both apps sync to the same Supabase backend. Changes sync bidirectionally.

**Q: I never set up Supabase. What now?**
A: You can enable it in v1.1 Settings before switching, or start fresh in the Flutter app.

**Q: Is there an import tool for local-only data?**
A: Not in v2.0. Supabase sync is the supported migration path.

---

*Last updated: Phase 14 (Release Hardening)*
