# Rollout Safety Plan

**App:** Sundee Fundee — Strength Training Tracker (Flutter)  
**Version:** v2.0 (Flutter full rewrite)  
**Last updated:** 2026-02-21  

---

## Overview

This document defines the staged rollout strategy for Sundee Fundee v2.0. The primary
goal is to detect regressions early through Crashlytics telemetry before expanding
exposure. Each stage has explicit go/no-go criteria and a tested rollback path.

---

## Telemetry Source

**Firebase Crashlytics** (added in Phase 14)

- Flutter framework errors → `FlutterError.onError` → `recordFlutterFatalError`
- Async / isolate errors → `PlatformDispatcher.onError` → `recordError(fatal: true)`
- Dashboard: [Firebase Console → Crashlytics](https://console.firebase.google.com)
- Key metric: **crash-free rate** (target ≥ 99.5%)

---

## Staged Rollout Table

| Stage | Rollout % | Duration  | Crash-Free Rate Threshold | Session Error Rate | Action on Breach      |
|-------|-----------|-----------|---------------------------|--------------------|-----------------------|
| 1     | 1%        | 24 hours  | ≥ 99.0%                   | ≤ 2%               | Halt & rollback       |
| 2     | 10%       | 48 hours  | ≥ 99.5%                   | ≤ 1%               | Halt & rollback       |
| 3     | 50%       | 72 hours  | ≥ 99.5%                   | ≤ 0.5%             | Pause & investigate   |
| 4     | 100%      | Permanent | ≥ 99.7%                   | ≤ 0.3%             | Hotfix within 4 hours |

> **Stage promotion cadence:** Monitor for full duration before advancing. Weekday
> promotions preferred (avoid Friday deploys unless critical security fix).

---

## Go / No-Go Criteria

### GO (advance to next stage) when ALL are true:
- [ ] Crash-free rate at or above threshold for the full stage duration
- [ ] No P0/P1 issues open in issue tracker related to this version
- [ ] Session error rate at or below threshold
- [ ] No regressions in workout logging core flow (start → set entry → complete)
- [ ] No data-loss reports from beta testers or early users

### NO-GO (halt rollout) when ANY are true:
- [ ] Crash-free rate drops below threshold at any point during stage
- [ ] More than 3 distinct crash signatures appear in Crashlytics in 12 hours
- [ ] Any report of user data loss (workout history, active cycle)
- [ ] Payment or account blocking bug affecting > 0.1% of sessions
- [ ] Critical security vulnerability reported

---

## Rollback Procedures

### Android — Google Play Console

1. Open [Play Console](https://play.google.com/console) → Your app → Release
2. Navigate to **Production** → **Release details**
3. Click **Halt rollout** to freeze current staged rollout immediately
4. If full rollback needed: navigate to the previous stable release version,
   click **Re-release** to promote that version to 100%
5. Verify Crashlytics crash-free rate recovers within 30 minutes

**CLI alternative (fastlane):**
```sh
fastlane supply --rollout 0  # halt rollout
```

### iOS — App Store Connect

1. Open [App Store Connect](https://appstoreconnect.apple.com) → Your app → App Store
2. Select the current version under **iOS App**
3. Under **Phased Release**, click **Pause Phased Release**
4. For full rollback: submit previous binary version for expedited review
   (use "Emergency Fix" category for faster review SLA)
5. Note: App Store does not support instant rollback — previous version re-review
   takes 24–48 hours (use pause to stop new installs)

### Web — Firebase Hosting

```sh
# List recent deploys
firebase hosting:releases:list --limit 5

# Roll back to previous deployment
firebase hosting:rollback

# Verify rollback
curl -s -o /dev/null -w "%{http_code}" https://sundeefundee.web.app
```

> Web rollback is instant — propagates via CDN within ~2 minutes globally.

---

## Monitoring Checklist

During active rollout, check these signals at each stage boundary:

- [ ] Crashlytics dashboard — crash-free rate trend (no downward trajectory)
- [ ] Crashlytics — new issue count (< 3 new issues per 24 hours at stage 1–2)
- [ ] App Store / Play Console reviews — no surge in 1-star reviews
- [ ] Firebase Performance (if enabled) — response time p99 < 3 seconds
- [ ] Supabase dashboard — DB connection pool and query error rate
- [ ] `flutter_app` GitHub Issues — no spike in user-reported bugs

---

## Incident Response

### Severity Levels

| Level | Definition                                         | Response SLA |
|-------|----------------------------------------------------|--------------|
| P0    | App crashes on launch / data loss                  | Halt + patch within 2 hours |
| P1    | Core workout flow broken for > 5% users            | Halt + patch within 4 hours |
| P2    | Feature regression, workaround exists              | Patch within 24 hours       |
| P3    | UI/cosmetic, no functional impact                  | Next scheduled release      |

### Incident Steps

1. **Detect** — Crashlytics alert fires OR user report received
2. **Assess** — Check Crashlytics for crash count, affected versions, device types
3. **Decide** — Apply go/no-go criteria; halt rollout if P0/P1
4. **Rollback** — Follow platform-specific procedure above
5. **Communicate** — Post status to team Slack `#releases` channel
6. **Root cause** — Reproduce locally with `flutter run --dart-define=...`
7. **Fix** — Hotfix branch → CI → expedited review (mobile) or `firebase hosting:rollback` (web)
8. **Post-mortem** — Document in `.planning/` within 48 hours

---

## Prerequisites Before Rollout

- [ ] `flutterfire configure` run → `lib/firebase_options.dart` committed
- [ ] `GoogleService-Info.plist` added to `ios/Runner/` (not committed — use CI secrets)
- [ ] `google-services.json` added to `android/app/` (not committed — use CI secrets)
- [ ] Crashlytics test event sent and visible in Firebase Console
- [ ] Build signing certificates valid (iOS) / keystore configured (Android)
- [ ] `flutter build appbundle --release` succeeds on CI
- [ ] `flutter build ipa --release` succeeds on CI
- [ ] `flutter build web --release` succeeds on CI
- [ ] All unit + integration tests green on CI
- [ ] DATA_MIGRATION_GUIDE.md reviewed for any required user-side migration steps
- [ ] Supabase environment variables configured in CI (SUPABASE_URL, SUPABASE_ANON_KEY)

---

## Contact / Escalation

| Role               | Responsibility                                  |
|--------------------|-------------------------------------------------|
| Release manager    | Owns stage promotion decisions and go/no-go     |
| On-call engineer   | Responds to P0/P1 incidents within SLA          |
| Firebase admin     | Crashlytics access, hosting rollback authority  |
| App store manager  | Play Console / App Store Connect permissions    |

> Escalate any P0 immediately — do not wait for the next scheduled check-in.

---

*DPLY-03 requirement satisfied: production rollout with defined telemetry thresholds,
staged deployment percentages, and tested rollback path across all platforms.*
