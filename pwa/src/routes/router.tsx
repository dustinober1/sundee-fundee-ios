/**
 * React Router configuration — maps all Sundee Fundee routes.
 *
 * Route structure mirrors the existing Expo Router file layout:
 *   /sign-in, /verify-email
 *   /onboarding/*
 *   / (dashboard), /history, /maxes, /cycle, /settings
 *   /workout, /workout/:id, /workout/timer
 *   /programs, /programs/:id, /programs/:id/session
 *   /benchmarks, /benchmarks/create, /benchmarks/:id
 *   /injuries, /injuries/body-map, /injuries/:id
 *   /ai-workout, /ai-workout/preview
 *   /wods
 *   /exercises/:id, /exercises/pick
 *   /goodbye
 */
import { createBrowserRouter } from 'react-router';
import { RootLayout } from './RootLayout';
import { AppLayout } from './AppLayout';

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
      { path: '/sign-in', element: <Placeholder name="Sign In" /> },
      { path: '/verify-email', element: <Placeholder name="Verify Email" /> },

      // Onboarding
      { path: '/onboarding/name', element: <Placeholder name="Onboarding: Name" /> },
      { path: '/onboarding/experience', element: <Placeholder name="Onboarding: Experience" /> },
      { path: '/onboarding/goal', element: <Placeholder name="Onboarding: Goal" /> },
      { path: '/onboarding/gender', element: <Placeholder name="Onboarding: Gender" /> },
      { path: '/onboarding/cycle', element: <Placeholder name="Onboarding: Cycle" /> },

      // Authenticated app (auth guard in AppLayout)
      {
        element: <AppLayout />,
        children: [
          // Tab screens
          { index: true, element: <Placeholder name="Dashboard" /> },
          { path: 'history', element: <Placeholder name="History" /> },
          { path: 'maxes', element: <Placeholder name="Maxes" /> },
          { path: 'cycle', element: <Placeholder name="Cycle" /> },
          { path: 'settings', element: <Placeholder name="Settings" /> },

          // Workout
          { path: 'workout', element: <Placeholder name="Workout Session" /> },
          { path: 'workout/:id', element: <Placeholder name="Workout Detail" /> },
          { path: 'workout/timer', element: <Placeholder name="Timer Mode" /> },

          // Programs
          { path: 'programs', element: <Placeholder name="Programs" /> },
          { path: 'programs/:id', element: <Placeholder name="Program Detail" /> },
          { path: 'programs/:id/session', element: <Placeholder name="Program Session" /> },

          // Benchmarks
          { path: 'benchmarks', element: <Placeholder name="Benchmarks" /> },
          { path: 'benchmarks/create', element: <Placeholder name="Create Benchmark" /> },
          { path: 'benchmarks/:id', element: <Placeholder name="Benchmark Detail" /> },

          // Injuries
          { path: 'injuries', element: <Placeholder name="Injuries" /> },
          { path: 'injuries/body-map', element: <Placeholder name="Body Map" /> },
          { path: 'injuries/:id', element: <Placeholder name="Injury Detail" /> },

          // AI Workout
          { path: 'ai-workout', element: <Placeholder name="AI Workout Config" /> },
          { path: 'ai-workout/preview', element: <Placeholder name="AI Workout Preview" /> },

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
