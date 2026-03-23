---
name: gen-test
description: Generate Vitest tests for domain layer files in pwa/src/domain/
disable-model-invocation: true
---

# Generate Domain Tests

Generate Vitest unit tests for pure TypeScript domain files.

## Usage

The user specifies a file or function in `pwa/src/domain/`. Generate comprehensive tests.

## Steps

1. Read the target source file in `pwa/src/domain/`.
2. Identify all exported functions, types, and constants.
3. Check if a corresponding `.test.ts` file already exists.
4. Generate (or append to) the test file with:
   - One `describe` block per exported function
   - Tests for happy path, edge cases, and error conditions
   - Import from the source file using relative paths

## Conventions

- Use Vitest (`describe`, `it`, `expect`) — not Jest globals.
- Domain code is pure TypeScript — no mocking needed.
- Test file goes next to the source file as `<name>.test.ts`.
- Run tests after generation to verify: `cd pwa && npx vitest run <test-file>`.
