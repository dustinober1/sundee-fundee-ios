# Onboarding Wizard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 3-step full-screen onboarding flow that collects user profile data (name, experience, goals) and creates user profile before navigating to dashboard.

**Architecture:** Single onboarding screen manages step state and form data, delegates to child step components for rendering. Uses React Native Paper components, UserContext for user creation, and Expo Router for navigation.

**Tech Stack:** React Native, Expo Router, React Native Paper, TypeScript, UserContext, AsyncStorage

---

## Prerequisites

**Location:** `/Users/dustinober/Projects/strength/apps/mobile`

**Existing Infrastructure:**
- ✅ UserContext with `createUser()` function
- ✅ Navigation with Expo Router
- ✅ Design tokens (Colors, Typography, Spacing)
- ✅ UI component wrappers (Button, Card, Text)
- ✅ AsyncStorage database layer

**Reference Docs:**
- Design: `docs/plans/2026-02-16-onboarding-wizard-design.md`
- Types: `types/user.ts` (User, ExperienceLevel, PrimaryGoal)
- UserContext: `contexts/user-context.tsx`

---

## Task 1: Create Step Indicator Component

**Files:**
- Create: `app/components/onboarding/step-indicator.tsx`

**Step 1: Create component file**

```typescript
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, Spacing, Typography } from '@/constants';

interface StepIndicatorProps {
  currentStep: number;
  totalSteps: number;
}

export function StepIndicator({ currentStep, totalSteps }: StepIndicatorProps) {
  return (
    <View style={styles.container}>
      <View style={styles.dots}>
        {Array.from({ length: totalSteps }).map((_, index) => (
          <View
            key={index}
            style={[
              styles.dot,
              index === currentStep - 1 && styles.dotActive,
            ]}
          />
        ))}
      </View>
      <Text style={styles.label}>Step {currentStep} of {totalSteps}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  dots: {
    flexDirection: 'row',
    gap: Spacing.sm,
    marginBottom: Spacing.xs,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.text.disabled,
  },
  dotActive: {
    backgroundColor: Colors.primary,
    width: 24,
  },
  label: {
    ...Typography.caption,
    color: Colors.text.secondary,
  },
});
```

**Step 2: Verify TypeScript compiles**

Run: `npx tsc --noEmit`
Expected: No errors

**Step 3: Commit**

```bash
git add app/components/onboarding/step-indicator.tsx
git commit -m "feat: add step indicator component for onboarding

Create visual progress indicator with dots and label
Highlight active step with primary color and wider dot
Use design tokens for consistent styling

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Create Name Step Component (Step 1)

**Files:**
- Create: `app/components/onboarding/name-step.tsx`
- Create: `app/components/onboarding/__tests__/name-step.test.tsx`

**Step 1: Write the failing test**

Create: `app/components/onboarding/__tests__/name-step.test.tsx`

```typescript
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { NameStep } from '../name-step';

