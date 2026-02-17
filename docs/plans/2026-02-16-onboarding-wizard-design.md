# Onboarding Wizard Design

**Date:** 2026-02-16
**Phase:** 3 - Onboarding & Core Flows
**Status:** Design Approved

## Overview

A 3-step full-screen stepper that collects user profile information before they can access the app. Each step fills the entire screen with a progress indicator at the top, Back/Next navigation buttons, and clear validation.

**Goals:**
- Collect essential user data (name, experience, goals)
- Create a welcoming first experience
- Guide users to dashboard with minimal friction
- Allow backward navigation for flexibility

## User Flow

```
Launch App
    ↓
Check if user exists
    ↓ (no user)
Onboarding Step 1 (Name)
    ↓ (Next)
Onboarding Step 2 (Experience)
    ↓ (Next)
Onboarding Step 3 (Goals)
    ↓ (Get Started)
Create User Profile
    ↓ (success)
Navigate to Dashboard
```

## Step-by-Step Breakdown

### Step 1: Welcome & Name

**UI Elements:**
- Progress indicator: "Step 1 of 3" (or visual: • ○ ○)
- Large heading: "Welcome to Strength 💪"
- Subheading: "Let's get to know you"
- TextInput: "What's your name?" (placeholder: "Enter your name")
- Next button: Full-width, bottom of screen (disabled until valid)

**Validation:**
- Name must not be empty (trim().length > 0)
- Show red error text below input: "Please enter your name"
- Next button disabled until validation passes

**Navigation:**
- No Back button (first step)
- Next button advances to step 2
- Keyboard: Dismiss on Next press

### Step 2: Training Experience

**UI Elements:**
- Progress indicator: "Step 2 of 3" (or visual: • • ○)
- Heading: "Training Experience"
- Subheading: "How long have you been lifting?"
- Three radio options:
  - ○ 0-1 years (Beginner)
  - ○ 1-3 years (Intermediate)
  - ○ 3+ years (Advanced)
- Back button: Left side, secondary style
- Next button: Right side, primary style (disabled until selection)

**Validation:**
- One option must be selected
- Default: Beginner pre-selected
- Next button enabled immediately

**Navigation:**
- Back button returns to step 1 (preserves name)
- Next button advances to step 3

### Step 3: Primary Goal

**UI Elements:**
- Progress indicator: "Step 3 of 3" (or visual: • • •)
- Heading: "Your Goals"
- Subheading: "What do you want to achieve?"
- Three radio options:
  - ○ Build Strength
  - ○ Build Muscle
  - ○ Improve Endurance
- Back button: Left side, secondary style
- Get Started button: Full-width, bottom (disabled until selection)

**Validation:**
- One option must be selected
- Default: Strength pre-selected
- Get Started button enabled immediately

**Navigation:**
- Back button returns to step 2 (preserves all data)
- Get Started button initiates user creation

## Completion Flow

### Success Path

1. User taps "Get Started"
2. Button shows loading spinner
3. Call `createUser()` with collected data:
   ```typescript
   await createUser({
     name: data.name,
     experienceLevel: data.experienceLevel,
     primaryGoal: data.primaryGoal
   });
   ```
4. On success: Call `refresh()` on UserContext
5. Navigate to `/dashboard` using `router.push('/dashboard')`

### Error Handling

**Validation Errors:**
- Name empty: Show red text below input
- No selection: Show error text "Please make a selection"
- Prevent step advance until valid

**Async Errors:**
- `createUser()` fails: Show alert "Couldn't create profile. Please try again."
- Network error: Same message, keep user on step 3
- Allow retry by tapping Get Started again

## Component Architecture

### File Structure

```
app/
  onboarding.tsx              # Main onboarding screen
  components/
    onboarding/
      step-indicator.tsx      # Progress indicator component
      name-step.tsx          # Step 1 - Name input
      experience-step.tsx    # Step 2 - Experience selection
      goal-step.tsx          # Step 3 - Goal selection
```

### Component Responsibilities

**onboarding.tsx (Main Container)**
- State: `currentStep` (1 | 2 | 3)
- State: `formData` object
- Validation functions per step
- Navigation handlers: `handleNext()`, `handleBack()`, `handleComplete()`
- Error handling and alerts
- Router integration

**Step Components (name-step.tsx, etc.)**
- Props: `value`, `onChange`, `error`
- Render input UI
- Local validation feedback
- Call `onChange` on user input

**step-indicator.tsx**
- Props: `currentStep`, `totalSteps`
- Render progress indicator
- Visual feedback for active step

### Data Flow

```
User Input
    ↓
Step Component onChange
    ↓
Parent State Update (formData)
    ↓
Next Button Pressed
    ↓
Parent Validates Current Step
    ↓
If Valid → Increment currentStep
    ↓
Render Next Step Component
```

## Navigation Edge Cases

### App Backgrounding
- **Behavior:** State is lost if user backgrounds app
- **Rationale:** Acceptable - onboarding is quick (<1 minute)
- **Future:** Could persist to AsyncStorage if needed

