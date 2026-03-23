---
name: deploy
description: Pre-deploy verification - runs build, lint, and tests before triggering deploy workflow
disable-model-invocation: true
---

# Pre-Deploy Verification

Run all checks before triggering the deploy GitHub Action.

## Steps

1. Run lint:
   ```bash
   cd pwa && npm run lint
   ```

2. Run tests:
   ```bash
   cd pwa && npx vitest run
   ```

3. Run production build:
   ```bash
   cd pwa && npm run build
   ```

4. If all pass, report ready status and ask the user if they want to trigger the deploy workflow:
   ```bash
   gh workflow run deploy.yml
   ```

5. If any step fails, report the errors and do NOT offer to trigger deploy.
