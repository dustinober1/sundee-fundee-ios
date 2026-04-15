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

### Upload Without Rebuild

When you already have an IPA (e.g. from a manual archive/export), upload directly:
```bash
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="<app-specific-password>" \
  bundle exec fastlane deliver --ipa /path/to/SundeeFundee.ipa \
  --skip_screenshots --force --app_version "X.Y.Z"
```

### Manual Archive + Export

The `release` lane handles this automatically, but for manual control:
```bash
# Archive
xcodebuild -scheme SundeeFundee -project ./SundeeFundee.xcodeproj \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/SundeeFundee.xcarchive \
  -allowProvisioningUpdates archive

# Export (uses automatic signing)
xcodebuild -exportArchive -archivePath /tmp/SundeeFundee.xcarchive \
  -exportOptionsPlist /tmp/export_options.plist \
  -exportPath /tmp/sundee-export \
  -allowProvisioningUpdates
```

Export options plist for App Store:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>87VVCMCW3F</string>
</dict>
</plist>
```

### Signing Requirements

- **Apple Development** certificate — for building/archiving
- **Apple Distribution** certificate — required for App Store export
- Both managed via Xcode > Settings > Accounts > Manage Certificates
- App-specific password required for `altool` uploads (set via `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` env var)

### Version Bumping

- **Marketing version** (`CFBundleShortVersionString`): `agvtool new-marketing-version X.Y.Z`
- **Build number** (`CFBundleVersion`): `agvtool new-version -all N`
- Keep Info.plist using `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` variables — don't hardcode

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
