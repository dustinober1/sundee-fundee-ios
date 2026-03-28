# Periodization Templates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 3 periodization templates (Linear, DUP, Block) to the program builder, each with proper phase structures and periodization-specific progression.

**Architecture:** Extend the existing `ProgramTemplate` enum with 3 new cases and add corresponding exercise generation logic to `ProgramTemplateGenerator`. Split the template picker in `CreateProgramView` into "Basic" and "Periodization" sections. No new files — modifications only.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing

---

## File Structure

```
Modified files only:
  SundeeFundee/Domain/ProgramTemplateGenerator.swift       — 3 new template cases + exercise pools
  SundeeFundee/Features/Programs/CreateProgramView.swift   — Split picker into Basic + Periodization sections
  SundeeFundeTests/SubscriptionTests.swift                 — Tests for new templates
```

---

### Task 1: Add Periodization Template Cases and Exercise Pools

**Files:**
- Modify: `SundeeFundee/Domain/ProgramTemplateGenerator.swift`
- Modify: `SundeeFundeTests/SubscriptionTests.swift`

- [ ] **Step 1: Write tests for new templates**

Append to `SundeeFundeTests/SubscriptionTests.swift`:

```swift
// MARK: - Periodization Template Tests

@Suite("Periodization Templates")
struct PeriodizationTemplateTests {

    @Test func linearTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .linear, name: "Linear Block", durationWeeks: 6, sessionsPerWeek: 3
        )
        #expect(program.name == "Linear Block")
        #expect(program.category == "custom")
        #expect(program.weeks.count == 6)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
            for session in week.sessions {
                #expect(!session.exercises.isEmpty)
            }
        }
    }

    @Test func linearProgressionDecreasesReps() {
        let program = ProgramTemplateGenerator.generate(
            template: .linear, name: "Test", durationWeeks: 6, sessionsPerWeek: 3
        )
        let week1Ex = program.weeks[0].sessions[0].exercises[0]
        let week6Ex = program.weeks[5].sessions[0].exercises[0]
        let w1Reps = PeriodizationTemplateTests.extractReps(week1Ex.reps)
        let w6Reps = PeriodizationTemplateTests.extractReps(week6Ex.reps)
        #expect(w1Reps > w6Reps, "Linear: reps should decrease over weeks")
    }

    @Test func linearProgressionIncreasesIntensity() {
        let program = ProgramTemplateGenerator.generate(
            template: .linear, name: "Test", durationWeeks: 6, sessionsPerWeek: 3
        )
        let week1Ex = program.weeks[0].sessions[0].exercises[0]
        let week6Ex = program.weeks[5].sessions[0].exercises[0]
        #expect((week6Ex.percent1RM ?? 0) > (week1Ex.percent1RM ?? 0), "Linear: %1RM should increase over weeks")
    }

    @Test func dupTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .dup, name: "DUP Block", durationWeeks: 4, sessionsPerWeek: 3
        )
        #expect(program.weeks.count == 4)
        for week in program.weeks {
            #expect(week.sessions.count == 3)
        }
    }

    @Test func dupVariesRepSchemeWithinWeek() {
        let program = ProgramTemplateGenerator.generate(
            template: .dup, name: "Test", durationWeeks: 4, sessionsPerWeek: 3
        )
        let week1 = program.weeks[0]
        let day1Reps = PeriodizationTemplateTests.extractReps(week1.sessions[0].exercises[0].reps)
        let day2Reps = PeriodizationTemplateTests.extractReps(week1.sessions[1].exercises[0].reps)
        let day3Reps = PeriodizationTemplateTests.extractReps(week1.sessions[2].exercises[0].reps)
        // DUP: Heavy (low reps), Moderate (mid reps), Volume (high reps)
        #expect(day1Reps < day2Reps, "DUP: Day 1 (heavy) should have fewer reps than Day 2 (moderate)")
        #expect(day2Reps < day3Reps, "DUP: Day 2 (moderate) should have fewer reps than Day 3 (volume)")
    }

    @Test func blockTemplateDefaults() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Block Periodization", durationWeeks: 9, sessionsPerWeek: 3
        )
        #expect(program.weeks.count == 9)
        #expect(program.phases.count == 3)
    }

    @Test func blockPhaseNames() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        #expect(program.phases[0].name == "Accumulation")
        #expect(program.phases[1].name == "Intensification")
        #expect(program.phases[2].name == "Peaking")
    }

    @Test func blockPhaseWeekRanges() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        #expect(program.phases[0].weekRange == [1, 3])
        #expect(program.phases[1].weekRange == [4, 6])
        #expect(program.phases[2].weekRange == [7, 9])
    }

    @Test func blockAccumulationHasHighReps() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        let accumEx = program.weeks[0].sessions[0].exercises[0]
        let peakEx = program.weeks[8].sessions[0].exercises[0]
        let accumReps = PeriodizationTemplateTests.extractReps(accumEx.reps)
        let peakReps = PeriodizationTemplateTests.extractReps(peakEx.reps)
        #expect(accumReps > peakReps, "Block: Accumulation reps > Peaking reps")
    }

    @Test func blockPeakingHasHighIntensity() {
        let program = ProgramTemplateGenerator.generate(
            template: .block, name: "Test", durationWeeks: 9, sessionsPerWeek: 3
        )
        let accumEx = program.weeks[0].sessions[0].exercises[0]
        let peakEx = program.weeks[8].sessions[0].exercises[0]
        #expect((peakEx.percent1RM ?? 0) > (accumEx.percent1RM ?? 0), "Block: Peaking %1RM > Accumulation %1RM")
    }

    @Test func newTemplateDisplayInfo() {
        #expect(ProgramTemplate.linear.displayName == "Linear")
        #expect(ProgramTemplate.dup.displayName == "Daily Undulating")
        #expect(ProgramTemplate.block.displayName == "Block")
        #expect(!ProgramTemplate.linear.icon.isEmpty)
        #expect(!ProgramTemplate.dup.icon.isEmpty)
        #expect(!ProgramTemplate.block.icon.isEmpty)
    }

    @Test func allSixTemplatesExist() {
        #expect(ProgramTemplate.allCases.count == 6)
    }

    @Test func periodizationTemplatesAreTagged() {
        #expect(ProgramTemplate.linear.isPeriodization == true)
        #expect(ProgramTemplate.dup.isPeriodization == true)
        #expect(ProgramTemplate.block.isPeriodization == true)
        #expect(ProgramTemplate.strength.isPeriodization == false)
        #expect(ProgramTemplate.hypertrophy.isPeriodization == false)
        #expect(ProgramTemplate.fullBody.isPeriodization == false)
    }

    // Helper
    static func extractReps(_ value: ExerciseValue) -> Int {
        switch value {
        case .fixed(let n): return n
        case .range(let lo, _): return lo
        case .amrap: return 0
        case .text: return 0
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/PeriodizationTemplateTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: FAIL — `.linear`, `.dup`, `.block` don't exist yet

- [ ] **Step 3: Add new template cases to ProgramTemplate enum**

In `ProgramTemplateGenerator.swift`, add 3 new cases to the `ProgramTemplate` enum after `.fullBody`:

```swift
case linear
case dup
case block
```

Add to each computed property:

In `displayName`:
```swift
case .linear: "Linear"
case .dup: "Daily Undulating"
case .block: "Block"
```

In `icon`:
```swift
case .linear: "chart.line.uptrend.xyaxis"
case .dup: "arrow.up.arrow.down"
case .block: "square.stack.3d.up"
```

In `subtitle`:
```swift
case .linear: "Progressive overload, decreasing reps"
case .dup: "Vary intensity daily"
case .block: "Accumulation → Intensification → Peaking"
```

In `descriptionText`:
```swift
case .linear: "6 weeks · 3x/week"
case .dup: "4 weeks · 3x/week"
case .block: "9 weeks · 3x/week"
```

In `defaultDuration`:
```swift
case .linear: 6
case .dup: 4
case .block: 9
```

In `defaultFrequency`:
```swift
case .linear: 3
case .dup: 3
case .block: 3
```

Add a new computed property to `ProgramTemplate`:

```swift
var isPeriodization: Bool {
    switch self {
    case .linear, .dup, .block: true
    case .strength, .hypertrophy, .fullBody: false
    }
}
```

- [ ] **Step 4: Update ProgramTemplateGenerator.generate to handle new templates**

The `generate` method needs to produce `ProgramPhase` structures for block periodization. Replace the entire `generate` method:

```swift
static func generate(
    template: ProgramTemplate,
    name: String,
    durationWeeks: Int,
    sessionsPerWeek: Int
) -> Program {
    let weeks = (1...durationWeeks).map { weekNum in
        let sessions = (1...sessionsPerWeek).map { dayNum in
            buildSession(template: template, week: weekNum, day: dayNum, sessionsPerWeek: sessionsPerWeek, totalWeeks: durationWeeks)
        }
        let phaseID: String? = if template == .block {
            blockPhaseID(week: weekNum, totalWeeks: durationWeeks)
        } else {
            nil
        }
        return ProgramWeek(week: weekNum, phaseID: phaseID, isTestWeek: nil, sessions: sessions)
    }

    let phases = template == .block ? blockPhases(totalWeeks: durationWeeks) : []

    return Program(
        id: UUID().uuidString,
        name: name,
        category: "custom",
        description: "\(template.displayName) program — \(durationWeeks) weeks, \(sessionsPerWeek)x/week",
        durationWeeks: durationWeeks,
        sessionsPerWeek: sessionsPerWeek,
        difficulty: "intermediate",
        phases: phases,
        weeks: weeks,
        cycleAdjustmentProfile: nil
    )
}
```

- [ ] **Step 5: Update buildSession to pass totalWeeks**

Update the `buildSession` signature and body:

```swift
private static func buildSession(
    template: ProgramTemplate,
    week: Int,
    day: Int,
    sessionsPerWeek: Int,
    totalWeeks: Int
) -> ProgramSession {
    let focus = sessionFocus(template: template, day: day, sessionsPerWeek: sessionsPerWeek)
    let exercises = sessionExercises(template: template, focus: focus, week: week, day: day, totalWeeks: totalWeeks)

    return ProgramSession(
        sessionID: "w\(week)d\(day)",
        sessionName: sessionName(template: template, day: day, focus: focus),
        sessionType: "strength",
        focus: focus,
        exercises: exercises
    )
}

