# iOS TestFlight Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Get the native iOS app from "builds in Simulator" to "installable via TestFlight for internal testers."

**Architecture:** Xcode project (`SundeeFundeeApp/`) imports `SundeeFundeeKit` Swift package (`SundeeFundee/`). App uses CloudKit for data, Sign in with Apple for auth, HealthKit for health data, and MockSubscriptionClient for subscription (RevenueCat not yet integrated). All 18/20 UI files are functional — only RevenueCatClient is an intentional stub.

**Tech Stack:** Swift 6.0, SwiftUI, Xcode 16, XcodeGen, CloudKit, HealthKit, AuthenticationServices

**Tools:** Xcode CLI (`xcodebuild`, `xcrun`, `xctool`), Swift CLI, Chrome browser automation for Apple Developer Portal and App Store Connect.

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `SundeeFundeeApp/project.yml` | Modify | Set DEVELOPMENT_TEAM |
| `SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/Contents.json` | Modify | Reference generated icon files |
| `SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/*.png` | Create | Generated icon images |
| `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift` | Modify | Fix "Continue" button navigation |

---

### Task 1: Build and Audit in Simulator

**Goal:** Verify the app builds for Simulator via CLI and document screen status.

**Files:**
- Read: All view files in `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/`

- [ ] **Step 1: Regenerate Xcode project from project.yml**

```bash
cd SundeeFundeeApp
xcodegen generate
```

Expected: `⚙️  Generating plists...` → `Created project at ...`

- [ ] **Step 2: Build for Simulator via CLI**

```bash
xcodebuild build \
  -project SundeeFundeeApp/SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Boot Simulator and install the app**

```bash
# Boot an iPhone 16 simulator
xcrun simctl boot "iPhone 16" 2>/dev/null || true

# Find the built .app bundle
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "SundeeFundee.app" -path "*/Debug-iphonesimulator/*" | head -1)

# Install and launch
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted com.sundeefundee.app
```

- [ ] **Step 4: Audit each screen using Chrome browser automation**

Use Chrome browser (with Simulator visible on screen) to visually inspect each tab and flow. Document findings in a triage table:

| Screen | Status | Notes |
|--------|--------|-------|
| Auth (Sign in with Apple) | Ship/Fix/Hide | |
| Onboarding | Ship/Fix/Hide | |
| Dashboard | Ship/Fix/Hide | |
| Workouts List | Ship/Fix/Hide | |
| Workout Detail | Ship/Fix/Hide | |
| Exercise Picker | Ship/Fix/Hide | |
| AI Workout | Ship/Fix/Hide | |
| Programs List | Ship/Fix/Hide | |
| Maxes List | Ship/Fix/Hide | |
| Benchmarks List | Ship/Fix/Hide | |
| Cycle Calendar | Ship/Fix/Hide | |
| Pain Tracking | Ship/Fix/Hide | |
| Settings | Ship/Fix/Hide | |

Note: Sign in with Apple uses a sandbox account in Simulator. Create one in Settings > Apple Account if needed.

- [ ] **Step 5: Commit audit findings**

Save the triage table to `docs/superpowers/plans/2026-04-02-screen-audit-results.md` and commit:

```bash
git add docs/superpowers/plans/2026-04-02-screen-audit-results.md
git commit -m "docs: add iOS screen audit results"
```

---

### Task 2: Fix Blocking Issues

**Goal:** Resolve any crashes, broken navigation, or auth failures found in the audit.

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Programs/ProgramsListView.swift` (known: "Continue" button nav issue)
- Modify: Any other files identified in the audit

- [ ] **Step 1: Fix Programs "Continue" button navigation**

Read `ProgramsListView.swift` and identify the broken navigation. The "Continue" button doesn't navigate — likely a missing `NavigationLink` or `navigationDestination` modifier.

Fix the navigation so tapping "Continue" on an enrolled program navigates to the program detail or next workout.

- [ ] **Step 2: Run Swift package tests to verify no regressions**

```bash
swift test --package-path SundeeFundee 2>&1 | tail -5
```

Expected: `Executed 321 tests, with 0 failures`

