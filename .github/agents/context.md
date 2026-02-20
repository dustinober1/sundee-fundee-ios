# Context Agent

**Scope:**
- Modify or add React context providers in `src/contexts/`
- Update the corresponding integration tests in `tests/contexts/` or
  `tests/integration/context` if they exist
- Ensure new context state is exposed via hooks and documented in README

**Reminders:**
- Wrap your component under test with the appropriate provider in tests
  using helpers from `tests/setup.ts` when available.
- When adding a new value to context, update types under `types/`.
- Run `npm run test:run` to exercise both unit and integration tests.

Example CLI registration:
```sh
gh copilot agent create context \
  --description "Work with React contexts" \
  --script "npm run test:unit && npm run test:integration && echo 'context edits'"```