private static func sessionName(template: ProgramTemplate, day: Int, focus: String) -> String {
    switch template {
    case .dup:
        let labels = ["Heavy", "Moderate", "Volume", "Heavy", "Moderate"]
        let label = labels[(day - 1) % labels.count]
        return "Day \(day) — \(label)"
    default:
        return "Day \(day) — \(focus.capitalized) Focus"
    }
}
```

- [ ] **Step 6: Update sessionFocus for new templates**

Add cases to `sessionFocus`:

```swift
case .linear:
    let focuses = ["squat", "bench", "deadlift", "overhead press", "squat"]
    return focuses[(day - 1) % focuses.count]
case .dup:
    // DUP uses same focus (full body compounds) every day, varies intensity
    return "full body"
case .block:
    let focuses = ["squat", "bench", "deadlift", "overhead press", "squat"]
    return focuses[(day - 1) % focuses.count]
```

- [ ] **Step 7: Update sessionExercises for new templates**

Replace `sessionExercises` to accept `day` and `totalWeeks`:

```swift
private static func sessionExercises(template: ProgramTemplate, focus: String, week: Int, day: Int = 1, totalWeeks: Int = 4) -> [ProgramExercise] {
    switch template {
    case .strength, .hypertrophy, .fullBody:
        let baseExercises = exercisePool(template: template, focus: focus)
        let progressionOffset = Double(week - 1) * 0.02
        return baseExercises.map { (name, sets, reps, basePct, rest, bw) in
            ProgramExercise(
                exercise: name, variant: nil, sets: .fixed(sets), reps: .fixed(reps),
                percent1RM: bw ? nil : basePct + progressionOffset,
                restMinutes: rest, notes: nil, bodyweightOnly: bw
            )
        }
    case .linear:
        return linearExercises(focus: focus, week: week, totalWeeks: totalWeeks)
    case .dup:
        return dupExercises(day: day, week: week)
    case .block:
        return blockExercises(focus: focus, week: week, totalWeeks: totalWeeks)
    }
}
```

- [ ] **Step 8: Add linearExercises method**

```swift
// MARK: - Linear Periodization

