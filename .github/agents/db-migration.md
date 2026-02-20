# DB‑Migration Agent

**Scope:**
- Update `src/lib/db/dexie.ts` schema and migrations
- Add corresponding unit tests under `tests/unit/db/`
- Ensure fake-indexeddb environment works and tests pass

**Reminders:**
1. Whenever the Dexie schema changes, bump the migration version and add a
   test that opens the database using the previous version to verify the
   migration logic.
2. Run `npm run test:unit` to catch lint or type errors after edits.
3. Tag any new indexes in the schema so that the migration test covers them.

Example CLI registration:
```sh
gh copilot agent create db-migration \
  --description "Schema updates & migration tests" \
  --script "npm run test:unit tests/unit/db && echo 'stub for migration tasks'"
```