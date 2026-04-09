# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-04-08

### Changed

- **Major: Repository consolidated to iOS-only.** The web application (Next.js PWA), Cloud Functions (Firebase), and all supporting infrastructure have been retired and archived. The repository now contains only the native iOS app (SundeeFundeeKit + SundeeFundeeApp).

### Removed

- `web-app/` — Next.js 16 PWA (211 files)
- `firebase/` — Cloud Functions for AI workout generation (14 files)
- `backend/` — Cloudflare Workers + teenybase wrappers (3 files)
- `scripts/` — Python marketing screenshot generators (2 files)
- `docs/` — Screenshots, app store copy, documentation (51 files)
- `plans/` — Historical planning documents (28 files)
- `.agents/` — Agent skill configurations (29 files)
- 11 root-level config files (package.json, firebase.json, wrangler.toml, etc.)
- Web-specific .gitignore patterns (node_modules, .next, coverage, etc.)

### Added

- `MIGRATION.md` — Documents the platform transition with archive location
- `.gitignore` updated for iOS/Xcode patterns
- `CLAUDE.md` rewritten for iOS-only architecture
- `README.md` rewritten with iOS project overview and setup instructions
- `CHANGELOG.md` — This file

### Technical Details

- Archive of all removed code: `sundee-fundee-archive-2026-04-08.zip` (4.1 MB, 335 files)
- Zero iOS build dependencies were affected (confirmed via cross-reference scan)
- Xcode project builds successfully post-cleanup
- All 60 unit tests pass post-cleanup
