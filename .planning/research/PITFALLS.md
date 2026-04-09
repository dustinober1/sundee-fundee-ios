# Domain Pitfalls

**Domain:** Repo cleanup and platform transition (multi-platform → iOS-only)
**Researched:** 2026-04-08

## Critical Pitfalls

Mistakes that cause rewrites, major issues, or permanent data loss.

### Pitfall 1: Cross-Reference Blindness

**What goes wrong:** After removing web-app/ and Firebase directories, iOS code still references deleted files through imports, configuration, or documentation. Xcode builds fail with "File not found" errors, or Swift code references non-existent shared utilities.

**Why it happens:** The codebase evolved organically with implicit dependencies. iOS-specific code may import shared types or utilities that live in the deleted web directories. Documentation (CLAUDE.md, README) describes commands that reference removed paths.

**Consequences:**
- Xcode build failures immediately after cleanup
- Broken documentation leads to confusion for future contributors
- Git history shows references to deleted files that no longer exist
- CI/CD (if any) fails with path errors

**Prevention:**
1. **Before deletion:** Create a comprehensive dependency map
   - Search for all references to `web-app/`, `firebase/`, `backend/`, `wod-dashboard/` in iOS code
   - Grep for imports, paths, and references to removed directories
   - Check Package.swift for any local package dependencies
   - Audit Xcode project file for absolute path references

2. **During deletion:** Delete references first, then directories
   - Update CLAUDE.md and README before removing code
   - Search-and-replace all documentation references to deleted paths
   - Update any build scripts that reference removed directories
   - Verify iOS project builds independently before committing deletions

3. **After deletion:** Verification step
   - Clean Xcode build folder (Product > Clean Build Folder)
   - Build fresh: `xcodebuild -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 16' clean build`
   - Run all iOS tests to ensure no hidden dependencies remain

**Detection:**
- Xcode build errors mentioning deleted paths
- Swift compiler errors for missing imports
- Git grep showing references to deleted directories in iOS code
- Documentation mentioning commands that no longer work

**Phase to address:** Phase 1 (Archive & Delete) — The dependency audit must happen before any files are deleted.

---

### Pitfall 2: Git History Orphaning

**What goes wrong:** Large-scale file deletion makes git history difficult to navigate. Commands like `git blame` become confusing because they reference deleted files. Binary file history (screenshots, assets) becomes inaccessible.

**Why it happens:** Git tracks all file history by default. When you delete directories containing years of commits, those commits remain in git log but their file contents become inaccessible through normal commands. The repo shrinks on disk but git log still shows the deleted work.

**Consequences:**
- `git show <commit>:path/to/deleted/file` fails
- `git blame` on remaining files loses context from deleted related files
- Future contributors cannot understand the evolution of features that were deleted
- If mistakes are found, reverting specific changes becomes harder
- Binary assets (screenshots, design files) become permanently inaccessible

**Prevention:**
1. **Before deletion:** Create navigable archive
   - Zip the entire repo state before cleanup: `sundee-fundee-archive.zip`
   - Store the zip in a permanent location (not just local)
   - Tag the commit before deletion: `git tag archive/pre-ios-only-cleanup`
   - Document the archive location in CLAUDE.md

2. **During deletion:** Preserve context in commits
   - Commit message should explain what was deleted and why
   - Reference the archive location in the commit message
   - Use detailed commit messages: "Retire web-app: Next.js PWA, moved to iOS-only"
   - Avoid squashing the deletion commit

3. **After deletion:** Update documentation
   - Document that history exists but is in archive
   - Update README to explain the platform transition
   - Create a MIGRATION.md explaining the transition
   - Link to the archive for anyone needing historical context

**Detection:**
- `git log --follow` on remaining files shows truncated history
- Trying to view old commits results in "fatal: bad revision" errors
- Team members ask "Where did the web app code go?"
- Need to reference an old implementation but cannot access it

**Phase to address:** Phase 1 (Archive & Delete) — Archive creation must happen before any git operations.

---

### Pitfall 3: Configuration Drift

**What goes wrong:** Root-level configuration files (firebase.json, firestore.indexes.json, wrangler.toml, package.json) remain after cleanup, confusing future contributors. CI/CD configs (if added later) reference removed directories.

