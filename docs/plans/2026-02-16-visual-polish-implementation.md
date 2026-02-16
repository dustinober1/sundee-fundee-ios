# Visual Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enhance the user experience with meaningful animations, smooth transitions, and tactile feedback to make the app feel "native" and polished.

**Architecture:** Use `framer-motion` for React component transitions and `canvas-confetti` for celebrations. Centralize animation tokens in `src/lib/animations.ts` and use reusable wrapper components (`PageTransition`, `FadeIn`, `ScaleButton`) to ensure consistency.

**Tech Stack:** framer-motion, canvas-confetti, clsx, tailwind-merge

---

### Task 1: Animation Foundation

**Files:**
- Run: `pnpm add framer-motion canvas-confetti && pnpm add -D @types/canvas-confetti`
- Create: `src/lib/animations.ts`
- Create: `src/components/animations/index.ts`
- Create: `tests/unit/animations/config.test.ts`

**Step 1: Write the test for animation config**

```typescript
import { describe, it, expect } from 'vitest';
import { TRANSITION_DEFAULTS, VARIANTS } from '@/lib/animations';

describe('Animation Config', () => {
  it('has default transition settings', () => {
    expect(TRANSITION_DEFAULTS.duration).toBe(0.3);
    expect(Array.isArray(TRANSITION_DEFAULTS.ease)).toBe(true);
  });

  it('defines fade in variants', () => {
    expect(VARIANTS.fadeIn.initial.opacity).toBe(0);
    expect(VARIANTS.fadeIn.animate.opacity).toBe(1);
  });

  it('defines scale press variants', () => {
    expect(VARIANTS.scalePress.tap.scale).toBeLessThan(1);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `pnpm vitest run tests/unit/animations/config.test.ts`
Expected: FAIL (module not found)

**Step 3: Install dependencies**

Run: `pnpm add framer-motion canvas-confetti && pnpm add -D @types/canvas-confetti`

**Step 4: Create animation configuration**

Create: `src/lib/animations.ts`

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
    transition: TRANSITION_DEFAULTS,
  },
  pageTransition: {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -20 },
    transition: { ...TRANSITION_DEFAULTS, duration: 0.4 },
  },
  scalePress: {
    tap: { scale: 0.96 },
    hover: { scale: 1.02 },
    transition: { duration: 0.1 },
  },
  staggerContainer: {
    animate: {
      transition: {
        staggerChildren: 0.05,
      },
    },
  },
  staggerItem: {
    initial: { opacity: 0, y: 10 },
    animate: { opacity: 1, y: 0 },
    transition: TRANSITION_DEFAULTS,
  },
};
```

Create: `src/components/animations/index.ts` (empty export for now)

```typescript
// Export animation components here
```

**Step 5: Run test to verify it passes**

Run: `pnpm vitest run tests/unit/animations/config.test.ts`
Expected: PASS

**Step 6: Commit**

```bash
git add src/lib/animations.ts src/components/animations/ tests/unit/animations/ package.json pnpm-lock.yaml
git commit -m "feat: setup animation foundation with framer-motion"
```

---

### Task 2: Page Transitions

**Files:**
- Create: `src/components/animations/page-transition.tsx`
- Create: `src/app/template.tsx`
- Modify: `src/components/animations/index.ts`

**Step 1: Create PageTransition component**

Create: `src/components/animations/page-transition.tsx`

```typescript
'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { ReactNode } from 'react';

interface PageTransitionProps {
  children: ReactNode;
  className?: string;
}

export function PageTransition({ children, className }: PageTransitionProps) {
  return (
    <motion.div
      initial="initial"
      animate="animate"
      exit="exit"
      variants={VARIANTS.pageTransition}
      className={className}
    >
      {children}
    </motion.div>
  );
}
```

**Step 2: Export from index**

Modify: `src/components/animations/index.ts`

```typescript
export * from './page-transition';
```

**Step 3: Create template for route transitions**

Create: `src/app/template.tsx`

