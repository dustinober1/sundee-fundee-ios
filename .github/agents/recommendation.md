# Recommendation Agent

**Scope:**
- Work on logic in `src/lib/recommendations/` and associated helpers.
- Write unit tests under `tests/unit/recommendations/` covering edge cases
  such as plateau detection or PR milestone triggers.

**Reminders:**
- Keep business rules clearly documented in comments; refer to any UX notes
  in `docs/`.
- Run `npm run test:unit` to ensure coverage after changes.

Example CLI registration:
```sh
gh copilot agent create recommendation \
  --description "Handle plateau and PR rule updates" \
  --script "npm run test:unit tests/unit/recommendations && echo 'rec logic'"```