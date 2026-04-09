# Requirements: Sundee Fundee — Repo Cleanup

**Defined:** 2026-04-08
**Core Value:** A clean, iOS-only repository with no web app remnants, updated docs reflecting the native-only direction.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Archive & Delete

- [ ] **ARCH-01**: User can create a zip archive of all non-iOS directories before deletion
- [ ] **ARCH-02**: User can delete web-app/ directory from repo
- [ ] **ARCH-03**: User can delete firebase/ directory from repo
- [ ] **ARCH-04**: User can delete wod-dashboard/ directory from repo
- [ ] **ARCH-05**: User can delete backend/ directory from repo
- [ ] **ARCH-06**: User can delete scripts/, screenshots/, docs/ directories from repo
- [ ] **ARCH-07**: User can delete plans/, .agents/ directories from repo
- [ ] **ARCH-08**: User can remove root config files (firebase.json, firestore.indexes.json, wrangler.toml, root package.json, and other non-iOS configs)
- [ ] **ARCH-09**: User can update .gitignore to remove Node.js/web entries and ensure Swift/Xcode patterns are present

### Documentation

- [ ] **DOCS-01**: Developer sees CLAUDE.md reflecting iOS-only project with no web/Firebase/Stripe/Cloud Functions references
- [ ] **DOCS-02**: Developer sees README.md with project overview, iOS-only setup instructions, and architecture description
- [ ] **DOCS-03**: Developer sees MIGRATION.md documenting the web-to-iOS transition for historical reference

### Verification

- [ ] **VERF-01**: Developer can confirm no broken references to deleted files/directories exist in remaining codebase

### Repo Quality

- [ ] **QUAL-01**: Developer sees CHANGELOG.md in Keep a Changelog format tracking version history
- [ ] **QUAL-02**: Developer can run SwiftLint with project-specific configuration (.swiftlint.yml)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### CI/CD

- **CICD-01**: Automated build + test on every commit via GitHub Actions for macOS
- **CICD-02**: Automated TestFlight deployment via Xcode Cloud or Fastlane

### Repo Polish

- **POSH-01**: CONTRIBUTING.md with dev environment setup and PR process
- **POSH-02**: GitHub issue and PR templates
- **POSH-03**: Swift format configuration (.swift-format)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New iOS features or improvements | This is cleanup only — no new app functionality |
| Database migration | CloudKit data is independent of Firestore; no migration needed |
| CI/CD pipeline setup | Deferred to v2 — focused on cleanup first |
| App Store submission preparation | Out of scope for repo cleanup |
| Firebase project deletion | External to repo cleanup; can be done separately |
| Vercel/deployment cleanup | External to repo; handled in hosting dashboard |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ARCH-01 | Phase 2 | Pending |
| ARCH-02 | Phase 3 | Pending |
| ARCH-03 | Phase 3 | Pending |
| ARCH-04 | Phase 3 | Pending |
| ARCH-05 | Phase 3 | Pending |
| ARCH-06 | Phase 4 | Pending |
| ARCH-07 | Phase 4 | Pending |
| ARCH-08 | Phase 5 | Pending |
| ARCH-09 | Phase 6 | Pending |
| DOCS-01 | Phase 7 | Pending |
| DOCS-02 | Phase 7 | Pending |
| DOCS-03 | Phase 8 | Pending |
| VERF-01 | Phase 1, Phase 9 | Pending |
| QUAL-01 | Phase 10 | Pending |
| QUAL-02 | Phase 11 | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after roadmap creation*
