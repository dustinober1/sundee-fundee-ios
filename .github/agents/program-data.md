# Program‑Data Agent

**Scope:**
- Add or modify program JSON files in `src/data/programs/`
- Update any lookup utilities or TypeScript types if the schema changes
- Write unit tests under `tests/unit/programs/` to validate parsing and
  default values

**Reminders:**
- The JSON schema is authoritative: use existing files as templates.
- When adding a new program, update any seed or migration logic if required.
- After editing, run `npm run lint` and `npm run test:unit` for coverage.

Example CLI registration:
```sh
gh copilot agent create program-data \
  --description "Manage program JSON definitions" \
  --script "npm run test:unit tests/unit/programs && echo 'edit program...'"```