private static func linearExercises(focus: String, week: Int, totalWeeks: Int) -> [ProgramExercise] {
    let progress = Double(week - 1) / Double(max(totalWeeks - 1, 1))
    let reps = Int(round(10.0 - progress * 7.0))  // 10 → 3
    let pct = 0.60 + progress * 0.28              // 60% → 88%
    let sets = reps <= 3 ? 5 : 4
    let rest = reps <= 5 ? 3.0 : 2.0

    let pool = linearPool(focus: focus)
    return pool.map { (name, bw) in
        ProgramExercise(
            exercise: name, variant: nil, sets: .fixed(sets),
            reps: .fixed(reps),
            percent1RM: bw ? nil : pct,
            restMinutes: rest, notes: nil, bodyweightOnly: bw
        )
    }
}

private static func linearPool(focus: String) -> [(String, Bool)] {
    switch focus {
    case "squat":
        return [("Back Squat", false), ("Front Squat", false), ("Leg Press", false), ("Walking Lunge", false), ("Calf Raise", false)]
    case "bench":
        return [("Bench Press", false), ("Incline Dumbbell Press", false), ("Barbell Row", false), ("Lateral Raise", false), ("Tricep Pushdown", false)]
    case "deadlift":
        return [("Deadlift", false), ("Romanian Deadlift", false), ("Pull-Up", true), ("Hip Thrust", false), ("Plank", true)]
    default:
        return [("Overhead Press", false), ("Push Press", false), ("Lateral Raise", false), ("Face Pull", false), ("Dip", true)]
    }
}
```

- [ ] **Step 9: Add dupExercises method**

```swift
// MARK: - Daily Undulating Periodization

