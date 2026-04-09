# Sundee Fundee — Repo Cleanup Roadmap

**Created:** 2026-04-08
**Granularity:** Fine (8-12 phases, 5-10 plans each)
**Mode:** YOLO (parallelization enabled)
**Coverage:** 15/15 requirements mapped

## Phases

- [ ] **Phase 1: Pre-Cleanup Audit** - Identify all dependencies and references before deletion
- [ ] **Phase 2: Archive Creation** - Create permanent backup of all non-iOS files
- [ ] **Phase 3: Directory Deletion** - Remove web-app/, firebase/, wod-dashboard/, backend/
- [ ] **Phase 4: Supporting Files Deletion** - Remove scripts/, screenshots/, docs/, plans/, .agents/
- [ ] **Phase 5: Root Config Cleanup** - Remove firebase.json, firestore.indexes.json, wrangler.toml, root package.json
- [ ] **Phase 6: Gitignore Update** - Remove web patterns and ensure iOS patterns present
- [x] **Phase 7: Documentation Core** - Rewrite CLAUDE.md and README.md for iOS-only (completed 2026-04-09)
- [x] **Phase 8: Migration Documentation** - Create MIGRATION.md documenting platform transition (completed 2026-04-09)
- [x] **Phase 9: Cross-Reference Verification** - Verify no broken references in remaining codebase (completed 2026-04-09)
- [ ] **Phase 10: CHANGELOG Creation** - Add Keep a Changelog format tracking
- [ ] **Phase 11: SwiftLint Configuration** - Add project-specific linting configuration

## Phase Details

### Phase 1: Pre-Cleanup Audit

**Goal**: Developer has complete inventory of all cross-references and dependencies before any deletion occurs
**Depends on**: Nothing (first phase)
**Requirements**: VERF-01
**Success Criteria** (what must be TRUE):
  1. Developer can view comprehensive list of all files referencing web-app/, firebase/, wod-dashboard/, backend/, scripts/, screenshots/, docs/, plans/, .agents/
  2. Developer can view comprehensive list of all root-level config files and their purposes
  3. Developer can view dependency map showing which iOS files (if any) import from directories to be deleted
  4. Developer can confirm no critical iOS build dependencies will be broken by deletions
**Plans**: 1 plan
Plans:
- [x] 01-01-PLAN.md -- Scan repository and produce audit document with cross-references and build verification

### Phase 2: Archive Creation

**Goal**: Developer has permanent backup of all multi-platform code before any deletion
**Depends on**: Phase 1
**Requirements**: ARCH-01
**Success Criteria** (what must be TRUE):
  1. Developer can download a zip archive containing all non-iOS directories (web-app/, firebase/, backend/, scripts/, docs/, plans/, .agents/, plus hidden config dirs)
  2. Zip archive includes all root-level config files to be removed (firebase.json, firestore.indexes.json, wrangler.toml, root package.json, etc.)
  3. Zip archive is named with date and version for clear identification
  4. Archive location is documented in CLAUDE.md for future reference
**Plans**: 1 plan
Plans:
- [x] 02-01-PLAN.md -- Create zip archive of all non-iOS directories and root config files with completeness validation

### Phase 3: Directory Deletion

**Goal**: All multi-platform directories are removed from the repository
**Depends on**: Phase 2
**Requirements**: ARCH-02, ARCH-03, ARCH-04, ARCH-05
**Success Criteria** (what must be TRUE):
  1. Repository no longer contains web-app/ directory
  2. Repository no longer contains firebase/ directory
  3. Repository no longer contains wod-dashboard/ directory
  4. Repository no longer contains backend/ directory
  5. Git history shows detailed commit message explaining what was deleted and why
**Plans**: TBD

### Phase 4: Supporting Files Deletion

**Goal**: All supporting directories and files are removed from repository
**Depends on**: Phase 3
**Requirements**: ARCH-06, ARCH-07
**Success Criteria** (what must be TRUE):
  1. Repository no longer contains scripts/ directory
  2. Repository no longer contains screenshots/ directory
  3. Repository no longer contains docs/ directory
  4. Repository no longer contains plans/ directory
  5. Repository no longer contains .agents/ directory
**Plans**: TBD

### Phase 5: Root Config Cleanup

**Goal**: All root-level configuration files for non-iOS platforms are removed
**Depends on**: Phase 4
**Requirements**: ARCH-08
**Success Criteria** (what must be TRUE):
  1. Repository root no longer contains firebase.json
  2. Repository root no longer contains firestore.indexes.json
  3. Repository root no longer contains wrangler.toml
  4. Repository root no longer contains root package.json
  5. Repository root no longer contains other non-iOS config files (identified in Phase 1 audit)
