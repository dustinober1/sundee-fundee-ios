# Weight Unit LBS Default Design

**Date:** 2026-03-30
**Status:** Approved
**Author:** Claude Code

## Overview

Ensure all weight entries across the application display in the user's preferred unit (defaulting to LBS/lb) instead of being hardcoded to kilograms. The application already has the correct default ("lb") in settings, but UI components are ignoring the user's `weightUnit` preference.

## Problem Statement

Currently, weight displays are hardcoded to show "kg" across multiple pages:
- Maxes page (add form and history list)
- AI Workouts page (generated workout weights)
- Benchmarks page (logging form)

The user's `weightUnit` preference exists in the profile but is not being used to convert displayed values. New users default to "lb" correctly, but all UI ignores this setting.

## Architecture

### Data Model (No Changes)

All weights continue to be stored in Firestore as `weightKg` (kilograms). The `weightUnit` field in the user profile is purely a display preference.

```
User Profile
  ├── weightUnit: "lb" | "kg" (default: "lb")
  └── ...other fields

OneRepMax records
  └── weightKg: number (always stored in kg)
```

### Conversion Flow

```
Firestore (weightKg)
        ↓
UI Component fetches user's weightUnit
        ↓
Domain: fromKilograms(weightKg, weightUnit)
        ↓
Display: formatted weight + unit label
```

### Reverse Flow (Data Entry)

```
User enters weight in preferred unit
        ↓
Domain: toKilograms(input, weightUnit)
        ↓
Firestore: weightKg (converted value)
```

## Components to Modify

### Server Components
| File | Changes |
|------|---------|
| `maxes/page.tsx` | Fetch user profile, pass `weightUnit` to child, convert displays |

### Client Components
| File | Changes |
|------|---------|
| `maxes/add-max-form.tsx` | Accept `weightUnit` prop, convert input label and estimated 1RM |
| `workouts/ai/page.tsx` | Accept `weightUnit` prop, convert workout weights |
| `benchmarks/[id]/log-result-form.tsx` | Accept `weightUnit` prop, convert weight label |

### Domain Layer (No Changes)
Existing functions in `weight-unit-conversion.ts` are used:
- `fromKilograms(kg, unit)` - Convert kg to preferred unit
- `toKilograms(value, unit)` - Convert input to kg for storage
- `formatWeightWithUnit(kg, unit)` - Format with unit label

## Implementation Details

### Maxes Page

**Server component (`maxes/page.tsx`):**
```typescript
// Fetch user profile to get weightUnit
const profile = await getUserProfile();
const weightUnit = (profile?.weightUnit as string) ?? "lb";

// Convert displays
<AddMaxForm weightUnit={weightUnit} />
{records.map(r => (
  <span>{formatWeightWithUnit(r.weightKg, weightUnit)}</span>
))}
```

**Add max form (`add-max-form.tsx`):**
```typescript
interface Props { weightUnit: string }

// Label uses user's unit
<Input label={`Weight (${weightUnit})`} ... />

// Estimate display uses user's unit
<p>Estimated 1RM: {formatWeightWithUnit(estimated1RM, weightUnit)}</p>

// Save converts to kg
await addMax({
  weightKg: toKilograms(estimated1RM, weightUnit)
});
```

### AI Workouts Page

**Client component (`workouts/ai/page.tsx`):**
```typescript
// Fetch weightUnit on mount
const [weightUnit, setWeightUnit] = useState("lb");
useEffect(() => {
  fetch("/api/user/profile").then(r => r.json()).then(p => setWeightUnit(p.weightUnit ?? "lb"));
}, []);

// Convert workout weights
{ex.weightKg && (
  <span>@ {formatWeightWithUnit(ex.weightKg, weightUnit)}</span>
)}
```

### Benchmarks Page

**Log result form (`benchmarks/[id]/log-result-form.tsx`):**
```typescript
interface Props { weightUnit: string }

// Label uses user's unit
const label = scoringType === "weight"
  ? `Weight (${weightUnit})`
  : scoringType === "reps" ? "Reps" : "Score";

// Convert input to kg before saving
await logBenchmarkResult({
  scoreValue: toKilograms(parseFloat(score), weightUnit)
});
```

## Error Handling & Edge Cases

1. **No weightUnit set** - Default to "lb" (fallback: `weightUnit ?? "lb"`)
2. **Invalid weightUnit value** - Treat as "lb"
3. **NaN/null weights** - Don't display unit, show "--"
4. **Conversion precision** - Use existing `formatWeight()` function
5. **User changes setting** - Updates on next page refresh (no real-time sync needed)

## Testing Strategy

### Domain Tests (Already Exist)
- `weight-unit-conversion.test.ts` - Verify conversion functions

### New Component Tests
- Test weight display with both "lb" and "kg" preferences
- Test weight input conversion for both units
- Test edge cases (null weights, invalid units)

### Manual Testing Checklist
- [ ] New user sees lbs on all pages by default
- [ ] Switching to kg in settings updates all displays
- [ ] Adding a max in lbs displays correctly in list
- [ ] AI workout weights show in user's preferred unit
- [ ] Benchmark logging uses correct unit label
- [ ] Existing kg users continue to see kg

## Success Criteria

1. All weight displays respect the user's `weightUnit` setting
2. New users default to "lb" (pounds)
3. Existing users keep their chosen preference
4. All weight entries continue to be stored as kg in Firestore
5. No data migration required