private static func dupExercises(day: Int, week: Int) -> [ProgramExercise] {
    let weekOffset = Double(week - 1) * 0.02

    let dayIndex = (day - 1) % 3
    let (reps, basePct, sets, rest): (Int, Double, Int, Double) = switch dayIndex {
    case 0: (3, 0.85, 5, 3.0)   // Heavy
    case 1: (6, 0.72, 4, 2.0)   // Moderate
    default: (12, 0.60, 3, 1.5) // Volume
    }

    let exercises: [(String, Bool)] = [
        ("Back Squat", false),
        ("Bench Press", false),
        ("Deadlift", false),
        ("Overhead Press", false),
        ("Pull-Up", true),
    ]

    return exercises.map { (name, bw) in
        ProgramExercise(
            exercise: name, variant: nil, sets: .fixed(sets),
            reps: .fixed(reps),
            percent1RM: bw ? nil : basePct + weekOffset,
            restMinutes: rest, notes: nil, bodyweightOnly: bw
        )
    }
}
```

- [ ] **Step 10: Add blockExercises and blockPhases methods**

```swift
// MARK: - Block Periodization

private static func blockPhases(totalWeeks: Int) -> [ProgramPhase] {
    let phaseLength = totalWeeks / 3
    return [
        ProgramPhase(id: "accumulation", name: "Accumulation", goal: "Build work capacity with high volume, moderate intensity", weekRange: [1, phaseLength]),
        ProgramPhase(id: "intensification", name: "Intensification", goal: "Increase intensity, reduce volume", weekRange: [phaseLength + 1, phaseLength * 2]),
        ProgramPhase(id: "peaking", name: "Peaking", goal: "Peak strength with low volume, max intensity", weekRange: [phaseLength * 2 + 1, totalWeeks]),
    ]
}

private static func blockPhaseID(week: Int, totalWeeks: Int) -> String {
    let phaseLength = totalWeeks / 3
    if week <= phaseLength { return "accumulation" }
    if week <= phaseLength * 2 { return "intensification" }
    return "peaking"
}

