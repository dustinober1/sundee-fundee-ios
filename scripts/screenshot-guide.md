# Screenshot Guide — Sundee Fundee

Step-by-step instructions for capturing App Store screenshots.

---

## Required Sizes

| Device | Resolution | Status |
|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320×2868 px | **Required** |
| iPhone 5.5" (iPhone 8 Plus) | 1242×2208 px | Recommended |

App Store Connect requires at least the 6.9" size. The 5.5" size covers older devices.

---

## Setup

### 1. Seed Sample Data
Run the app in the simulator with DEBUG mode. In Settings → Debug:
- Tap **"Seed Sample Data"** to populate realistic workouts, cycle data, and maxes
- This gives all screens meaningful content for screenshots

### 2. Simulator Settings
- **Simulator**: iPhone 16 Pro Max (6.9") → required size
- **Simulator**: iPhone 8 Plus (5.5") → optional
- **Appearance**: Light mode for primary set; optionally repeat in dark mode
- **Status bar**: Simulator → Features → Toggle In-Call Status Bar (keep it clean)
- **Time**: Set to 9:41 AM via `xcrun simctl status_bar booted override --time "9:41"`

---

## Screens to Capture

Capture these in order. The goal is to tell a story: "I open the app and it guides my training."

### Screen 1 — Dashboard (Hero Shot)
**What to show**: Cycle phase banner ("Follicular Phase — High energy week. Go for PRs."), today's featured workout card, and quick-start button.

**Steps**:
1. Open app → Dashboard tab
2. Confirm cycle phase card is visible
3. File → New Screenshot (⌘S)

---

### Screen 2 — Active Workout (Core Feature)
**What to show**: Live workout session with a barbell lift (e.g., Back Squat), sets logged, barbell plate math displayed, timer running.

**Steps**:
1. Tap "Start Workout" from Dashboard
2. Log 2-3 sets on a barbell lift (Back Squat or Deadlift)
3. Ensure the barbell weight display is visible (e.g., "225 lbs = 45 bar + 2×90 lb plates")
4. Screenshot mid-session

---

### Screen 3 — Cycle Phase View
**What to show**: Cycle calendar with phase colors, current phase highlighted, training tip for current phase.

**Steps**:
1. Tap Cycle tab
2. Ensure current day is highlighted with correct phase color
3. Screenshot

---

### Screen 4 — Maxes & Benchmarks
**What to show**: 1RM maxes for Big 3 lifts, with calculated percentage targets (e.g., "Squat — 185 lbs • 80% = 148 lbs").

**Steps**:
1. Go to Maxes tab (or Settings → Lift Maxes)
2. Ensure 3-4 lifts are populated with maxes
3. Tap one lift to show benchmark detail
4. Screenshot

---

### Screen 5 — Programs
**What to show**: Program list with names and descriptions, or an active program day with exercises listed.

**Steps**:
1. Go to Programs tab
2. Either show the program list or an active week view
3. Screenshot

---

### Screen 6 — Onboarding (Optional)
**What to show**: A polished onboarding screen with app icon and welcome copy.

**Steps**:
1. Delete app → reinstall fresh build
2. Stop at the most visually compelling onboarding step
3. Screenshot

---

## Capture Process

```bash
# Set clean status bar time
xcrun simctl status_bar booted override --time "9:41"

# Reset status bar to default
xcrun simctl status_bar booted clear
```

In Simulator: **File → New Screenshot** (or ⌘S)
Screenshots save to your Desktop by default.

---

## Device Frame (Optional but Recommended)

Wrap screenshots in device frames using:
- **Framer** (framer.com) — free tier available
- **AppMockUp** (appmockup.com)
- **Rottenwood** / Sketch templates

App Store Connect accepts raw screenshots without frames, but frames make listings look more polished.

---

## Upload to App Store Connect

1. Log in to appstoreconnect.apple.com
2. Select Sundee Fundee → iOS App → v1.0
3. Scroll to "App Previews and Screenshots"
4. Drag screenshots into the 6.9" and 5.5" slots
5. Arrange in the story order above (Dashboard first)

---

## Notes

- Screenshots must be exactly the required pixel dimensions — no tolerance
- No alpha channel (pure RGB PNG or JPEG)
- Max 10 screenshots per device size
- You can add text/callout overlays in Figma or Canva before upload