```typescript
'use client';

import { PageTransition } from '@/components/animations/page-transition';
import { AnimatePresence } from 'framer-motion';
import { usePathname } from 'next/navigation';

export default function Template({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <AnimatePresence mode="wait">
      <PageTransition key={pathname}>
        {children}
      </PageTransition>
    </AnimatePresence>
  );
}
```

**Step 4: Manual Verification (Since visual test)**

Run: `pnpm dev`
Action: Navigate between Dashboard and Programs.
Expected: Content should fade in and slide up slightly.

**Step 5: Commit**

```bash
git add src/components/animations/page-transition.tsx src/components/animations/index.ts src/app/template.tsx
git commit -m "feat: add page transitions"
```

---

### Task 3: Interaction Components

**Files:**
- Create: `src/components/animations/fade-in.tsx`
- Create: `src/components/animations/scale-button.tsx`
- Create: `src/components/animations/stagger-list.tsx`
- Modify: `src/components/animations/index.ts`
- Test: `tests/unit/animations/components.test.tsx`

**Step 1: Create FadeIn component**

Create: `src/components/animations/fade-in.tsx`

```typescript
'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { ReactNode } from 'react';

interface FadeInProps {
  children: ReactNode;
  delay?: number;
  className?: string;
}

export function FadeIn({ children, delay = 0, className }: FadeInProps) {
  return (
    <motion.div
      initial="initial"
      animate="animate"
      variants={VARIANTS.fadeIn}
      transition={{ delay }}
      className={className}
    >
      {children}
    </motion.div>
  );
}
```

**Step 2: Create ScaleButton component**

Create: `src/components/animations/scale-button.tsx`

```typescript
'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { Button, ButtonProps } from '@/components/ui/button';
import { forwardRef } from 'react';

export const ScaleButton = forwardRef<HTMLButtonElement, ButtonProps>(
  (props, ref) => {
    return (
      <motion.div
        whileTap="tap"
        whileHover="hover"
        variants={VARIANTS.scalePress}
        className="inline-block" // Ensure wrapper doesn't break layout
      >
        <Button ref={ref} {...props} />
      </motion.div>
    );
  }
);
ScaleButton.displayName = 'ScaleButton';
```

**Step 3: Create StaggerList components**

Create: `src/components/animations/stagger-list.tsx`

```typescript
'use client';

import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';
import { ReactNode } from 'react';

export function StaggerList({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <motion.div
      initial="initial"
      animate="animate"
      variants={VARIANTS.staggerContainer}
      className={className}
    >
      {children}
    </motion.div>
  );
}

export function StaggerItem({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <motion.div variants={VARIANTS.staggerItem} className={className}>
      {children}
    </motion.div>
  );
}
```

**Step 4: Export all**

Modify: `src/components/animations/index.ts`

```typescript
export * from './page-transition';
export * from './fade-in';
export * from './scale-button';
export * from './stagger-list';
```

**Step 5: Write smoke tests**

Create: `tests/unit/animations/components.test.tsx`

```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { FadeIn, ScaleButton, StaggerList, StaggerItem } from '@/components/animations';

describe('Animation Components', () => {
  it('renders FadeIn content', () => {
    render(<FadeIn>Test Content</FadeIn>);
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('renders ScaleButton content', () => {
    render(<ScaleButton>Click Me</ScaleButton>);
    expect(screen.getByText('Click Me')).toBeInTheDocument();
  });

  it('renders StaggerList content', () => {
    render(
      <StaggerList>
        <StaggerItem>Item 1</StaggerItem>
        <StaggerItem>Item 2</StaggerItem>
      </StaggerList>
    );
    expect(screen.getByText('Item 1')).toBeInTheDocument();
    expect(screen.getByText('Item 2')).toBeInTheDocument();
  });
});
```

**Step 6: Run tests**

Run: `pnpm vitest run tests/unit/animations/components.test.tsx`
Expected: PASS

**Step 7: Commit**

```bash
git add src/components/animations/ tests/unit/animations/
git commit -m "feat: add interaction components (FadeIn, ScaleButton, StaggerList)"
```

