/**
 * React Router configuration — maps all Sundee Fundee routes.
 * All 41 routes now have real implementations.
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
import { ProgramSessionScreen } from './ProgramSession';
import { WorkoutSessionScreen } from './WorkoutSession';
import { WorkoutDetail } from './WorkoutDetail';
import { AIWorkoutConfig } from './AIWorkoutConfig';
import { AIWorkoutPreview } from './AIWorkoutPreview';
import { Benchmarks } from './Benchmarks';
import { BenchmarkDetail } from './BenchmarkDetail';
import { BenchmarkCreate } from './BenchmarkCreate';
import { Injuries } from './Injuries';
import { InjuryDetail } from './InjuryDetail';
import { BodyMap } from './BodyMap';
import { WODs } from './WODs';
import { ExerciseDetail } from './ExerciseDetail';
import { Goodbye } from './Goodbye';
import { Settings } from './Settings';

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
          { path: 'workout/:id', element: <WorkoutDetail /> },

          // Programs
          { path: 'programs', element: <Programs /> },
          { path: 'programs/:id', element: <ProgramDetail /> },
          { path: 'programs/session', element: <ProgramSessionScreen /> },

          // Benchmarks
          { path: 'benchmarks', element: <Benchmarks /> },
          { path: 'benchmarks/create', element: <BenchmarkCreate /> },
          { path: 'benchmarks/:id', element: <BenchmarkDetail /> },

          // Injuries
          { path: 'injuries', element: <Injuries /> },
          { path: 'injuries/body-map', element: <BodyMap /> },
          { path: 'injuries/:id', element: <InjuryDetail /> },

          // AI Workout
          { path: 'ai-workout/config', element: <AIWorkoutConfig /> },
          { path: 'ai-workout/preview', element: <AIWorkoutPreview /> },

          // WODs
          { path: 'wods', element: <WODs /> },

          // Exercises
          { path: 'exercises/:id', element: <ExerciseDetail /> },

          // Account
          { path: 'goodbye', element: <Goodbye /> },
        ],
      },
    ],
  },
]);