describe('NameStep', () => {
  it('renders input field with label', () => {
    const { getByPlaceholderText, getByText } = render(
      <NameStep value="" onChange={jest.fn()} />
    );

    expect(getByPlaceholderText('Enter your name')).toBeTruthy();
    expect(getByText('What\'s your name?')).toBeTruthy();
  });

  it('calls onChange when text is entered', () => {
    const onChange = jest.fn();
    const { getByPlaceholderText } = render(
      <NameStep value="" onChange={onChange} />
    );

    const input = getByPlaceholderText('Enter your name');
    fireEvent.changeText(input, 'John');

    expect(onChange).toHaveBeenCalledWith('John');
  });

  it('displays error message when name is empty', () => {
    const { getByText } = render(
      <NameStep value="" onChange={jest.fn()} error="Name is required" />
    );

    expect(getByText('Name is required')).toBeTruthy();
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npm test -- app/components/onboarding/__tests__/name-step.test.tsx`
Expected: FAIL with "Unable to find ../name-step"

**Step 3: Write minimal implementation**

Create: `app/components/onboarding/name-step.tsx`

```typescript
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { TextInput } from 'react-native-paper';
import { Colors, Spacing, Typography } from '@/constants';

interface NameStepProps {
  value: string;
  onChange: (name: string) => void;
  error?: string;
}

export function NameStep({ value, onChange, error }: NameStepProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>What's your name?</Text>
      <TextInput
        value={value}
        onChangeText={onChange}
        placeholder="Enter your name"
        mode="outlined"
        style={styles.input}
        error={!!error}
      />
      {error && <Text style={styles.error}>{error}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    ...Typography.body,
    marginBottom: Spacing.sm,
    color: Colors.text.primary,
  },
  input: {
    backgroundColor: Colors.surface,
  },
  error: {
    ...Typography.small,
    color: Colors.error,
    marginTop: Spacing.xs,
  },
});
```

**Step 4: Run test to verify it passes**

Run: `npm test -- app/components/onboarding/__tests__/name-step.test.tsx`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add app/components/onboarding/name-step.tsx app/components/onboarding/__tests__/name-step.test.tsx
git commit -m "feat: add name input step component

Implement text input for user's name
Show error message when validation fails
Call onChange callback on text change
Add tests for rendering, input, and error display

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Create Experience Step Component (Step 2)

**Files:**
- Create: `app/components/onboarding/experience-step.tsx`
- Create: `app/components/onboarding/__tests__/experience-step.test.tsx`

**Step 1: Write the failing test**

Create: `app/components/onboarding/__tests__/experience-step.test.tsx`

```typescript
import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { ExperienceStep } from '../experience-step';
import { ExperienceLevel } from '@/types';

describe('ExperienceStep', () => {
  const experienceLevels: ExperienceLevel[] = ['beginner', 'intermediate', 'advanced'];

  it('renders three radio options', () => {
    const { getByText } = render(
      <ExperienceStep value="beginner" onChange={jest.fn()} />
    );

    expect(getByText('0-1 years (Beginner)')).toBeTruthy();
    expect(getByText('1-3 years (Intermediate)')).toBeTruthy();
    expect(getByText('3+ years (Advanced)')).toBeTruthy();
  });

  it('pre-selects beginner by default', () => {
    const { getByText } = render(
      <ExperienceStep value="beginner" onChange={jest.fn()} />
    );

    // Beginner should be selected (checked)
    expect(getByText('0-1 years (Beginner)')).toBeTruthy();
  });

  it('calls onChange when option is selected', () => {
    const onChange = jest.fn();
    const { getByText } = render(
      <ExperienceStep value="beginner" onChange={onChange} />
    );

    fireEvent.press(getByText('1-3 years (Intermediate)'));
    expect(onChange).toHaveBeenCalledWith('intermediate');
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npm test -- app/components/onboarding/__tests__/experience-step.test.tsx`
Expected: FAIL with "Unable to find ../experience-step"

**Step 3: Write minimal implementation**

Create: `app/components/onboarding/experience-step.tsx`

```typescript
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { RadioButton } from 'react-native-paper';
import { Colors, Spacing, Typography } from '@/constants';
import type { ExperienceLevel } from '@/types';

interface ExperienceStepProps {
  value: ExperienceLevel;
  onChange: (level: ExperienceLevel) => void;
}

const OPTIONS = [
  { value: 'beginner' as ExperienceLevel, label: '0-1 years (Beginner)' },
  { value: 'intermediate' as ExperienceLevel, label: '1-3 years (Intermediate)' },
  { value: 'advanced' as ExperienceLevel, label: '3+ years (Advanced)' },
];

export function ExperienceStep({ value, onChange }: ExperienceStepProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>Training experience</Text>
      <RadioButton.Group onValueChange={onChange} value={value}>
        {OPTIONS.map((option) => (
          <View key={option.value} style={styles.option}>
            <RadioButton value={option.value} />
            <Text style={styles.optionLabel}>{option.label}</Text>
          </View>
        ))}
      </RadioButton.Group>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    ...Typography.body,
    marginBottom: Spacing.md,
    color: Colors.text.primary,
  },
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  optionLabel: {
    ...Typography.body,
    marginLeft: Spacing.sm,
    color: Colors.text.primary,
  },
});
```

**Step 4: Run test to verify it passes**

Run: `npm test -- app/components/onboarding/__tests__/experience-step.test.tsx`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add app/components/onboarding/experience-step.tsx app/components/onboarding/__tests__/experience-step.test.tsx
git commit -m "feat: add experience selection step component

Implement radio buttons for training experience level
Display three options: beginner, intermediate, advanced
Pre-select beginner as default option
Call onChange callback when selection changes
Add tests for rendering and selection behavior

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Create Goal Step Component (Step 3)

**Files:**
- Create: `app/components/onboarding/goal-step.tsx`
- Create: `app/components/onboarding/__tests__/goal-step.test.tsx`

**Step 1: Write the failing test**

Create: `app/components/onboarding/__tests__/goal-step.test.tsx`

```typescript
import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { GoalStep } from '../goal-step';
import { PrimaryGoal } from '@/types';

describe('GoalStep', () => {
  it('renders three radio options', () => {
    const { getByText } = render(
      <GoalStep value="strength" onChange={jest.fn()} />
    );

    expect(getByText('Build Strength')).toBeTruthy();
    expect(getByText('Build Muscle')).toBeTruthy();
    expect(getByText('Improve Endurance')).toBeTruthy();
  });

  it('pre-selects strength by default', () => {
    const { getByText } = render(
      <GoalStep value="strength" onChange={jest.fn()} />
    );

    expect(getByText('Build Strength')).toBeTruthy();
  });

  it('calls onChange when option is selected', () => {
    const onChange = jest.fn();
    const { getByText } = render(
      <GoalStep value="strength" onChange={onChange} />
    );

    fireEvent.press(getByText('Build Muscle'));
    expect(onChange).toHaveBeenCalledWith('hypertrophy');
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npm test -- app/components/onboarding/__tests__/goal-step.test.tsx`
Expected: FAIL with "Unable to find ../goal-step"

**Step 3: Write minimal implementation**

Create: `app/components/onboarding/goal-step.tsx`

```typescript
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { RadioButton } from 'react-native-paper';
import { Colors, Spacing, Typography } from '@/constants';
import type { PrimaryGoal } from '@/types';

interface GoalStepProps {
  value: PrimaryGoal;
  onChange: (goal: PrimaryGoal) => void;
}

const OPTIONS = [
  { value: 'strength' as PrimaryGoal, label: 'Build Strength' },
  { value: 'hypertrophy' as PrimaryGoal, label: 'Build Muscle' },
  { value: 'endurance' as PrimaryGoal, label: 'Improve Endurance' },
];

export function GoalStep({ value, onChange }: GoalStepProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>What do you want to achieve?</Text>
      <RadioButton.Group onValueChange={onChange} value={value}>
        {OPTIONS.map((option) => (
          <View key={option.value} style={styles.option}>
            <RadioButton value={option.value} />
            <Text style={styles.optionLabel}>{option.label}</Text>
          </View>
        ))}
      </RadioButton.Group>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    ...Typography.body,
    marginBottom: Spacing.md,
    color: Colors.text.primary,
  },
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  optionLabel: {
    ...Typography.body,
    marginLeft: Spacing.sm,
    color: Colors.text.primary,
  },
});
```

**Step 4: Run test to verify it passes**

Run: `npm test -- app/components/onboarding/__tests__/goal-step.test.tsx`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add app/components/onboarding/goal-step.tsx app/components/onboarding/__tests__/goal-step.test.tsx
git commit -m "feat: add goal selection step component

Implement radio buttons for primary training goal
Display three options: strength, hypertrophy, endurance
Pre-select strength as default option
Call onChange callback when selection changes
Add tests for rendering and selection behavior

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Update Onboarding Screen with Full Implementation

**Files:**
- Modify: `app/onboarding.tsx`
- Create: `app/__tests__/onboarding.test.tsx`

**Step 1: Write the failing integration test**

Create: `app/__tests__/onboarding.test.tsx`

```typescript
import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { useRouter } from 'expo-router';
import OnboardingScreen from '../onboarding';
import { UserProvider } from '@/contexts/user-context';
import { createUser } from '@/lib/storage/database';

jest.mock('expo-router');
jest.mock('@/lib/storage/database');

describe('Onboarding Screen', () => {
  const mockRouter = { push: jest.fn() };
  (useRouter as jest.Mock).mockReturnValue(mockRouter);
  (createUser as jest.Mock).mockResolvedValue({ id: '1', name: 'Test' });

  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <UserProvider>{children}</UserProvider>
  );

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders step 1 by default', () => {
    const { getByText, getByPlaceholderText } = render(
      <OnboardingScreen />,
      { wrapper }
    );

    expect(getByText('Welcome to Strength 💪')).toBeTruthy();
    expect(getByPlaceholderText('Enter your name')).toBeTruthy();
  });

  it('advances to step 2 when name is entered and Next pressed', async () => {
    const { getByText, getByPlaceholderText, getByRole } = render(
      <OnboardingScreen />,
      { wrapper }
    );

    const input = getByPlaceholderText('Enter your name');
    fireEvent.changeText(input, 'John');

    const nextButton = getByRole('button');
    fireEvent.press(nextButton);

    await waitFor(() => {
      expect(getByText('Training experience')).toBeTruthy();
    });
  });

  it('completes onboarding and navigates to dashboard', async () => {
    const { getByPlaceholderText, getByText, getByRole } = render(
      <OnboardingScreen />,
      { wrapper }
    );

    // Step 1: Enter name
    fireEvent.changeText(getByPlaceholderText('Enter your name'), 'John');
    fireEvent.press(getByRole('button'));

    // Step 2: Select experience (default beginner)
    await waitFor(() => {
      fireEvent.press(getByRole('button'));
    });

    // Step 3: Select goal (default strength)
    await waitFor(() => {
      const getStartedButton = getByText('Get Started');
      fireEvent.press(getStartedButton);
    });

    // Verify navigation
    await waitFor(() => {
      expect(createUser).toHaveBeenCalledWith({
        name: 'John',
        experienceLevel: 'beginner',
        primaryGoal: 'strength',
      });
      expect(mockRouter.push).toHaveBeenCalledWith('/dashboard');
    });
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npm test -- app/__tests__/onboarding.test.tsx`
Expected: FAIL (onboarding screen not implemented yet)

**Step 3: Implement onboarding screen**

Replace contents of: `app/onboarding.tsx`

```typescript
import React, { useState } from 'react';
import { View, Text, ScrollView, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Button } from '@/components/ui/button';
import { StepIndicator } from './components/onboarding/step-indicator';
import { NameStep } from './components/onboarding/name-step';
import { ExperienceStep } from './components/onboarding/experience-step';
import { GoalStep } from './components/onboarding/goal-step';
import { useUser } from '@/contexts/user-context';
import { createUser } from '@/lib/storage/database';
import { Colors, Spacing, Typography } from '@/constants';
import type { ExperienceLevel, PrimaryGoal } from '@/types';

interface OnboardingData {
  name: string;
  experienceLevel: ExperienceLevel;
  primaryGoal: PrimaryGoal;
}

export default function OnboardingScreen() {
  const router = useRouter();
  const { refresh } = useUser();
  const [currentStep, setCurrentStep] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [data, setData] = useState<OnboardingData>({
    name: '',
    experienceLevel: 'beginner',
    primaryGoal: 'strength',
  });
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const totalSteps = 3;

  function validateStep(step: number): boolean {
    const newErrors: { [key: string]: string } = {};

    if (step === 1 && !data.name.trim()) {
      newErrors.name = 'Please enter your name';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  async function handleNext() {
    if (!validateStep(currentStep)) {
      return;
    }

    if (currentStep < totalSteps) {
      setCurrentStep(currentStep + 1);
    } else {
      await handleComplete();
    }
  }

  function handleBack() {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  }

  async function handleComplete() {
    setIsLoading(true);
    try {
      await createUser({
        name: data.name,
        experienceLevel: data.experienceLevel,
        primaryGoal: data.primaryGoal,
      });
      await refresh();
      router.push('/dashboard');
    } catch (error) {
      setIsLoading(false);
      Alert.alert('Error', "Couldn't create profile. Please try again.");
    }
  }

  return (
    <View style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        <StepIndicator currentStep={currentStep} totalSteps={totalSteps} />

        {currentStep === 1 && (
          <>
            <Text style={styles.heading}>Welcome to Strength 💪</Text>
            <Text style={styles.subheading}>Let's get to know you</Text>
            <NameStep
              value={data.name}
              onChange={(name) => setData({ ...data, name })}
              error={errors.name}
            />
          </>
        )}

        {currentStep === 2 && (
          <>
            <Text style={styles.heading}>Training Experience</Text>
            <Text style={styles.subheading}>How long have you been lifting?</Text>
            <ExperienceStep
              value={data.experienceLevel}
              onChange={(experienceLevel) => setData({ ...data, experienceLevel })}
            />
          </>
        )}

        {currentStep === 3 && (
          <>
            <Text style={styles.heading}>Your Goals</Text>
            <Text style={styles.subheading}>What do you want to achieve?</Text>
            <GoalStep
              value={data.primaryGoal}
              onChange={(primaryGoal) => setData({ ...data, primaryGoal })}
            />
          </>
        )}
      </ScrollView>

      <View style={styles.footer}>
        {currentStep > 1 && (
          <Button
            mode="outlined"
            onPress={handleBack}
            style={styles.backButton}
          >
            Back
          </Button>
        )}

        <Button
          mode="contained"
          onPress={handleNext}
          disabled={isLoading}
          style={styles.nextButton}
        >
          {isLoading ? (
            <ActivityIndicator color="#fff" />
          ) : currentStep === 3 ? (
            'Get Started'
          ) : (
            'Next'
          )}
        </Button>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scrollContent: {
    flexGrow: 1,
    padding: Spacing.lg,
    paddingTop: Spacing.xl,
  },
  heading: {
    ...Typography.headingLarge,
    marginBottom: Spacing.xs,
    color: Colors.text.primary,
  },
  subheading: {
    ...Typography.body,
    marginBottom: Spacing.lg,
    color: Colors.text.secondary,
  },
  footer: {
    flexDirection: 'row',
    padding: Spacing.lg,
    gap: Spacing.md,
    backgroundColor: Colors.background,
  },
  backButton: {
    flex: 1,
  },
  nextButton: {
    flex: 2,
  },
});
```

**Step 4: Run test to verify it passes**

Run: `npm test -- app/__tests__/onboarding.test.tsx`
Expected: PASS (3 tests)

**Step 5: Verify all tests still pass**

Run: `npm test`
Expected: All tests pass (40 + new tests)

**Step 6: Commit**

```bash
git add app/onboarding.tsx app/__tests__/onboarding.test.tsx
git commit -m "feat: implement onboarding wizard with full flow

Create main onboarding screen with step management
Add state for form data, validation, and navigation
Implement step progression with Back/Next buttons
Add loading state during user creation
Handle errors with alert dialog
Complete onboarding creates user and navigates to dashboard
Add integration tests for full onboarding flow

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Run Full Test Suite and Type Check

**Step 1: Run all tests**

Run: `npm test`
Expected: All tests pass (40 existing + 12 new = 52 tests)

**Step 2: Type check**

Run: `npx tsc --noEmit`
Expected: No type errors

**Step 3: Verify app builds**

Run: `npm start`
Expected: Expo dev server starts successfully

**Step 4: Final commit**

```bash
git add -A
git commit -m "test: verify onboarding wizard implementation

All tests passing (52 tests)
TypeScript compilation successful
Expo dev server starts correctly
Ready for manual testing on device/simulator

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Verification Checklist

After implementation, manually verify:

- [ ] Onboarding screen loads on app launch (no user exists)
- [ ] Step 1: Can enter name, validation works
- [ ] Step 2: Can select experience, see default selection
- [ ] Step 3: Can select goal, see default selection
- [ ] Back button works on steps 2 and 3
- [ ] Data persists when going back
- [ ] Get Started button shows loading indicator
- [ ] Successful creation navigates to dashboard
- [ ] Error alert shows if creation fails
- [ ] Progress indicator shows correct step
- [ ] Keyboard dismisses properly
- [ ] Works on both iOS and Android

---

**Total Estimated Time:** 3-4 hours
**Test Coverage:** 12 tests (3 unit + 3 unit + 3 unit + 3 integration)
**Files Created:** 9 files
**Files Modified:** 1 file (onboarding.tsx)
**Commits:** 6 commits
