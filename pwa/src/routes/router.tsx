/**
 * React Router configuration — all routes with lazy loading.
 * Layouts and Dashboard are eagerly loaded; all other screens use React.lazy().
 */
import { lazy, Suspense } from 'react';
import { createBrowserRouter } from 'react-router';
import { RootLayout } from './RootLayout';
import { AppLayout } from './AppLayout';
import { Dashboard } from './Dashboard';
import { RootErrorBoundary } from './RootErrorBoundary';
import { AppErrorBoundary } from './AppErrorBoundary';

// ─── Lazy-loaded route components ────────────────────────────────────────────

const SignIn = lazy(() => import('./SignIn').then((m) => ({ default: m.SignIn })));
const VerifyEmail = lazy(() => import('./VerifyEmail').then((m) => ({ default: m.VerifyEmail })));
const Onboarding = lazy(() => import('./Onboarding').then((m) => ({ default: m.Onboarding })));
const History = lazy(() => import('./History').then((m) => ({ default: m.History })));
const Maxes = lazy(() => import('./Maxes').then((m) => ({ default: m.Maxes })));
const Cycle = lazy(() => import('./Cycle').then((m) => ({ default: m.Cycle })));
const Settings = lazy(() => import('./Settings').then((m) => ({ default: m.Settings })));
const Programs = lazy(() => import('./Programs').then((m) => ({ default: m.Programs })));
const ProgramDetail = lazy(() => import('./ProgramDetail').then((m) => ({ default: m.ProgramDetail })));
const ProgramSessionScreen = lazy(() => import('./ProgramSession').then((m) => ({ default: m.ProgramSessionScreen })));
const WorkoutSessionScreen = lazy(() => import('./WorkoutSession').then((m) => ({ default: m.WorkoutSessionScreen })));
const WorkoutDetail = lazy(() => import('./WorkoutDetail').then((m) => ({ default: m.WorkoutDetail })));
const AIWorkoutConfig = lazy(() => import('./AIWorkoutConfig').then((m) => ({ default: m.AIWorkoutConfig })));
const AIWorkoutPreview = lazy(() => import('./AIWorkoutPreview').then((m) => ({ default: m.AIWorkoutPreview })));
const Benchmarks = lazy(() => import('./Benchmarks').then((m) => ({ default: m.Benchmarks })));
const BenchmarkDetail = lazy(() => import('./BenchmarkDetail').then((m) => ({ default: m.BenchmarkDetail })));
const BenchmarkCreate = lazy(() => import('./BenchmarkCreate').then((m) => ({ default: m.BenchmarkCreate })));
const Injuries = lazy(() => import('./Injuries').then((m) => ({ default: m.Injuries })));
const InjuryDetail = lazy(() => import('./InjuryDetail').then((m) => ({ default: m.InjuryDetail })));
const BodyMap = lazy(() => import('./BodyMap').then((m) => ({ default: m.BodyMap })));
const WODs = lazy(() => import('./WODs').then((m) => ({ default: m.WODs })));
const ExerciseDetail = lazy(() => import('./ExerciseDetail').then((m) => ({ default: m.ExerciseDetail })));
const Goodbye = lazy(() => import('./Goodbye').then((m) => ({ default: m.Goodbye })));
const NotFound = lazy(() => import('./NotFound').then((m) => ({ default: m.NotFound })));

// ─── Suspense wrapper ────────────────────────────────────────────────────────

function LazyFallback() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: 48 }}>
      <div style={{
        width: 24, height: 24,
        border: '3px solid var(--border)',
        borderTopColor: 'var(--accent)',
        borderRadius: '50%',
        animation: 'spin 0.8s linear infinite',
      }} />
    </div>
  );
}

function L({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<LazyFallback />}>{children}</Suspense>;
}

// ─── Router ──────────────────────────────────────────────────────────────────

export const router = createBrowserRouter([
  {
    element: <RootLayout />,
    ErrorBoundary: RootErrorBoundary,
    children: [
      // Auth screens
      { path: '/sign-in', element: <L><SignIn /></L> },
      { path: '/verify-email', element: <L><VerifyEmail /></L> },

      // Onboarding
      { path: '/onboarding', element: <L><Onboarding /></L> },
      { path: '/onboarding/:step', element: <L><Onboarding /></L> },

      // Authenticated app (auth guard in AppLayout)
      {
        element: <AppLayout />,
        ErrorBoundary: AppErrorBoundary,
        children: [
          // Tab screens (Dashboard eager, rest lazy)
          { index: true, element: <Dashboard /> },
          { path: 'history', element: <L><History /></L> },
          { path: 'maxes', element: <L><Maxes /></L> },
          { path: 'cycle', element: <L><Cycle /></L> },
          { path: 'settings', element: <L><Settings /></L> },

          // Workout
          { path: 'workout-session', element: <L><WorkoutSessionScreen /></L> },
          { path: 'workout/:id', element: <L><WorkoutDetail /></L> },

          // Programs
          { path: 'programs', element: <L><Programs /></L> },
          { path: 'programs/:id', element: <L><ProgramDetail /></L> },
          { path: 'programs/session', element: <L><ProgramSessionScreen /></L> },

          // Benchmarks
          { path: 'benchmarks', element: <L><Benchmarks /></L> },
          { path: 'benchmarks/create', element: <L><BenchmarkCreate /></L> },
          { path: 'benchmarks/:id', element: <L><BenchmarkDetail /></L> },

          // Injuries
          { path: 'injuries', element: <L><Injuries /></L> },
          { path: 'injuries/body-map', element: <L><BodyMap /></L> },
          { path: 'injuries/:id', element: <L><InjuryDetail /></L> },

          // AI Workout
          { path: 'ai-workout/config', element: <L><AIWorkoutConfig /></L> },
          { path: 'ai-workout/preview', element: <L><AIWorkoutPreview /></L> },

          // WODs
          { path: 'wods', element: <L><WODs /></L> },

          // Exercises
          { path: 'exercises/:id', element: <L><ExerciseDetail /></L> },

          // Account
          { path: 'goodbye', element: <L><Goodbye /></L> },
        ],
      },

      // Catch-all 404 — sibling of AppLayout so unauthenticated users see 404, not sign-in redirect
      { path: '*', element: <L><NotFound /></L> },
    ],
  },
]);
