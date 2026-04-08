# Pre-Cleanup Audit

**Date:** 2026-04-08
**Base Commit:** e53c30bcbb2419eddadc38396c018895edc260a3
**Purpose:** Comprehensive inventory of all directories, files, and cross-references before repository cleanup. This document serves as the baseline for Phase 9 (Cross-Reference Verification).

---

## 1. Directories to Delete

| Directory | Files | Size | Purpose |
|-----------|-------|------|---------|
| `web-app/` | 211 | 2.9M | Next.js 16 PWA (main web application with React 19, Tailwind CSS 4, Firebase Auth, Stripe, AI workout generation) |
| `firebase/` | 12 | 156K | Cloud Functions for AI workout generation (Vertex AI Gemini, rate limiting) |
| `backend/` | 5 | 28K | Wrappers for backend tooling (teenybase build/deploy/dev scripts) |
| `src-backend/` | 1 | 4K | Backend worker source code |
| `scripts/` | 2 | 8K | Python marketing screenshot generators |
| `docs/` | 51 | 3.5M | Screenshots, app store copy, superpowers docs (plans + specs), TODO |
| `plans/` | 2 | 56K | Historical planning documents (monetization roadmap, delivery spec) |
| `.agents/` | 29 | 232K | Agent skill configurations (25 ASC skills for App Store Connect automation) |
| `.github/` | 1 | 4K | GitHub Actions CI/CD workflow |
| `.blitz/` | 1 | 4K | Blitz configuration |
| `.codex/` | 2 | 8K | Codex configuration (rules) |
| `.gemini/` | 1 | 4K | Gemini AI configuration |
| `.playwright-mcp/` | 1 | 4K | Playwright MCP settings |
| `.workflow-audit/` | 1 | 8K | Workflow audit snapshot |
| `.xcodebuildmcp/` | 1 | 4K | XcodeBuildMCP configuration |
| **Total** | **321** | **~6.9M** | |

### web-app/ Structure (211 files, 2.9M)

The main Next.js PWA application. Key subdirectories:

- `src/app/(auth)/` -- Sign-in / sign-up pages (Firebase Auth)
- `src/app/(features)/` -- Protected routes: dashboard, workouts, programs, maxes, benchmarks, cycle, settings
- `src/app/(marketing)/` -- Public pages: blog, privacy, terms, support
- `src/app/(admin)/` -- Admin dashboard
- `src/app/api/` -- API routes: auth session, AI generation, Stripe webhooks
- `src/app/auth-error/` -- Auth error handling
- `src/components/ui/` -- UI primitives (button, card, input)
- `src/components/install/` -- PWA install prompt
- `src/components/layout/` -- Bottom nav
- `src/components/providers/` -- Auth provider (Firebase Auth context)
- `src/components/admin/` -- Admin components
- `src/components/dashboard/` -- Dashboard components
- `src/lib/domain/` -- Pure TypeScript business logic (weight calculations, cycle phases, injury adaptation, benchmarks, subscriptions)
- `src/lib/domain/__tests__/` -- Vitest unit tests for domain layer
- `src/lib/__tests__/` -- Additional library tests
- `src/lib/` -- Firebase client/admin init, Firestore helpers, Stripe, blog parser, theme tokens
- `content/blog/` -- MDX blog posts
- `public/icons/` -- PWA icons
- `scripts/` -- Build/utility scripts

### firebase/ Structure (12 files, 156K)

Cloud Functions for serverless AI workout generation:

- `functions/src/index.ts` -- `generateWorkoutFn` callable function
- `functions/src/ai.ts` -- Vertex AI Gemini integration
- `functions/src/rate-limit.ts` -- Firestore-based daily rate limiting
- `functions/lib/` -- Compiled JavaScript output

### backend/ Structure (5 files, 28K)

Backend tooling wrappers using teenybase:

- `src-backend/` -- Source code for backend workers
- Contains teenybase build, deploy, dev, and migration scripts

### docs/ Structure (51 files, 3.5M)

Mixed documentation and screenshots:

- `screenshots/` -- 6 app screenshots (sign-in, dashboard, maxes, benchmarks, paywall, cycle) as PNG files
- `superpowers/plans/` -- 24 planning documents from feature development
- `superpowers/specs/` -- 19 design/spec documents from feature development
- `superpowers/phase1-summary.md` -- Phase 1 development summary
- `app-store-copy.md` -- App Store listing text
- `TODO.md` -- Development TODO tracking

### .agents/ Structure (29 files, 232K)