- [ ] **Step 3: Rebuild for Simulator and verify fixes**

```bash
xcodebuild build \
  -project SundeeFundeeApp/SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Fix any additional blocking issues from audit**

For each "Fix" item in the audit table, apply the minimal fix needed. Priority:
1. Crashes (app terminates)
2. Auth flow broken (can't sign in/out)
3. Core CRUD broken (can't save workouts/maxes)
4. Dead-end navigation (tap leads nowhere)

- [ ] **Step 5: Hide any incomplete screens**

For screens marked "Hide" in the audit, conditionally remove the tab from `MainTabView`. Example approach — add a `BetaConfig` enum:

```swift
// In SundeeFundee/Sources/SundeeFundeeKit/UI/App/SundeeFundeeApp.swift

public enum BetaConfig {
    /// Tabs visible in the TestFlight beta
    public static let visibleTabs: Set<Tab> = [
        .dashboard, .workouts, .maxes, .settings
        // Add/remove tabs based on audit results
    ]
}
```

Then filter tabs in `MainTabView`:

```swift
// Only show tabs that are ready for beta
if BetaConfig.visibleTabs.contains(.dashboard) {
    DashboardView()
        .tabItem { ... }
        .tag(Tab.dashboard)
}
```

- [ ] **Step 6: Commit fixes**

```bash
git add -A
git commit -m "fix: resolve blocking issues for TestFlight beta"
```

---

### Task 3: Set Team ID and Regenerate Xcode Project

**Goal:** Configure code signing so the app can run on real devices and be archived.

**Files:**
- Modify: `SundeeFundeeApp/project.yml`

- [ ] **Step 1: Get your Team ID**

```bash
# List available signing teams
security find-identity -v -p codesigning | head -10
```

The Team ID is the 10-character alphanumeric string in parentheses (e.g., `ABC123DEF0`).

Alternatively, use Chrome browser to navigate to https://developer.apple.com/account → Membership Details → Team ID.

- [ ] **Step 2: Set DEVELOPMENT_TEAM in project.yml**

Edit `SundeeFundeeApp/project.yml`, replacing the empty string:

```yaml
settings:
  base:
    SWIFT_VERSION: "6.0"
    SWIFT_STRICT_CONCURRENCY: complete
    DEVELOPMENT_TEAM: "YOUR_TEAM_ID_HERE"
```

- [ ] **Step 3: Regenerate the Xcode project**

```bash
cd SundeeFundeeApp && xcodegen generate && cd ..
```

- [ ] **Step 4: Verify the project builds with signing**

```bash
xcodebuild build \
  -project SundeeFundeeApp/SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -configuration Debug \
  2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add SundeeFundeeApp/project.yml SundeeFundeeApp/SundeeFundee.xcodeproj/
git commit -m "chore: set development team for code signing"
```

---

### Task 4: Register App ID and Capabilities in Apple Developer Portal

**Goal:** Register the App ID with required capabilities so the app can use Sign in with Apple, HealthKit, CloudKit, and push notifications on real devices.

- [ ] **Step 1: Open Apple Developer Portal in Chrome**

Navigate to https://developer.apple.com/account/resources/identifiers/list using Chrome browser automation.

- [ ] **Step 2: Check if App ID already exists**

Look for `com.sundeefundee.app` in the identifiers list. If it exists, skip to Step 4.

- [ ] **Step 3: Register new App ID**

If not found:
1. Click "+" to register a new identifier
2. Select "App IDs" → Continue
3. Select "App" → Continue
4. Description: "Sundee Fundee"
5. Bundle ID (Explicit): `com.sundeefundee.app`
6. Enable capabilities:
   - Sign in with Apple
   - HealthKit
   - iCloud (include CloudKit)
   - Push Notifications
7. Continue → Register

- [ ] **Step 4: Verify capabilities are enabled**

Click on the `com.sundeefundee.app` identifier and confirm all four capabilities show as enabled.

- [ ] **Step 5: Create CloudKit container if needed**

Navigate to https://developer.apple.com/icloud/dashboard/ (CloudKit Console).

1. Check if container `iCloud.com.sundeefundee.app` exists
2. If not, create it via the CloudKit Console
3. Verify the container is associated with the App ID

---

### Task 5: Generate App Icon

**Goal:** Create the required app icon assets from Logo.jpeg so the archive can upload to TestFlight.

**Files:**
- Source: `Logo.jpeg` (project root)
- Create: `SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
- Modify: `SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Generate 1024x1024 icon from Logo.jpeg**

```bash
# Use sips (macOS built-in) to resize Logo.jpeg to 1024x1024 PNG
sips -z 1024 1024 Logo.jpeg --out SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/icon-1024.png -s format png
```

- [ ] **Step 2: Update Contents.json to reference the icon**

Write the following to `SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