**Plans**: TBD

### Phase 6: Gitignore Update

**Goal**: .gitignore reflects iOS-only project with no web platform patterns
**Depends on**: Phase 5
**Requirements**: ARCH-09
**Success Criteria** (what must be TRUE):
  1. .gitignore contains no Node.js-specific patterns (node_modules/, npm-debug.log, package-lock.json, etc.)
  2. .gitignore contains no Firebase-specific patterns (firebase-debug.log, .firebase/)
  3. .gitignore contains no web framework patterns (.next/, out/, dist/)
  4. .gitignore contains standard iOS/Xcode patterns (DerivedData/, *.xcuserstate, .swiftpm/)
  5. .gitignore contains Swift Package Manager patterns (.swiftpm/, .build/, Package.resolved)
**Plans**: TBD

### Phase 7: Documentation Core

**Goal**: Core project documentation reflects iOS-only architecture
**Depends on**: Phase 6
**Requirements**: DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):
  1. CLAUDE.md contains no references to web app, Firebase, Stripe, or Cloud Functions
  2. CLAUDE.md accurately describes SundeeFundeeKit (Swift Package) and SundeeFundeeApp (Xcode project) structure
  3. CLAUDE.md documents iOS-specific commands (xcodebuild, swift test, Swift Package Manager)
  4. README.md provides clear project overview for iOS-only repository
  5. README.md includes setup instructions for Xcode project and Swift Package
  6. README.md describes iOS architecture (SundeeFundeeKit + SundeeFundeeApp)
**Plans**: TBD
**UI hint**: yes

### Phase 8: Migration Documentation

**Goal**: Developer can understand historical context of platform transition
**Depends on**: Phase 7
**Requirements**: DOCS-03
**Success Criteria** (what must be TRUE):
  1. MIGRATION.md documents the transition from multi-platform to iOS-only
  2. MIGRATION.md explains why the web app was retired
  3. MIGRATION.md references the zip archive location for historical code
  4. MIGRATION.md lists all removed directories and their former purposes
  5. MIGRATION.md documents the date of the transition
**Plans**: TBD

### Phase 9: Cross-Reference Verification

**Goal**: No broken references to deleted files or directories remain in codebase
**Depends on**: Phase 8
**Requirements**: VERF-01
**Success Criteria** (what must be TRUE):
  1. No Swift files in SundeeFundeeKit/ contain imports referencing deleted directories
  2. No Swift files in SundeeFundeeApp/ contain imports referencing deleted directories
  3. No documentation files reference deleted paths or files
  4. Xcode project builds successfully without errors
  5. All unit tests pass after cleanup
**Plans**: TBD

### Phase 10: CHANGELOG Creation

**Goal**: Developer can track version history in standardized format
**Depends on**: Phase 9
**Requirements**: QUAL-01
**Success Criteria** (what must be TRUE):
  1. CHANGELOG.md exists in repository root
  2. CHANGELOG.md follows Keep a Changelog format (version, date, Added, Changed, Removed sections)
  3. CHANGELOG.md documents this repo cleanup as initial entry
  4. CHANGELOG.md includes migration from multi-platform to iOS-only as major version change
**Plans**: TBD

### Phase 11: SwiftLint Configuration

**Goal**: Project has consistent Swift code formatting and linting
**Depends on**: Phase 10
**Requirements**: QUAL-02
**Success Criteria** (what must be TRUE):
  1. .swiftlint.yml exists in repository root
  2. .swiftlint.yml contains project-specific rules for Swift 6
  3. .swiftlint.yml includes rules for concurrency checking
  4. .swiftlint.yml excludes third-party dependencies
  5. Developer can run SwiftLint via command line to check code style
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Pre-Cleanup Audit | 0/1 | Planning complete | - |
| 2. Archive Creation | 0/1 | Planning complete | - |
| 3. Directory Deletion | 0/5 | Not started | - |
| 4. Supporting Files Deletion | 0/5 | Not started | - |
| 5. Root Config Cleanup | 0/5 | Not started | - |
| 6. Gitignore Update | 0/5 | Not started | - |
| 7. Documentation Core | 0/0 | Complete    | 2026-04-09 |
| 8. Migration Documentation | 0/0 | Complete    | 2026-04-09 |
| 9. Cross-Reference Verification | 0/0 | Complete    | 2026-04-09 |
| 10. CHANGELOG Creation | 0/4 | Not started | - |
| 11. SwiftLint Configuration | 0/5 | Not started | - |

---
*Roadmap created: 2026-04-08*
*Granularity: Fine*
*Total phases: 11*