private static func blockExercises(focus: String, week: Int, totalWeeks: Int) -> [ProgramExercise] {
    let phaseLength = totalWeeks / 3
    let (reps, basePct, sets, rest): (Int, Double, Int, Double)
    let phaseWeek: Int

    if week <= phaseLength {
        // Accumulation: high volume
        let weekInPhase = week - 1
        reps = 10
        basePct = 0.60 + Double(weekInPhase) * 0.02
        sets = 4
        rest = 1.5
        phaseWeek = weekInPhase
    } else if week <= phaseLength * 2 {
        // Intensification: moderate volume, high intensity
        let weekInPhase = week - phaseLength - 1
        reps = 5
        basePct = 0.75 + Double(weekInPhase) * 0.02
        sets = 4
        rest = 2.5
        phaseWeek = weekInPhase
    } else {
        // Peaking: low volume, max intensity
        let weekInPhase = week - phaseLength * 2 - 1
        reps = 2
        basePct = 0.85 + Double(weekInPhase) * 0.02
        sets = 5
        rest = 3.0
        phaseWeek = weekInPhase
    }

    let pool = blockPool(focus: focus)
    return pool.map { (name, bw) in
        ProgramExercise(
            exercise: name, variant: nil, sets: .fixed(sets),
            reps: .fixed(reps),
            percent1RM: bw ? nil : basePct,
            restMinutes: rest, notes: nil, bodyweightOnly: bw
        )
    }
}

private static func blockPool(focus: String) -> [(String, Bool)] {
    switch focus {
    case "squat":
        return [("Back Squat", false), ("Front Squat", false), ("Leg Press", false), ("Walking Lunge", false), ("Calf Raise", false)]
    case "bench":
        return [("Bench Press", false), ("Incline Dumbbell Press", false), ("Barbell Row", false), ("Lateral Raise", false), ("Tricep Pushdown", false)]
    case "deadlift":
        return [("Deadlift", false), ("Romanian Deadlift", false), ("Pull-Up", true), ("Hip Thrust", false), ("Plank", true)]
    default:
        return [("Overhead Press", false), ("Push Press", false), ("Lateral Raise", false), ("Face Pull", false), ("Dip", true)]
    }
}
```

- [ ] **Step 11: Run tests to verify they pass**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests/PeriodizationTemplateTests \
  -only-testing:SundeeFundeTests/ProgramTemplateGeneratorTests \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20
```
Expected: ALL PASS (new periodization tests + existing template tests)

- [ ] **Step 12: Commit**

```bash
git add SundeeFundee/Domain/ProgramTemplateGenerator.swift SundeeFundeTests/SubscriptionTests.swift
git commit -m "feat: add Linear, DUP, and Block periodization templates"
```

---

### Task 2: Split Template Picker in CreateProgramView

**Files:**
- Modify: `SundeeFundee/Features/Programs/CreateProgramView.swift`

- [ ] **Step 1: Update the templatePicker to split into sections**

Replace the `templatePicker` computed property in `CreateProgramView.swift`:

```swift
private var templatePicker: some View {
    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("BASIC")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                .tracking(1)

            ForEach(ProgramTemplate.allCases.filter { !$0.isPeriodization }, id: \.self) { template in
                templateButton(template)
            }
        }

        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("PERIODIZATION")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                .tracking(1)

            ForEach(ProgramTemplate.allCases.filter(\.isPeriodization), id: \.self) { template in
                templateButton(template)
                    .requiresSubscription(.periodizationTemplates)
            }
        }
    }
}

private func templateButton(_ template: ProgramTemplate) -> some View {
    Button {
        viewModel.selectTemplate(template)
    } label: {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: template.icon)
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(template.displayName)
                    .font(AppTheme.Fonts.subheading)
                Text(template.descriptionText + " · " + template.subtitle)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .foregroundStyle(AppTheme.Colors.navy)
        .cornerRadius(AppTheme.CornerRadius.card)
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 2: Build to verify**

Run:
```bash
xcodebuild build \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SundeeFundee/Features/Programs/CreateProgramView.swift
git commit -m "feat: split template picker into Basic and Periodization sections"
```

---

### Task 3: Full Verification and TODO Update

**Files:**
- Modify: `docs/TODO.md`

- [ ] **Step 1: Run full test suite**

Run:
```bash
xcodebuild test \
  -project SundeeFundee.xcodeproj \
  -scheme SundeeFundee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:SundeeFundeTests \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```
Expected: ALL TESTS PASS

- [ ] **Step 2: Update TODO.md**

Change:
```markdown
- [ ] **Periodization Templates** — Pre-built linear, undulating, block periodization structures
```
to:
```markdown
- [x] **Periodization Templates** — Added Linear, Daily Undulating (DUP), and Block periodization templates with proper phase structures and progression patterns. Plus-gated in template picker.
```

- [ ] **Step 3: Commit**

```bash
git add docs/TODO.md
git commit -m "docs: mark Periodization Templates as complete"
```