Note: Xcode 16 uses a single 1024x1024 universal icon for iOS. No need for multiple sizes.

- [ ] **Step 3: Verify the icon is picked up by the build**

```bash
xcodebuild build \
  -project SundeeFundeeApp/SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -i "icon\|asset\|error" | head -10
```

Expected: No icon-related errors.

- [ ] **Step 4: Commit**

```bash
git add SundeeFundeeApp/SundeeFundee/Assets.xcassets/AppIcon.appiconset/
git commit -m "chore: add app icon for TestFlight"
```

---

### Task 6: Build and Test on Physical Device

**Goal:** Run the app on a real iPhone to verify capabilities that don't work in Simulator (HealthKit, Sign in with Apple production, CloudKit).

- [ ] **Step 1: List connected devices**

```bash
xcrun xctrace list devices 2>&1 | grep -i iphone
```

Note the device name and UDID.

- [ ] **Step 2: Build and run on device**

```bash
xcodebuild build \
  -project SundeeFundeeApp/SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'id=DEVICE_UDID_HERE' \
  -configuration Debug \
  -allowProvisioningUpdates \
  2>&1 | tail -10
```

If automatic signing prompts for a profile, Xcode will create it. The `-allowProvisioningUpdates` flag enables this from the CLI.

- [ ] **Step 3: Install on device**

```bash
# If xcodebuild doesn't auto-install, use ios-deploy or Xcode
xcrun devicectl device install app --device DEVICE_UDID_HERE path/to/SundeeFundee.app
```

Alternatively, open the project in Xcode and hit Run with the device selected.

- [ ] **Step 4: Test core flows on device**

Verify manually (or via Chrome browser if screen-sharing the device):

1. **Sign in with Apple** — real Apple ID prompt, not sandbox
2. **Onboarding** — complete flow, profile saved
3. **HealthKit** — permission prompt appears, data reads/writes
4. **CloudKit** — data saves and loads (check CloudKit Console for records)
5. **Navigation** — all visible tabs work
6. **Workout/Maxes CRUD** — create, view, edit entries

- [ ] **Step 5: Fix device-only issues**

