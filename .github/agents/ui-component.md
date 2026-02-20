# UI/Component Agent

**Scope:**
- Add or update React components under `src/components/` or UI-related
  files under `src/app/` routes.
- Write or adjust React Testing Library integration tests in
  `tests/integration/` or unit tests in `tests/unit/components/`.
- Ensure Tailwind classes adhere to mobile‑first one‑handed design.

**Reminders:**
- Use the `components/` naming conventions and PascalCase.
- After creating a new component run `npm run lint` and `npm run test`
  to catch style or typing issues.
- For interactive behavior, add Playwright snippets under `tests/e2e`
  if it affects user flow.

Example CLI registration:
```sh
gh copilot agent create ui-component \
  --description "Create or tweak React UI components" \
  --script "npm run lint && npm run test && echo 'component changes'"```