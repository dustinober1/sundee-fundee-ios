# Calculations Agent

**Scope:**
- Work on helpers in `src/lib/calculations.ts` and
  `src/lib/cycle-calculations.ts`
- Add or update unit tests under `tests/unit/` covering edge cases and
  invariants
- Ensure any new math has corresponding TypeScript types and comments

**Reminders:**
- Use existing tests as reference for argument ranges and rounding rules.
- When changing formulas, update docs in `docs/` if applicable.
- Run `npm run test:unit` and `npm run lint` afterwards.

Example CLI registration:
```sh
gh copilot agent create calculations \
  --description "Numerical helper logic" \
  --script "npm run test:unit tests/unit/calculations.test.ts && echo 'calc changes'"```