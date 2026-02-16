# Visual Polish Design: Animations & Transitions

**Date:** 2026-02-16
**Status:** Approved
**Goal:** Enhance the user experience with meaningful animations, smooth transitions, and tactile feedback to make the app feel "native" and polished.

---

## 1. Core Architecture

### Library Strategy
- **Primary Engine:** `framer-motion` (v12+) for React component transitions.
- **Micro-interactions:** `framer-motion` (shared layout animations).
- **Celebrations:** `canvas-confetti` for lightweight particle effects.
- **Utilities:** `clsx` / `tailwind-merge` for class composition.

### Configuration (`src/lib/animations.ts`)
Centralize all timing, easing, and variants to ensure consistency.

```typescript
export const TRANSITION_DEFAULTS = {
  duration: 0.3,
  ease: [0.25, 0.1, 0.25, 1], // Cubic bezier for natural feel
};

export const VARIANTS = {
  fadeIn: {
    initial: { opacity: 0, y: 10 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -10 },
  },
  scalePress: {
    tap: { scale: 0.96 },
    hover: { scale: 1.02 },
  },
};
```

### Accessibility
- Use `framer-motion`'s `useReducedMotion()` hook.
- If reduced motion is enabled:
  - Slide/scale animations -> Fade only.
  - Duration -> 0 (instant) or very fast fade.

---

## 2. Page Transitions

### Strategy
Use `src/app/template.tsx` instead of `layout.tsx` to mount/unmount components on route changes.

### Component: `<PageTransition>`
Wraps page content to provide a seamless navigation experience.

**Behavior:**
- **Mount:** Fade in from 95% opacity + Slide up 10px.
- **Exit:** Fade out to 0% opacity.
- **Key:** `pathname` ensures unique instances per route.

```tsx
// src/app/template.tsx
<AnimatePresence mode="wait">
  <motion.div
    key={pathname}
    initial="initial"
    animate="animate"
    exit="exit"
    variants={VARIANTS.pageTransition}
  >
    {children}
  </motion.div>
</AnimatePresence>
```

---

## 3. Reusable Interaction Components

### 3.1 `<FadeIn>`
A general-purpose wrapper for entering content (charts, cards, sections).
- **Props:** `delay`, `duration`, `direction` (up/down/left/right).
- **Usage:** Wrap dashboard widgets so they load smoothly.

### 3.2 `<StaggerList>` & `<StaggerItem>`
Orchestrates lists so items appear sequentially rather than all at once.
- **Usage:** Program list, Exercise list in workout view.
- **Timing:** 0.05s delay per item.

### 3.3 `<ScaleButton>` / `<ScaleCard>`
Wraps interactive elements to give tactile feedback.
- **Behavior:** Scales down to 0.96 on press.
- **Usage:** "Start Workout" button, Program selection cards.

### 3.4 `<AnimatedCheck>`
SVG path animation for success states.
- **Usage:** Completing a set or finishing a workout.
- **Animation:** Path length 0 -> 1.

---

## 4. Delightful Moments

### 4.1 Workout Completion (Confetti)
- **Library:** `canvas-confetti`
- **Hook:** `useConfetti()`
- **Trigger:** Clicking "Complete Workout" on summary screen.
- **Effect:** Explosion from center-bottom.

### 4.2 PR Celebration
- **Visual:** Shimmer/shine effect on the "PR" badge.
- **Trigger:** When `isPersonalRecord` returns true.
- **Implementation:** CSS keyframe animation `animate-shimmer` via Tailwind.

### 4.3 Loading States
- **Visual:** Smooth pulse/wave on Skeletons.
- **Enhancement:** Cross-fade from Skeleton to Content (no layout shift).

---

## 5. Implementation Plan

### Phase 1: Foundation
1. Install `framer-motion` and `canvas-confetti`.
2. Create `src/lib/animations.ts` with tokens.
3. Create `src/components/animations/` directory.

### Phase 2: Core Components
1. Build `<PageTransition>` and add to `template.tsx`.
2. Build `<FadeIn>`, `<StaggerList>`, `<ScaleButton>`.

### Phase 3: Integration
1. Apply `<PageTransition>` to all routes.
2. Wrap Dashboard cards in `<StaggerList>`.
3. Wrap Workout exercises in `<StaggerList>`.
4. Replace standard Buttons with `<ScaleButton>` where appropriate.

### Phase 4: Delight
1. Create `useConfetti` hook.
2. Integrate confetti on "Complete Workout" action.
3. Add PR shimmer effect.

---

## 6. Testing Strategy
- **Unit Tests:** Verify hooks return expected values.
- **Visual/Manual:** Check animations on:
  - Mobile (performance check).
  - Desktop (layout stability).
  - Reduced Motion enabled (verify animations disabled).