25 App Store Connect (ASC) agent skills for automating App Store workflows. Each skill directory contains a `SKILL.md` and optionally `rules/*.md` files. Skills include: app creation, ASO audit, build lifecycle, CLI usage, crash triage, IAP attach, ID resolution, localization, metadata sync, notarization, PPP pricing, privacy labels, release flow, RevenueCat sync, screenshot resize, shots pipeline, signing setup, submission health, subscription localization, team key creation, TestFlight orchestration, wall submit, What's New writer, workflow, and Xcode build.

---

## 2. Root-Level Files to Remove

| File | Purpose | iOS Needed? | Action |
|------|---------|-------------|--------|
| `package.json` | Node.js dependencies (react-native-purchases, teenybase) with build/deploy scripts for backend | No | Remove |
| `package-lock.json` | npm lockfile (147KB) | No | Remove |
| `firebase.json` | Firebase project config (functions source, Firestore rules/indexes) | No | Remove |
| `firestore.indexes.json` | Firestore index definitions | No | Remove |
| `.firebaserc` | Firebase project alias | No | Remove |
| `.dev.vars` | Dev environment variables (JWT secrets, Mailgun API key, admin tokens for Cloudflare/teenybase) | No | Remove |
| `wrangler.toml` | Cloudflare Workers configuration | No | Remove |
| `teenybase.ts` | Teenybase type definitions (6.7KB) | No | Remove |
| `opencode.json` | OpenCode AI tool configuration | No | Remove |
| `skills-lock.json` | Agent skills lockfile | No | Remove |
| `backlog.md` | Single backlog item ("add plate calculator to workout screen") | No | Remove |

### Root-Level Files to KEEP or REWRITE

| File | Purpose | Action |
|------|---------|--------|
| `Logo.jpeg` | App logo image (462KB) | Keep -- useful for iOS assets |
| `.mcp.json` | MCP server config (blitz-iphone, blitz-macos, claude-in-mobile, ios-control) | Keep -- contains iOS-relevant MCP servers (no XcodeBuildMCP reference found) |
| `readme.md` | Project readme (currently describes web stack) | Keep but rewrite in Phase 7 |
| `CLAUDE.md` | Claude Code instructions (16KB, comprehensive) | Keep but rewrite in Phase 7 |
| `AGENTS.md` | Agent instructions (references XcodeBuildMCP skill) | Keep but rewrite in Phase 7 |
| `.gitignore` | Git ignore patterns (contains both iOS and web patterns) | Keep but clean up in Phase 6 |

---

## 3. Cross-Reference Scan Results

### Scan 1: `grep -rn "web-app" SundeeFundee/ SundeeFundeeApp/`

**Result:** No matches found. iOS codebase has zero references to the `web-app/` directory.

### Scan 2: `grep -rn "firebase" SundeeFundee/ SundeeFundeeApp/`

**Result:** No matches found. iOS codebase has zero references to Firebase. (iOS uses CloudKit, not Firebase.)

### Scan 3: `grep -rn "wod-dashboard" SundeeFundee/ SundeeFundeeApp/`

**Result:** No matches found. iOS codebase has zero references to the admin dashboard.

### Scan 4: `grep -rn "backend" SundeeFundee/ SundeeFundeeApp/`

**Result:** 4 matches found -- all in code comments in `SundeeFundee/Sources/SundeeFundeeKit/Auth/`:

| File | Line | Match |
|------|------|-------|
| `Auth/AppleAuthResult.swift` | 8 | `/// after a successful authentication, including identity tokens for backend verification.` |
| `Auth/AppleAuthResult.swift` | 23 | `/// the user on your backend. It's specific to your app and Team ID.` |
| `Auth/AppleAuthResult.swift` | 50 | `/// This token can be sent to your backend for verification with Apple's servers.` |
| `Auth/AppleAuthClient.swift` | 110 | `/// information and tokens for backend verification.` |

**Assessment:** All 4 matches are documentation comments describing the generic concept of "backend" (server-side verification), not references to the `backend/` directory being deleted. These are safe and require no changes.

### Scan 5: `grep -rn "scripts/" SundeeFundee/ SundeeFundeeApp/`

**Result:** 1 match found:

| File | Line | Match |
|------|------|-------|
| `SundeeFundee/README.md` | 36 | `./scripts/verify-coverage.sh` |

**Assessment:** This references `SundeeFundee/scripts/verify-coverage.sh`, which is a script INSIDE the Swift Package (confirmed to exist at that path). It is NOT a reference to the root `scripts/` directory being deleted. Safe to ignore.

### Scan 6: `grep -rn "screenshots/" SundeeFundee/ SundeeFundeeApp/`

**Result:** 1 match found:

| File | Line | Match |
|------|------|-------|
| `DataLayer/HealthClientFactory.swift` | 6 | `// Switch between HealthKitClient (real device/production) and MockHealthKitClient (screenshots/testing)` |

**Assessment:** This is a code comment about using the mock client during screenshot capture. It does not reference the `docs/screenshots/` directory or any file being deleted. Safe to ignore.

