# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Fastlane

This project uses **Fastlane** for build automation and App Store deployment. Configuration is in `fastlane/`.

### Key Files

- **`fastlane/Appfile`** — Bundle ID (`com.sundeefundee.app`), Apple ID, team IDs
- **`fastlane/Fastfile`** — Lane definitions (build, release, upload)
- **`fastlane/Deliverfile`** — App Store Connect deliver configuration
- **`fastlane/metadata/`** — App Store metadata (descriptions, keywords, etc.)
- **`fastlane/screenshots/`** — App Store screenshots

### Commands

```bash
cd SundeeFundeeApp

# Release build + upload to App Store
bundle exec fastlane release

# Run a specific lane
bundle exec fastlane <lane_name>

# List available lanes
bundle exec fastlane list
```

### Adding New Lanes

Define lanes in `fastlane/Fastfile` under `platform :ios do`. Common patterns:
- `build_app(scheme: "SundeeFundee")` — archive and export IPA
- `upload_to_app_store` — deliver to App Store Connect
- `upload_to_testflight` — deliver to TestFlight
- `increment_build_number(xcodeproj: "SundeeFundee.xcodeproj")` — bump build number

### Metadata Management

Use `fastlane deliver` to sync metadata between `fastlane/metadata/` and App Store Connect:
- `bundle exec fastlane deliver download_metadata` — pull current metadata
- `bundle exec fastlane deliver` — push metadata + screenshots