**Why it happens:** These files sit at the repo root and are easy to forget. They're not in the deleted directories, so they survive the initial cleanup pass. They reference services that no longer exist (Firebase, Cloudflare Workers, Vercel).

**Consequences:**
- Future contributors are confused by configs for non-existent services
- Build scripts fail trying to deploy to Firebase/Vercel
- New CI/CD pipelines reference directories that don't exist
- Onboarding documentation contradicts actual project structure
- Search results index stale config keys

**Prevention:**
1. **Audit all config files before cleanup:**
   - List all root-level configs: `ls -la | grep -E '\.(json|toml|yml|yaml|config)'`
   - Check each file for references to deleted platforms
   - Document what each config does and whether it's still needed

2. **Delete platform-specific configs:**
   - `firebase.json` — Firebase deployment (delete)
   - `firestore.indexes.json` — Firestore indexes (delete)
   - `wrangler.toml` — Cloudflare Workers (delete)
   - Root `package.json` if only used by web backend (delete)
   - `.vercelignore`, `.vercel` directory (delete)
   - `next-sitemap.config.js` (delete, even though it's in web-app/)

3. **Keep iOS-relevant configs:**
   - `.gitignore` (update to remove web-specific entries)
   - Any iOS-specific scripts or tooling configs
   - `.agents/skills/` directory (iOS App Store automation)
   - App Store metadata files

4. **Update .gitignore:**
   - Remove entries for deleted directories
   - Remove web-specific ignores (node_modules, .next, build/, etc.)
   - Add iOS-specific ignores if not present (Xcode derived data, etc.)

**Detection:**
- Root directory lists Firebase/Cloudflare configs in a iOS-only repo
- Documentation mentions Firebase deployment commands
- `npm install` fails because package.json references deleted directories
- CI/CD pipeline references non-existent deploy targets

**Phase to address:** Phase 1 (Archive & Delete) — Config cleanup should be part of the initial deletion pass.

---

### Pitfall 4: Documentation Staleness

**What goes wrong:** CLAUDE.md, README, and other documentation still reference the web app, Firebase, Stripe, and other deleted components. Commands don't work, paths are wrong, architecture descriptions are outdated.

**Why it happens:** Documentation is updated manually and easily overlooked. The focus is on code deletion, not docs. Multiple documentation files may exist (CLAUDE.md, README.md, docs/ directory, inline comments).

**Consequences:**
- New contributors follow outdated instructions and hit errors
- `npm run dev` commands fail because web-app/ doesn't exist
- Architecture docs describe Firebase when iOS uses CloudKit
- Onboarding takes longer due to contradictory information
- Support tickets from confused users referencing deleted features

**Prevention:**
1. **Before deletion:** Audit all documentation
   - Find all markdown files: `find . -name "*.md" -not -path "./node_modules/*"`
   - Grep for references to deleted platforms: `grep -r "web-app\|Firebase\|Stripe\|Next.js" *.md`
   - List all documentation locations: README.md, CLAUDE.md, docs/, .planning/

2. **During deletion:** Update docs in same commit
   - Rewrite CLAUDE.md to describe iOS-only architecture
   - Update README to reflect iOS app only
   - Remove web-specific setup instructions
   - Update architecture diagrams to remove Firebase/Stripe
   - Remove blog, PWA, and web feature references
   - Keep iOS-relevant sections (auth, CloudKit, StoreKit, HealthKit)

3. **After deletion:** Documentation verification
   - All commands in CLAUDE.md must work
   - All file paths referenced must exist
   - Architecture diagram matches actual structure
   - Setup instructions work for a fresh clone
   - Onboarding section reflects iOS development workflow

**Detection:**
- `grep -r "web-app" CLAUDE.md README.md` returns results
- Documentation mentions Firebase/Firestore in iOS-only repo
- Commands like `cd web-app && npm run dev` fail
- Architecture section describes components that don't exist
- Users report confusion about missing features

**Phase to address:** Phase 1 (Archive & Delete) — Documentation updates must happen in the same commit as deletions.

---

## Moderate Pitfalls

Mistakes that cause confusion, extra work, or temporary issues but are recoverable.

### Pitfall 1: Forgetting to Update .gitignore

**What goes wrong:** .gitignore still references web-app specific patterns (node_modules, .next, build/, firebase-debug.log) and misses iOS-specific ignores (DerivedData/, *.pbxuser, .swiftpm).

**Why it happens:** .gitignore is at the root and easily overlooked. It's not in any deleted directory, so it survives cleanup unchanged. Web ignores are harmless but add noise. iOS ignores are missing entirely.

**Consequences:**
- `git status` shows noise from Xcode build artifacts
- Accidental commits of .DS_Store, xcuserdata, or DerivedData
- Repository bloated with ignored files that should have been excluded
- Team members commit different sets of build artifacts
- `git clean -fd` behaves differently than expected

**Prevention:**
1. **Audit .gitignore before cleanup:**
   - Remove web-specific entries: node_modules, .next, out/, build/, dist/
   - Remove Firebase-specific: firebase-debug.log, firebase-debug.*.log
   - Remove Cloudflare-specific: .wrangler/, wrangler.toml
   - Keep generic entries: .DS_Store, *.log, .env

2. **Add iOS-specific ignores:**
   - Xcode user data: *.xcuserstate, xcuserdata/, *.hmap
   - Build artifacts: DerivedData/, build/, *.ipa
   - Swift Package Manager: .swiftpm/, .build/
   - CocoaPods (if ever used): Pods/, Podfile.lock
   - SPM resolution: .swiftpm/xcode/package.resolved

3. **Test .gitignore:**
   - Create files that should be ignored
   - Run `git status` to verify they don't appear
   - Add .gitignore to the cleanup commit

**Detection:**
- `git status` shows DerivedData/, *.xcuserstate, or other build artifacts
- Team members have different git status outputs
- Repository size grows due to committed build artifacts
- `git clean -fd` removes files that should be tracked

**Phase to address:** Phase 1 (Archive & Delete) — Update .gitignore in the cleanup commit.

---

### Pitfall 2: Breaking Relative Imports

**What goes wrong:** Swift files or Package.swift reference code in directories that will be deleted. After deletion, imports fail and Xcode shows red "file not found" errors.

**Why it happens:** If the Swift Package ever had local dependencies on code outside SundeeFundee/ or SundeeFundeeApp/, those imports break. Package.swift may reference local modules that no longer exist.

**Consequences:**
- Xcode build fails immediately after cleanup
- Red error icons in Xcode navigator
- Autocomplete stops working
- Cannot open the project in Xcode until imports are fixed

**Prevention:**
1. **Before deletion:** Check Swift Package dependencies
   - Read `SundeeFundee/Package.swift` for local path dependencies
   - Search for imports outside the Swift Package: `grep -r "^import" SundeeFundee/Sources/ | grep -v "Foundation\|SwiftUI\|CloudKit\|HealthKit\|StoreKit"`
   - Check for local module imports

2. **Verify Xcode project references:**
   - Open `SundeeFundeeApp/SundeeFundee.xcodeproj/project.pbxproj`
   - Search for path references outside SundeeFundeeApp/ and SundeeFundee/
   - Check for any absolute path references (should never exist)

3. **Test build before deletion:**
   - Build the iOS app: `xcodebuild -scheme SundeeFundee build`
   - If build succeeds, no cross-platform dependencies exist
   - If build fails, fix imports before cleanup

**Detection:**
- Xcode shows red "file not found" errors after cleanup
- `xcodebuild` fails with "No such module" errors
- Imports reference paths that no longer exist
- Package.swift lists local dependencies on deleted directories

**Phase to address:** Phase 1 (Archive & Delete) — Verify iOS builds before and after cleanup.

---

### Pitfall 3: Lost Context in Git Commits

**What goes wrong:** Future contributors reading git log see "Remove web-app" and cannot understand what was deleted or why. Commit messages lack context, and the archive location is not documented.

**Why it happens:** Commit messages like "Cleanup" or "Delete web stuff" provide no context. The archive is created separately and not linked in the git history. Tagging the pre-cleanup state is forgotten.

**Consequences:**
- Git history becomes opaque after cleanup
- Cannot understand project evolution without accessing archive
- "Why was this deleted?" questions cannot be answered from git log
- Harder to revert specific changes if needed
- Historical context requires leaving the repo (to find the archive)

**Prevention:**
1. **Tag before cleanup:**
   ```bash
   git tag archive/pre-ios-only -m "Multi-platform repo before iOS-only cleanup. Contains web-app, Firebase, Cloud Functions, WOD dashboard, backend."
   git push origin archive/pre-ios-only
   ```

2. **Write detailed commit messages:**
   ```
   Retire web app and Firebase backend, transition to iOS-only

   Deleted directories:
   - web-app/: Next.js 16 PWA, Firebase/Firestore/Stripe integration
   - firebase/functions/: Cloud Functions for AI workout generation
   - backend/: Experimental Cloudflare Workers backend
   - wod-dashboard/: Admin dashboard for WODs/programs/benchmarks (not in current repo)
   - docs/, scripts/, plans/: Planning and documentation files

   Archive: sundee-fundee-archive.zip stored in [LOCATION]

   Reason: iOS app is feature-complete and ready for App Store. Web app served as MVP but is being retired. iOS uses CloudKit for persistence, not Firebase.

   Remaining: SundeeFundee/ (Swift Package), SundeeFundeeApp/ (Xcode project), .agents/ (App Store automation)
   ```

3. **Document the transition:**
   - Create MIGRATION.md explaining the platform transition
   - Link to archive in README
   - Update CLAUDE.md with iOS-only architecture
   - Reference the tag and archive in documentation

**Detection:**
- `git log --oneline` shows unhelpful messages like "cleanup"
- No tag exists for pre-cleanup state
- Archive location not documented anywhere
- Team members don't know where to find historical code

**Phase to address:** Phase 1 (Archive & Delete) — Tag and document before any deletions.

---

### Pitfall 4: Forgetting Shared Scripts

**What goes wrong:** Root-level scripts (`scripts/generate_appstore_marketing.py`) rely on files that will be deleted (e.g., scripts expect to be run from web-app/ directory, or reference web assets). After cleanup, scripts fail.

**Why it happens:** Scripts sit at the repo root, not in deleted directories. They may have implicit dependencies on directory structure that isn't obvious until they're run.

**Consequences:**
- App Store screenshot generation fails
- Deployment scripts error out
- Build automation breaks
- Team members manually work around broken scripts
- Scripts are abandoned rather than fixed

**Prevention:**
1. **Audit all scripts before cleanup:**
   - List all executable scripts: `find . -name "*.py" -o -name "*.sh" -type f -not -path "./node_modules/*" -not -path "./.git/*"`
   - Read each script for directory references
   - Test each script to verify it works

2. **Update script dependencies:**
   - Change working directory assumptions
   - Update file paths to reference iOS locations
   - Remove scripts that are no longer needed
   - Document script usage in CLAUDE.md

3. **Test scripts after cleanup:**
   - Run `scripts/generate_appstore_marketing.py` to verify it works
   - Run any other automation scripts
   - Fix or remove broken scripts

**Detection:**
- Scripts fail with "No such file or directory" errors
- `scripts/` directory contains references to deleted paths
- Documentation mentions scripts that don't work
- Team members avoid using automation scripts

**Phase to address:** Phase 1 (Archive & Delete) — Test all scripts before and after cleanup.

---

## Minor Pitfalls

Mistakes that cause annoyance or minor cleanup work but are quickly fixed.

### Pitfall 1: Leaving Empty Directories

**What goes wrong:** After deleting files, empty directories remain (e.g., `docs/` becomes empty after all web docs are removed). These clutter the repo and confuse newcomers.

**Why it happens:** `git rm` removes files but not parent directories. If all files in a directory are deleted, the empty directory remains unless explicitly removed.

**Consequences:**
- `ls` shows empty directories that serve no purpose
- Confusing for new contributors exploring the repo
- `git clean -fd` wants to delete them (adds noise)
- Documentation references non-existent files in otherwise-empty dirs

**Prevention:**
1. **After deletion, remove empty directories:**
   ```bash
   find . -type d -empty -not -path "./.git/*" -not -path "./node_modules/*"
   # Remove the listed directories
   ```

2. **Add to cleanup commit:**
   - Include empty directory removal in the deletion commit
   - Commit message: "Remove empty directories after platform cleanup"

**Detection:**
- `find . -type d -empty` returns results
- `ls -R` shows empty directories
- Team members ask "What's this directory for?"

**Phase to address:** Phase 1 (Archive & Delete) — Clean up empty dirs as part of the deletion commit.

---

### Pitfall 2: Outdated Code Comments

**What goes wrong:** Swift source files have comments referencing "web app" or "Firebase" or "shared with Next.js." After cleanup, these comments are confusing.

**Why it happens:** Code comments are not automatically updated when architecture changes. Developers wrote comments assuming the multi-platform structure.

**Consequences:**
- Comments reference non-existent platforms
- "Shared with web app" comments are misleading
- Future contributors are confused by architectural references
- Code understanding requires mental filtering of outdated comments

**Prevention:**
1. **Search for outdated comments:**
   ```bash
   grep -r "web app\|Firebase\|Next.js\|shared with" SundeeFundee/Sources/
   ```

2. **Update comments during cleanup:**
   - Remove "shared with web app" references
   - Update "Firebase" references to "CloudKit" (if applicable)
   - Remove platform comparison comments
   - Update architectural descriptions

**Detection:**
- Comments mention platforms that don't exist
- "Shared with..." references nothing
- Architectural comments contradict actual structure

**Phase to address:** Phase 2 (Documentation Updates) — Clean up comments as part of doc updates.

---

### Pitfall 3: Breaking External Links

**What goes wrong:** External documentation, blog posts, or GitHub issues link to specific file paths in the repo. After cleanup, those links return 404.

**Why it happens:** GitHub permalinks to files break when those files are deleted. External blogs or Stack Overflow answers may link to repo files. Documentation outside the repo becomes stale.

**Consequences:**
- External resources link to deleted files
- GitHub issues reference file paths that no longer exist
- Blog posts or tutorials have broken example links
- Search engines index 404 pages for the repo
- Users report "broken link" issues

**Prevention:**
1. **Before deletion:** Identify external links
   - Check GitHub issues for file references
   - Search for blog posts mentioning the repo
   - Look for Stack Overflow answers linking to repo files

2. **Create redirects if possible:**
   - GitHub doesn't support file-level redirects
   - Add a note to deleted file locations in README
   - Update external resources if you control them

3. **Document the change:**
   - Add a MIGRATION.md explaining what moved where
   - Update README with link to historical archive
   - Respond to GitHub issues with updated links

**Detection:**
- GitHub issues reference deleted file paths
- External links to repo return 404
- Users report broken documentation links
- Search results show deleted file paths

**Phase to address:** Phase 2 (Documentation Updates) — Update external links if possible, document changes.

---

## Phase-Specific Warnings

| Phase | Likely Pitfall | Mitigation |
|-------|----------------|------------|
| **Phase 1: Archive & Delete** | Cross-reference blindness | Dependency audit before deletion |
| **Phase 1: Archive & Delete** | Git history orphaning | Create archive and tag before cleanup |
| **Phase 1: Archive & Delete** | Configuration drift | Delete all platform-specific configs |
| **Phase 1: Archive & Delete** | Documentation staleness | Update docs in same commit as deletions |
| **Phase 1: Archive & Delete** | Breaking relative imports | Verify iOS builds before and after |
| **Phase 2: Doc Updates** | Leaving outdated comments | Search and update platform references |
| **Phase 2: Doc Updates** | Breaking external links | Document changes, update external resources |
| **Phase 3: Verification** | Missing broken references | Comprehensive grep for deleted paths |
| **Phase 3: Verification** | Assuming build success | Run full test suite after cleanup |

## Sources

- **Git documentation:** git clean, git rm, git history navigation (general Git knowledge, LOW confidence due to lack of specific sources)
- **Repository management best practices:** (general software engineering knowledge, LOW confidence due to lack of specific sources)
- **Platform migration common issues:** (general software engineering experience, LOW confidence due to lack of specific sources)
- **Atlassian Git Tutorial:** [How to Remove Untracked Files in Git](https://www.atlassian.com/git/tutorials/undoing-changes/git-clean) (MEDIUM confidence - authoritative source on Git commands)
- **GitHub documentation:** [Using files - GitHub Docs](https://docs.github.com/en/repositories/working-with-files/using-files) (LOW confidence - general docs, not specific to cleanup)

**Confidence assessment:** LOW to MEDIUM overall. Specific authoritative sources on repository cleanup and platform transition pitfalls were not accessible through web search. Recommendations are based on general software engineering principles, Git best practices, and common patterns in platform retirement projects. Verification through additional sources is recommended before executing the cleanup.