---

### Task 4: Integrate Animations into Dashboard

**Files:**
- Modify: `src/app/dashboard/page.tsx`
- Modify: `src/components/dashboard/active-cycles-card.tsx`

**Step 1: Wrap dashboard content**

Modify: `src/app/dashboard/page.tsx`

```typescript
import { ActiveCyclesCard } from '@/components/dashboard/active-cycles-card';
import { FadeIn, StaggerList, StaggerItem } from '@/components/animations';

export default function DashboardPage() {
  return (
    <div className="min-h-screen p-4 pb-20">
      <FadeIn>
        <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      </FadeIn>

      <StaggerList className="space-y-4">
        <StaggerItem>
          <ActiveCyclesCard />
        </StaggerItem>
        {/* Future widgets will be added here as StaggerItems */}
      </StaggerList>
    </div>
  );
}
```

**Step 2: Update ActiveCyclesCard to use ScaleButton if actions exist**
(No actions yet, so just ensuring the card itself animates nicely within the list)

**Step 3: Commit**

```bash
git add src/app/dashboard/page.tsx
git commit -m "refactor: apply animations to dashboard"
```

---

### Task 5: Integrate Animations into Program Browser

**Files:**
- Modify: `src/app/programs/page.tsx`
- Modify: `src/components/programs/program-card.tsx`

**Step 1: Wrap program list**

Modify: `src/app/programs/page.tsx`

```typescript
import { useExercise } from '@/contexts/exercise-context';
import { ProgramCard } from '@/components/programs/program-card';
import { FadeIn, StaggerList, StaggerItem } from '@/components/animations';

export default function ProgramsPage() {
  const { programs } = useExercise();

  return (
    <div className="min-h-screen p-4 pb-20">
      <FadeIn>
        <h1 className="text-2xl font-bold mb-4">Workout Programs</h1>
      </FadeIn>

      <StaggerList className="space-y-6">
        {programs.map(program => (
          <StaggerItem key={program.id}>
            <ProgramCard program={program} />
          </StaggerItem>
        ))}
      </StaggerList>
    </div>
  );
}
```

**Step 2: Add hover effect to ProgramCard**

Modify: `src/components/programs/program-card.tsx`

```typescript
'use client';

import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import type { Program } from '@/types';
import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';

interface ProgramCardProps {
  program: Program;
}

export function ProgramCard({ program }: ProgramCardProps) {
  return (
    <Link href={`/programs/${program.id}`}>
      <motion.div
        whileHover="hover"
        whileTap="tap"
        variants={VARIANTS.scalePress}
      >
        <Card className="h-full hover:shadow-md transition-shadow">
          <CardHeader>
            <div className="flex justify-between items-start">
              <CardTitle className="text-lg">{program.name}</CardTitle>
              <Badge variant="secondary">{program.difficulty}</Badge>
            </div>
            <CardDescription>{program.description}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-sm text-muted-foreground">
              {program.durationWeeks} weeks • {program.daysPerWeek} days/week
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </Link>
  );
}
```

**Step 3: Commit**

```bash
git add src/app/programs/page.tsx src/components/programs/program-card.tsx
git commit -m "refactor: apply animations to program browser"
```

---

### Task 6: Confetti Celebration Hook

**Files:**
- Create: `src/hooks/use-confetti.ts`
- Test: `tests/unit/hooks/use-confetti.test.ts`
- Modify: `src/app/workout/[id]/page.tsx`

**Step 1: Create useConfetti hook**

Create: `src/hooks/use-confetti.ts`

