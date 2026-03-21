/**
 * React Router configuration — maps all Sundee Fundee routes.
 */
import { createBrowserRouter } from 'react-router';
import { RootLayout } from './RootLayout';
import { AppLayout } from './AppLayout';
import { SignIn } from './SignIn';
import { VerifyEmail } from './VerifyEmail';
import { Onboarding } from './Onboarding';
import { Dashboard } from './Dashboard';
import { History } from './History';
import { Maxes } from './Maxes';
import { Cycle } from './Cycle';
import { Programs } from './Programs';
import { ProgramDetail } from './ProgramDetail';
import { WorkoutSessionScreen } from './WorkoutSession';
import { AIWorkoutConfig } from './AIWorkoutConfig';
import { AIWorkoutPreview } from './AIWorkoutPreview';
import { Benchmarks } from './Benchmarks';
import { Settings } from './Settings';

// Placeholder component for routes not yet migrated
function Placeholder({ name }: { name: string }) {
  return (
    <div style={{ padding: 24 }}>
      <h2>{name}</h2>
      <p>This screen is being migrated to the PWA.</p>
    </div>
  );
}

export const router = createBrowserRouter([
  {
    element: <RootLayout />,
    children: [
      // Auth screens
      { path: '/sign-in', element: <SignIn /> },
      { path: '/verify-email', element: <VerifyEmail /> },

      // Onboarding (single multi-step wizard page)
      { path: '/onboarding', element: <Onboarding /> },
      { path: '/onboarding/:step', element: <Onboarding /> },

      // Authenticated app (auth guard in AppLayout)
      {
        element: <AppLayout />,
        children: [
          // Tab screens
          { index: true, element: <Dashboard /> },
          { path: 'history', element: <History /> },
          { path: 'maxes', element: <Maxes /> },
          { path: 'cycle', element: <Cycle /> },
          { path: 'settings', element: <Settings /> },

          // Workout
          { path: 'workout-session', element: <WorkoutSessionScreen /> },
          { path: 'workout/:id', element: <Placeholder name="Workout Detail" /> },
          { path: 'workout/timer', element: <Placeholder name="Timer Mode" /> },

          // Programs
          { path: 'programs', element: <Programs /> },
          { path: 'programs/:id', element: <ProgramDetail /> },
          { path: 'programs/session', element: <Placeholder name="Program Session" /> },

          // Benchmarks
          { path: 'benchmarks', element: <Benchmarks /> },
          { path: 'benchmarks/create', element: <Placeholder name="Create Benchmark" /> },
          { path: 'benchmarks/:id', element: <Placeholder name="Benchmark Detail" /> },

          // Injuries
          { path: 'injuries', element: <Placeholder name="Injuries" /> },
          { path: 'injuries/body-map', element: <Placeholder name="Body Map" /> },
          { path: 'injuries/:id', element: <Placeholder name="Injury Detail" /> },

          // AI Workout
          { path: 'ai-workout/config', element: <AIWorkoutConfig /> },
          { path: 'ai-workout/preview', element: <AIWorkoutPreview /> },

          // WODs
          { path: 'wods', element: <Placeholder name="WODs" /> },

          // Exercises
          { path: 'exercises/:id', element: <Placeholder name="Exercise Detail" /> },
          { path: 'exercises/pick', element: <Placeholder name="Exercise Picker" /> },

          // Account
          { path: 'goodbye', element: <Placeholder name="Goodbye" /> },
        ],
      },
    ],
  },
]);