### Back Navigation
- **Step 1:** No Back button (already at start)
- **Step 2:** Back → Step 1, preserve entered data
- **Step 3:** Back → Step 2, preserve entered data

### System Back Button (Android)
- **Behavior:** Disable system back during onboarding
- **Rationale:** In-app Back buttons only for consistent UX
- **Implementation:** React Navigation back behavior

## Styling & Design

### Design Tokens

**Colors:**
- Primary: `Colors.primary` (#6366f1) - Action buttons
- Background: `Colors.background` (#ffffff)
- Text Primary: `Colors.text.primary` (#111827)
- Text Secondary: `Colors.text.secondary` (#6b7280)
- Error: `Colors.error` (#ef4444)

**Typography:**
- Heading: `Typography.headingLarge` (32px, 700)
- Subheading: `Typography.body` (16px, 400)
- Label: `Typography.body` (16px, 400)

**Spacing:**
- Screen padding: `Spacing.lg` (24px)
- Between elements: `Spacing.md` (16px)
- Button height: 48px

### Component Styles

**Progress Indicator:**
- Option A: Text "Step X of 3" - Simple, clear
- Option B: Visual dots (• ○ ○) - More engaging
- **Decision:** Implement visual dots with text label

**Buttons:**
- Primary button: Full width, 48px height, rounded (8px)
- Secondary button: Ghost style, 44px height
- Loading state: Show ActivityIndicator in button

**Inputs:**
- TextInput: 48px height, rounded border (1px)
- Focus state: Border color changes to primary
- Error state: Red border + error text below

## Accessibility

**Screen Reader:**
- All inputs have `accessibilityLabel`
- Headings marked as `accessibilityRole="header"`
- Buttons have descriptive labels
- Progress indicator announces current step

**Focus Management:**
- Auto-focus input on step mount
- Focus moves to next step on advance
- Keyboard dismisses on step change

**Touch Targets:**
- Minimum 44px height (Apple HIG)
- Radio buttons: 48px tap area
- Buttons: Full width, easy to tap

## Testing Strategy

### Unit Tests

**name-step.test.tsx**
- Renders correctly with props
- Shows error when name is empty
- Calls onChange on text input
- Dismisses keyboard on Next press

**experience-step.test.tsx**
- Renders three radio options
- Pre-selects Beginner by default
- Calls onChange with selected value
- Shows validation error if no selection

**goal-step.test.tsx**
- Renders three radio options
- Pre-selects Strength by default
- Calls onChange with selected value
- Shows validation error if no selection

**step-indicator.test.tsx**
- Renders correct number of dots
- Highlights active step
- Displays text label "Step X of 3"

### Integration Tests

**onboarding.test.tsx**
- Full flow: Start → Step 1 → Step 2 → Step 3 → Complete
- Backward navigation: Can go back and change answers
- Validation: Next disabled until valid input
- Completion: Calls createUser and navigates to dashboard
- Error handling: Shows alert on createUser failure

### E2E Tests (Detox - Phase 6)

**Complete onboarding flow**
- Launch app
- See onboarding step 1
- Enter name
- Tap Next
- Select experience
- Tap Next
- Select goal
- Tap Get Started
- Verify dashboard is displayed

**Backward navigation**
- Complete steps 1-3
- Go back to step 2
- Change selection
- Advance to step 3
- Complete onboarding
- Verify correct data saved

## Implementation Notes

### React Native Paper Components

- `TextInput` - Name input field
- `RadioButton.Group` - Experience/goal selections
- `Button` - Back/Next/Get Started
- `ActivityIndicator` - Loading spinner
- `Portal` - Error alert dialog
- `Text` - All text labels
- `View` - Layout containers

### State Management

- Local component state for form data
- UserContext for user creation
- useRouter for navigation

### Keyboard Handling

- `KeyboardAvoidingView` wrapper
- Dismiss keyboard on step change
- Auto-focus next input (if applicable)

### Platform Considerations

**iOS:**
- Use iOS-style back button chevron
- Smooth transitions between steps
- Native-feeling animations

**Android:**
- Disable system back button
- Material Design ripple effects
- Adjust padding for navigation bar

## Success Criteria

✅ User can complete onboarding in <60 seconds
✅ All validation works correctly
✅ Backward navigation preserves data
✅ Errors are handled gracefully
✅ Created user appears in dashboard
✅ Accessibility standards met
✅ Works on both iOS and Android

## Next Steps

1. ✅ Design approved
2. ⏭️ Create implementation plan with detailed tasks
3. ⏭️ Implement step components
4. ⏭️ Implement main onboarding container
5. ⏭️ Write tests
6. ⏭️ Test on physical devices
7. ⏭️ Move to next feature (Dashboard)

---

**Design Status:** ✅ Approved
**Ready for Implementation:** Yes
**Estimated Implementation Time:** 3-4 hours
