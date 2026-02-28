# App Store Metadata — Sundee Fundee

Paste this content into App Store Connect. Fields marked ⚠️ require live URLs before submission.

---

## App Information

| Field | Value |
|---|---|
| **App Name** | Sundee Fundee |
| **Subtitle** (30 chars max) | Strength on Your Cycle |
| **Primary Category** | Health & Fitness |
| **Secondary Category** | Sports |
| **Age Rating** | 17+ |

---

## Description (4000 chars max)

```
Lift smarter. Train with your body, not against it.

Sundee Fundee is the strength training app built for women who lift. It combines barbell programming with hormonal cycle awareness — so your workouts adapt to where you are in your cycle, not just where you are in the program.

CYCLE-AWARE TRAINING
Your hormones affect your strength, recovery, and energy. Sundee Fundee reads your menstrual cycle phases and adjusts training recommendations accordingly:

• Follicular & Ovulatory phases: Higher intensity, PR attempts, new volume
• Luteal phase: Moderate loads, technique focus, accessory work
• Menstrual phase: Active recovery, mobility, deload options

REAL BARBELL PROGRAMMING
Built for compound lifts — squat, bench, deadlift, overhead press, and more. Log sets, reps, and weight with barbell-aware weight tracking (45 lb bar + plate math built in). Track your one-rep maxes and watch them climb.

SMART BENCHMARKS
Set your maxes once. The app generates percentage-based targets across all your lifts, so you always know what "80% of your squat max" means without mental math.

PROGRAMS THAT PROGRESS
Follow structured training programs or build your own. Workouts are organized into programs with exercise libraries, session notes, and progress tracking.

INJURY-AWARE RECOMMENDATIONS
Log injury profiles (knee, shoulder, lower back, etc.) so the app can flag exercises that conflict with your current limitations.

PRIVATE BY DESIGN
Your data lives in your personal iCloud account — encrypted, private, and never used for advertising. We don't sell your data. We don't track you. Full stop.

WORKS WITH APPLE HEALTH
Optionally reads menstrual cycle data from Apple Health for seamless cycle phase detection. You're always in control — revoke access any time in iOS Settings.

Sundee Fundee is for the woman who takes her training seriously — who wants to stop working against her biology and start using it as an advantage.

Train smart. Lift heavy. Feel the difference.
```

---

## Keywords (100 chars max, comma-separated)

```
strength,lifting,cycle,period,hormones,barbell,workout,training,fitness,women
```

---

## What's New (Version 1.0)

```
Initial release. Cycle-aware strength training is here.
```

---

## Support URL ⚠️

Replace with your live support page URL before submission.

```
https://sundeefundee.app/support
```

---

## Privacy Policy URL ⚠️

Must be a publicly accessible webpage. Host your privacy policy (text in LegalContent.swift) before submission.

```
https://sundeefundee.app/privacy
```

---

## App Store Rating Questionnaire

Answer these in App Store Connect → App Information → Age Rating:

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Medical/Treatment Information | Infrequent/Mild |
| Gambling | None |
| Horror/Fear Themes | None |
| Mature/Suggestive Themes | None |
| Unrestrained Internet Access | No |
| Unrestricted Web Access | No |
| User-Generated Content Sharing | No |
| **Final Rating** | **17+** |

> Note: 17+ is appropriate due to potential health/medical content.

---

## TestFlight Notes (What to Test)

```
WHAT'S NEW
Version 1.0 — First TestFlight build.

WHAT TO TEST

1. ONBOARDING
   - Fresh install → Complete onboarding flow
   - Sign in with Apple → Confirm account creation
   - Set profile (name, experience level, goal)

2. DASHBOARD
   - Cycle phase card shows current phase
   - Quick-start workout button works
   - Barbell weight display is correct

3. WORKOUTS
   - Log a full workout (3+ exercises, multiple sets)
   - Verify plate math calculates correctly for barbell lifts
   - Save and confirm workout appears in history

4. PROGRAMS
   - Browse available programs
   - Start a program and complete Day 1

5. CYCLE TRACKING
   - Log a cycle start date
   - Verify phase changes after a few days

6. MAXES & BENCHMARKS
   - Set 1RM for squat, bench, deadlift
   - Verify benchmark percentages appear correctly

7. SETTINGS
   - Edit profile → changes persist
   - Add an injury profile
   - View all three legal pages (Terms, Privacy, Medical)
   - Sign out → Sign back in

8. HEALTH INTEGRATION (Optional)
   - Grant HealthKit permission
   - Verify cycle data imports from Apple Health
   - Revoke permission in iOS Settings → confirm graceful degradation

KNOWN LIMITATIONS
- Requires iOS 17.0 or later
- iPhone only (iPad not supported in v1.0)
- CloudKit sync requires iCloud account
```

---

## App Store Screenshots Required

See `scripts/screenshot-guide.md` for capture instructions.

### Required Sizes
| Device | Size | Required? |
|---|---|---|
| iPhone 6.9" (Pro Max) | 1320×2868 px | ✅ Required |
| iPhone 5.5" | 1242×2208 px | Recommended |

### Recommended Screens to Capture
1. Dashboard — cycle phase banner + today's workout card
2. Log Workout — active session with barbell lift + sets
3. Cycle view — phase calendar
4. Maxes/Benchmarks — 1RM entries with percentage breakdown
5. Programs — program list or active program day

---

## Localization

v1.0 ships English only. No localization needed at launch.
