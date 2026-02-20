# Sync/Supabase Agent

**Scope:**
- Modify the optional sync layer under `src/lib/supabase/` and
  `src/lib/sync/`
- Adjust or add end-to-end tests around synchronization (`tests/e2e/sync-verification.spec.ts`)
- Ensure offline-first behavior remains intact when interacting with cloud

**Reminders:**
- Use the `NEXT_PUBLIC_SUPABASE_*` env variables in development and make sure
  they are excluded from commits.
- Update any migration or queue logic that interacts with Supabase.
- Run `npm run test:e2e` locally if a new flow is affected.

Example CLI registration:
```sh
gh copilot agent create sync-supabase \
  --description "Maintain cloud sync and e2e tests" \
  --script "npm run test:e2e tests/e2e/sync-verification.spec.ts && echo 'sync tasks'"```