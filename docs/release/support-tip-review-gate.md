# Support Tip Review Gate

Product ID: `com.sundeefundee.app.support.tip199`

## Contract

- [x] Consumable
- [x] Repeatable
- [x] Settings-only placement
- [x] No feature unlocks
- [x] No paywall
- [x] No restore UI for this consumable
- [x] No charity, fundraiser, or medical-benefit language

## Simulator StoreKit Paths

- [x] Product loads and shows `$1.99`
- [x] Successful purchase completes with the StoreKit configuration
- [x] Second purchase can be started after first success
- [x] Pending purchase shows pending copy
- [x] Cancelled purchase shows no error
- [x] Unavailable product shows user-facing unavailable copy
- [x] Unverified transaction shows verification copy

## Commands

```bash
cd SundeeFundee
swift test --filter SupportTip
```

```bash
cd SundeeFundeeApp
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet test -only-testing:SundeeFundeeTests/StoreKitSupportTipStoreIntegrationTests
```

```bash
cd SundeeFundeeApp
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## July 2, 2026 Evidence

- `swift test --filter SupportTip` passed 13 tests covering repeatable support-tip copy, purchase success, pending, cancel, unavailable, and unverified states.
- `xcodebuild ... test -only-testing:SundeeFundeeTests/StoreKitSupportTipStoreIntegrationTests` passed on iPhone 17 Pro Simulator and verified the real StoreKit configuration loads `com.sundeefundee.app.support.tip199` at `$1.99` and completes a purchase.

## Notes

Do not upload, submit, or build for App Store review from this gate. Submission requires explicit user approval.