Common device-only problems:
- Keychain access failures (different entitlements environment)
- CloudKit container not found (needs to be created in dashboard)
- HealthKit authorization denied (check Info.plist usage descriptions)
- Networking issues (Simulator uses Mac's network, device uses cellular/WiFi)

Fix and rebuild until all core flows pass.

- [ ] **Step 6: Commit any device-specific fixes**

```bash
git add -A
git commit -m "fix: resolve device-specific issues"
```

---

### Task 7: Create App Store Connect Record

**Goal:** Set up the app in App Store Connect so TestFlight uploads are accepted.

- [ ] **Step 1: Open App Store Connect in Chrome**

Navigate to https://appstoreconnect.apple.com/apps using Chrome browser automation.

- [ ] **Step 2: Create new app**

1. Click "+" → "New App"
2. Platforms: iOS
3. Name: "Sundee Fundee"
4. Primary Language: English (U.S.)
5. Bundle ID: select `com.sundeefundee.app` from dropdown (registered in Task 4)
6. SKU: `com.sundeefundee.app` (or any unique string)
7. Full Access: Select your team
8. Click "Create"

- [ ] **Step 3: Create internal testing group**

1. In the app, go to TestFlight tab
2. Click "+" next to "Internal Testing"
3. Group Name: "Friends & Family"
4. Enable "Automatic Distribution" (builds go to testers immediately after processing)
5. Save

- [ ] **Step 4: Add internal testers**

1. Click on the "Friends & Family" group
2. Click "+" to add testers
3. Add testers by Apple ID email
4. Internal testers must be App Store Connect users on your team. If your testers aren't team members, you'll need to add them to your App Store Connect team first (Users and Access → add with "Customer Support" or "Marketing" role for minimal permissions)

---

### Task 8: Archive and Upload to TestFlight

**Goal:** Create a release archive and upload it to App Store Connect for TestFlight distribution.

- [ ] **Step 1: Clean and archive**

```bash
xcodebuild archive \
  -project SundeeFundeeApp/SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -archivePath ~/Desktop/SundeeFundee.xcarchive \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  2>&1 | tail -10
```

Expected: `** ARCHIVE SUCCEEDED **`

- [ ] **Step 2: Create ExportOptions.plist for App Store upload**

```bash
cat > /tmp/ExportOptions.plist << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID_HERE</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
PLISTEOF
```

Replace `YOUR_TEAM_ID_HERE` with the real Team ID.

- [ ] **Step 3: Export and upload to App Store Connect**

```bash
xcodebuild -exportArchive \
  -archivePath ~/Desktop/SundeeFundee.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  -exportPath ~/Desktop/SundeeFundeeExport \
  -allowProvisioningUpdates \
  2>&1 | tail -10
```

Expected: `** EXPORT SUCCEEDED **` and the IPA is uploaded to App Store Connect.

Alternatively, if CLI upload fails (common with authentication), use:

```bash
xcrun altool --upload-app \
  -f ~/Desktop/SundeeFundeeExport/SundeeFundee.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

Or upload via Xcode Organizer (open the archive, click Distribute App → App Store Connect → Upload).

- [ ] **Step 4: Verify upload in App Store Connect**

Use Chrome browser to navigate to App Store Connect → TestFlight tab.

1. Wait for the build to finish processing (usually 5-15 minutes)
2. Build status should change from "Processing" to "Ready to Test"
3. If "Missing Compliance" appears, click it and answer "No" to export compliance (the app doesn't use custom encryption beyond standard HTTPS)

- [ ] **Step 5: Add beta test notes**

In App Store Connect → TestFlight → build details:

1. Click "Test Details"
2. Add "What to Test" notes based on audit results:
   ```
   Welcome to the Sundee Fundee beta!

   What to test:
   - Sign in with Apple
   - Complete onboarding
   - Log a workout with exercises
   - Track your 1RM maxes
   - Browse the dashboard

   Known issues:
   - [List items from audit marked as known issues]
   - Subscription features use mock data (RevenueCat not yet integrated)
   ```
3. Save

---

### Task 9: Invite Testers and Verify

**Goal:** Send TestFlight invitations and confirm the app installs on a tester's device.

- [ ] **Step 1: Verify build is distributed to internal testers**

In App Store Connect (Chrome browser):
1. Go to TestFlight → "Friends & Family" group
2. Confirm the latest build shows as available
3. If "Automatic Distribution" is on, testers should already have received invites

- [ ] **Step 2: Check your own TestFlight**

Open TestFlight on your own iPhone and verify:
1. "Sundee Fundee" appears in the app list
2. You can install it
3. The app launches and shows the sign-in screen
4. Full auth → onboarding → main flow works

- [ ] **Step 3: Confirm testers received invitations**

Check with testers that they received the TestFlight invitation email. If not:
1. Verify their Apple ID email is correct in App Store Connect
2. Resend the invitation from the testing group

- [ ] **Step 4: Tag the release**

```bash
git tag -a v1.0.0-beta.1 -m "First TestFlight beta release"
git push origin v1.0.0-beta.1
```

---

## Exit Criteria

- [ ] App installs from TestFlight on tester devices
- [ ] Testers can sign in with Apple
- [ ] Testers can navigate all visible (non-hidden) screens
- [ ] Testers can log a workout or 1RM entry
- [ ] Known issues documented in TestFlight beta notes
- [ ] Git tag `v1.0.0-beta.1` created
