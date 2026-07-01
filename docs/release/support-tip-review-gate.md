# Support Tip Review Gate

Product ID: `com.sundeefundee.app.support.tip199`

## Contract

- [ ] Consumable
- [ ] Repeatable
- [ ] Settings-only placement
- [ ] No feature unlocks
- [ ] No paywall
- [ ] No restore UI for this consumable
- [ ] No charity, fundraiser, or medical-benefit language

## Simulator StoreKit Paths

- [ ] Product loads and shows `$1.99`
- [ ] Successful purchase shows thank-you copy
- [ ] Second purchase can be started after first success
- [ ] Pending purchase shows pending copy
- [ ] Cancelled purchase shows no error
- [ ] Unavailable product shows user-facing unavailable copy
- [ ] Unverified transaction shows verification copy

## Commands

```bash
cd SundeeFundee
swift test --filter SupportTip
```

```bash
cd SundeeFundeeApp
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Notes

Do not upload, submit, or build for App Store review from this gate. Submission requires explicit user approval.