```typescript
import confetti from 'canvas-confetti';
import { useCallback } from 'react';

export function useConfetti() {
  const fireConfetti = useCallback(() => {
    const duration = 3000;
    const end = Date.now() + duration;

    // Launch confetti from bottom center
    confetti({
      particleCount: 100,
      spread: 70,
      origin: { y: 0.8 },
      colors: ['#26ccff', '#a25afd', '#ff5e7e', '#88ff5a', '#fcff42', '#ffa62d', '#ff36ff']
    });

    // Add a few random bursts
    const interval: any = setInterval(function() {
      if (Date.now() > end) {
        return clearInterval(interval);
      }

      confetti({
        startVelocity: 30,
        spread: 360,
        ticks: 60,
        origin: {
          x: Math.random() * (0.7 - 0.3) + 0.3,
          y: Math.random() - 0.2
        },
        colors: ['#26ccff', '#a25afd', '#ff5e7e', '#88ff5a', '#fcff42', '#ffa62d', '#ff36ff']
      });
    }, 250);
  }, []);

  return { fireConfetti };
}
```

**Step 2: Smoke test for hook (basic rendering)**

Create: `tests/unit/hooks/use-confetti.test.ts`

```typescript
import { describe, it, expect, vi } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useConfetti } from '@/hooks/use-confetti';

// Mock canvas-confetti
vi.mock('canvas-confetti', () => ({
  default: vi.fn(),
}));

describe('useConfetti', () => {
  it('returns fireConfetti function', () => {
    const { result } = renderHook(() => useConfetti());
    expect(typeof result.current.fireConfetti).toBe('function');
  });
});
```

**Step 3: Run test**

Run: `pnpm vitest run tests/unit/hooks/use-confetti.test.ts`
Expected: PASS

**Step 4: Integrate into Workout Page**

Modify: `src/app/workout/[id]/page.tsx`

```typescript
import { useExercise } from '@/contexts/exercise-context';
import { ExerciseCard } from '@/components/workout/exercise-card';
import { ScaleButton } from '@/components/animations';
import { FadeIn, StaggerList, StaggerItem } from '@/components/animations';
import { useConfetti } from '@/hooks/use-confetti';

interface PageProps {
  params: { id: string };
}

export default function WorkoutPage({ params }: PageProps) {
  const { getProgram } = useExercise();
  const { fireConfetti } = useConfetti();
  const program = getProgram(params.id);

  if (!program) {
    return <div>Program not found</div>;
  }

  // For MVP, showing week 1, day 1
  const workout = program.weeks[0]?.days[0];

  const handleComplete = () => {
    fireConfetti();
    // TODO: Add actual completion logic here
  };

  return (
    <div className="min-h-screen p-4 pb-20">
      <FadeIn>
        <h1 className="text-2xl font-bold mb-4">Today's Workout</h1>
        <p className="text-muted-foreground mb-4">{program.name}</p>
      </FadeIn>

      <StaggerList className="space-y-4">
        {workout?.exercises.map(exercise => (
          <StaggerItem key={exercise.exercise}>
            <ExerciseCard
              exercise={exercise}
              prescribedWeight={195} // TODO: Calculate from user's 1RM
            />
          </StaggerItem>
        ))}
      </StaggerList>

      <FadeIn delay={0.5}>
        <div className="mt-6">
          <ScaleButton
            className="w-full"
            size="lg"
            onClick={handleComplete}
          >
            Complete Workout
          </ScaleButton>
        </div>
      </FadeIn>
    </div>
  );
}
```

**Step 5: Commit**

```bash
git add src/hooks/use-confetti.ts tests/unit/hooks/use-confetti.test.ts src/app/workout/[id]/page.tsx
git commit -m "feat: add confetti celebration on workout completion"
```

---

### Task 7: Final Polish & Verification

**Files:**
- Modify: `src/app/globals.css` (for global scroll behavior)

**Step 1: Smooth scrolling**

Modify: `src/app/globals.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    scroll-behavior: smooth;
  }
}

/* ... rest of file */
```

**Step 2: Manual Verification Walkthrough**
- Check dashboard loading animation.
- Navigate to Programs (page transition).
- Click a program (scale animation).
- Navigate to Workout (page transition).
- See exercises stagger in.
- Click "Complete Workout" -> Confetti explosion.

**Step 3: Commit**

```bash
git add src/app/globals.css
git commit -m "style: enable global smooth scrolling"
```
