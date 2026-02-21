# CloudKit Admin Guide — Pushing Programs to All Users

## Overview

The Sundee-Fundee app fetches workout programs from the **CloudKit public database** so you can add new programs to all users without an app update. Programs are cached locally for 6 hours and fall back to the cache if offline.

---

## CloudKit Dashboard Access

1. Go to [https://icloud.developer.apple.com](https://icloud.developer.apple.com)
2. Sign in with your Apple Developer account
3. Select container: **iCloud.com.sundeefundee.app**
4. Navigate to **Schema** → **Record Types**

---

## Record Type Schema

Create (or verify) a record type named **`Program`** with the following fields:

| Field Name       | Type   | Required | Notes                                        |
|------------------|--------|----------|----------------------------------------------|
| `programId`      | String | ✅       | Unique identifier (e.g. `easy-full-body-1`)  |
| `name`           | String | ✅       | Display name (e.g. "Full Body Beginner")     |
| `category`       | String | ✅       | e.g. `strength`, `conditioning`, `mobility`  |
| `description`    | String | ✅       | Short description shown in the program list  |
| `durationWeeks`  | Int64  | ✅       | Total program length in weeks                |
| `sessionsPerWeek`| Int64  | ✅       | Number of sessions per week                  |
| `difficulty`     | String | ✅       | `beginner`, `intermediate`, or `advanced`    |
| `programJSON`    | String | ✅       | Full JSON payload (see schema below)         |

---

## `programJSON` Field Format

The `programJSON` field must contain a valid JSON string matching the `ProgramV2` schema:

```json
{
  "id": "easy-full-body-1",
  "name": "Full Body Beginner",
  "category": "strength",
  "description": "A simple 4-week full body program for beginners.",
  "durationWeeks": 4,
  "sessionsPerWeek": 3,
  "difficulty": "beginner",
  "phases": [
    {
      "id": "phase-1",
      "name": "Foundation",
      "goal": "Build movement patterns",
      "weekRange": [1, 4]
    }
  ],
  "weeks": [
    {
      "week": 1,
      "phaseId": "phase-1",
      "isTestWeek": false,
      "sessions": [
        {
          "sessionId": "week1-day1",
          "sessionName": "Day 1",
          "sessionType": "full-body",
          "focus": "Lower + Push",
          "exercises": [
            {
              "exercise": "back-squat",
              "variant": null,
              "sets": 3,
              "reps": 8,
              "percent1RM": null,
              "restMinutes": 2.0,
              "notes": "Focus on form"
            }
          ]
        }
      ]
    }
  ]
}
```

> **Tip:** The `id` in `programJSON` should match the `programId` field on the record. The app uses `programId` from the JSON to deduplicate against local bundled programs.

---

## Adding a New Program

1. In CloudKit Dashboard → **Data** → **Public Database**
2. Click **Add Record** → select record type `Program`
3. Fill in all required fields
4. Paste the full JSON string into the `programJSON` field
5. Click **Save**

The app will pick up the new program within 6 hours (or immediately on next fresh fetch after cache expires).

---

## Exercise IDs Reference

Exercise IDs used in `programJSON` must match IDs defined in the app's `ExerciseDefinitions.swift`. Key IDs include:

- `back-squat`, `front-squat`, `pause-squat`
- `bench-press`, `incline-bench-press`
- `deadlift`, `romanian-deadlift`
- `pull-up`, `barbell-row`
- `overhead-press`
- `box-jump`, `burpees`

Use the exact IDs from `ExerciseDefinitions.swift` — unrecognised IDs will display the raw ID string as a fallback.

---

## Cache Behaviour

- Programs are cached in `UserDefaults` for **6 hours**
- On expiry, the app re-fetches from CloudKit
- If the fetch fails (e.g. offline), the last cached copy is used
- Public programs with the same `id` as a bundled program **override** the bundled version
