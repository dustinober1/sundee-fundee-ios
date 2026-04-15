# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Fastlane

Build automation and App Store deployment. Full Fastlane reference is in `.claude/rules/fastlane.md`.

### Quick Reference

```bash
cd SundeeFundeeApp
bundle exec fastlane release    # increment build, archive, upload to ASC
bundle exec fastlane list       # see all available lanes
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

### Manual Archive + Export

The `release` lane handles this automatically, but for manual control:
```bash
xcodebuild -scheme SundeeFundee -project ./SundeeFundee.xcodeproj \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/SundeeFundee.xcarchive \
  -allowProvisioningUpdates archive

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
