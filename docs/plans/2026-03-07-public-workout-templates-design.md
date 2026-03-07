# Public Workout Template System Design

## Summary

When any user generates an AI workout, an anonymized copy (exercises, sets, reps, rest times -- no weights, no user data) is automatically saved to the CloudKit Public DB. Free users can later query this pool filtered by focus, duration, and equipment, receive a random workout, and have weights filled in from their own maxes.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Template content | Full structure, weights stripped to nil | Universally applicable; existing applyWeights() logic fills them in |
| Contribution trigger | Immediately on generation | Maximizes pool size quickly |
| Weight normalization | Raw weights stripped (nil) | Simplest; no 1RM dependency at contribution time |
| User consent | Automatic (ToS disclosure) | No PII stored; exercise structures are generic fitness data |
| Retrieval method | Filter + random pick | Simple; matches questionnaire filters exactly |
| Query filters | focus, duration, equipment | Matches questionnaire; YAGNI on extras |

## Data Flow

```
User generates AI workout
    |
    v
Save full workout --> Private DB (GeneratedWorkoutRecord, existing)
    |
    v
Strip weights + user data --> SharedWorkoutTemplateRecord
    |
    v
Save to Public DB (CloudKit Public)
    |
    v
Later: Free user answers questionnaire
    |
    v
Query Public DB by focus + duration + equipment
    |
    v
Pick random result --> Fill weights from user's 1RMs
    |
    v
Present as GeneratedWorkout
```

## Model: SharedWorkoutTemplateRecord (exists in V10)

Keep the existing shape, clarify field usage:

- `id` -- UUID string, @Attribute(.unique)
- `userID` -- empty string (anonymized)
- `createdAt` -- generation timestamp
- `downloadedAt` -- set to creation time on upload, updated on download
- `workoutJSON` -- serialized GeneratedWorkout with all weightLb set to nil
- `focusRaw` -- WorkoutFocus.rawValue (indexed for CloudKit queries)
- `durationMinutes` -- from questionnaire (indexed)
- `equipmentRaw` -- EquipmentAccess.rawValue (indexed)

## Model Change: GeneratedWorkoutRecord

Already has `contributedToDatabase: Bool` in V10. Used to prevent duplicate contributions.

## Dual-Database Configuration

Two ModelConfigurations in AppModelContainer:

1. **Private config** -- All existing models except SharedWorkoutTemplateRecord. CloudKit private DB (when enabled) or local persistent.
2. **Public config** -- Only SharedWorkoutTemplateRecord. Points to `.public("iCloud.com.sundeefundee.app")`.

Both configs share the same container identifier.

## Contribution Logic

In `SwiftDataAIWorkoutService.generateWorkout()`, after saving the private record:

1. Clone the GeneratedWorkout
2. Strip all weightLb values to nil
3. Build SharedWorkoutTemplateRecord with empty userID
4. Insert into the public model context
5. Mark GeneratedWorkoutRecord.contributedToDatabase = true

If public DB write fails, log and continue silently -- the private workout is unaffected.

## Privacy

- No user ID stored on public records
- No weight data (cannot infer strength level)
- Exercise names, sets, reps, rest times are generic fitness data
- Disclosed in Terms of Service / Privacy Policy

## Future: Random Workout Generator (not built now)

- Free user answers questionnaire (focus, duration, equipment)
- Query SharedWorkoutTemplateRecord from Public DB with matching filters
- Pick random result from returned set
- Decode workoutJSON to GeneratedWorkout
- Apply weights via existing OfflineWorkoutGenerator.applyWeights() logic
- Present to user as a normal generated workout

## No Schema Migration Needed

Both SharedWorkoutTemplateRecord and GeneratedWorkoutRecord.contributedToDatabase already exist in AppSchemaV10.