### Cross-Reference Summary

| Scan | Matches | Action Required |
|------|---------|-----------------|
| web-app | 0 | None |
| firebase | 0 | None |
| wod-dashboard | 0 | None |
| backend | 4 (comments only) | None -- generic "backend" concept, not directory reference |
| scripts/ | 1 (internal ref) | None -- references SundeeFundee's own scripts/, not root scripts/ |
| screenshots/ | 1 (comment only) | None -- describes mock client usage, not a file reference |

**Conclusion:** The iOS codebase has ZERO functional dependencies on any directory being deleted. All matches are documentation comments or internal package references that do not point to deleted files.

---

## 4. iOS Build Verification

**Build command:** `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16' build`

**Build result:** (Pending -- to be recorded in Task 2)

**Test result:** (Pending -- to be recorded in Task 2)

---

## 5. Hidden Directories to Preserve

These hidden directories are for iOS tooling and project management and must NOT be deleted:

| Directory | Purpose | Action |
|-----------|---------|--------|
| `.claude/` | GSD workflow engine, Claude configuration, worktrees | Preserve |
| `.git/` | Git repository data | Preserve |
| `.planning/` | Current cleanup project planning artifacts (STATE.md, ROADMAP.md, REQUIREMENTS.md, phase documents) | Preserve |

### Directories Under Review

| Directory | Purpose | Recommendation |
|-----------|---------|----------------|
| `.xcodebuildmcp/` | XcodeBuildMCP configuration for Xcode build MCP server | Preserve if XcodeBuildMCP skill is actively used; remove otherwise |

**Note:** The `.mcp.json` file at root does NOT contain an XcodeBuildMCP server entry. It references blitz-iphone, blitz-macos, claude-in-mobile, and ios-control. The AGENTS.md file mentions XcodeBuildMCP but the actual MCP server is not configured there.

---

## 6. .gitignore Assessment

Current `.gitignore` entries that reference non-iOS tooling:

| Pattern | Tool/Platform | Phase 6 Action |
|---------|---------------|----------------|
| `functions/node_modules/` | Firebase Functions | Remove |
| `node_modules/` | Node.js | Remove |
| `.next/` | Next.js | Remove |
| `dist/` | Generic web build output | Remove |
| `__pycache__/` | Python cache (used by scripts/) | Remove |
| `*.pyc` | Python bytecode | Remove |
| `.venv/` | Python virtual environments | Remove |
| `venv/` | Python virtual environments | Remove |
| `coverage/` | Web app test coverage | Remove |
| `.vercel` | Vercel deployment | Remove |
| `.env*.local` | Web app env files | Remove |
| `AuthKey_*.p8` | Apple auth keys (2 entries) | Keep -- used by iOS |

### .gitignore Entries to Keep

These entries are relevant to iOS development and should remain:

| Pattern | Purpose |
|---------|---------|
| `*.xcuserstate` | Xcode user state |
| `xcuserdata/` | Xcode user data |
| `DerivedData/` | Xcode build artifacts |
| `.swiftpm/` | Swift Package Manager |
| `.build/` | Swift build directory |
| `Package.resolved` | SPM resolved versions |
| `*.pbxuser` | Xcode project user files |
| `*.mode1v3`, `*.mode2v3`, `*.perspectivev3` | Legacy Xcode files |
| `*.xccheckout`, `*.xcscmblueprint` | Xcode SCM files |
| `build/` | Generic build output |
| `.DS_Store` | macOS metadata |
| `*.swp`, `*~`, `*.swo` | Editor swap files |
| `.vscode/`, `*.code-workspace` | VS Code |
| `*.pem` | SSL/client certificates |
| `.env*` | Environment variables |
| `GoogleService-Info.plist` | Firebase config (may remove later) |
| `*.log` | Log files |
| `.worktrees/` | Git worktrees |
| `ExportOptions.plist` | Xcode export |
| `.idea/` | JetBrains IDE |
| `.cache/`, `tmp/` | Temp directories |
| `.claude/`, `.bg-shell/` | Claude Code |
| `.gsd`, `.gsd-id` | GSD workflow |

---

## Audit Summary

- **Total files to delete:** 321 across 15 directories (~6.9M)
- **Root files to remove:** 11 config/tooling files
- **Root files to preserve:** 4 (Logo.jpeg, .mcp.json, readme.md, CLAUDE.md, AGENTS.md)
- **Cross-references found:** 6 matches, all safe (comments or internal references, zero functional dependencies)
- **iOS build dependencies on deleted code:** NONE
- **Risk level:** LOW -- iOS codebase is fully independent of web/backend code

---

*Audit completed: 2026-04-08*
*Auditor: Automated scan (GSD Phase 01-01)*
