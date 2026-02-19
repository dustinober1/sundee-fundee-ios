-- Supabase schema for Strength app
-- Run this in the Supabase SQL editor to set up tables and Row Level Security.
-- All tables scope data to the authenticated user via user_id = auth.uid().

-- ─────────────────────────────────────────────
-- Users (profile data beyond auth.users)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name          text NOT NULL,
  experience_level text NOT NULL CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  primary_goal  text NOT NULL CHECK (primary_goal IN ('strength', 'hypertrophy', 'explosiveness')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  synced_at     timestamptz,
  updated_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users: owner access" ON public.users
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ─────────────────────────────────────────────
-- One Rep Maxes
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.one_rep_maxes (
  id            uuid PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id   text NOT NULL,
  weight        numeric NOT NULL,
  date          timestamptz NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.one_rep_maxes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "OneRepMaxes: owner access" ON public.one_rep_maxes
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS one_rep_maxes_user_exercise ON public.one_rep_maxes (user_id, exercise_id);
CREATE INDEX IF NOT EXISTS one_rep_maxes_date ON public.one_rep_maxes (user_id, date DESC);

-- ─────────────────────────────────────────────
-- Active Cycles (training program cycles)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.active_cycles (
  id                  uuid PRIMARY KEY,
  user_id             uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  program_id          text NOT NULL,
  cycle_name          text NOT NULL,
  start_date          timestamptz NOT NULL,
  current_week        integer NOT NULL DEFAULT 1,
  current_session_id  text,
  current_phase       text,
  status              text NOT NULL CHECK (status IN ('active', 'completed', 'paused')),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.active_cycles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ActiveCycles: owner access" ON public.active_cycles
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS active_cycles_user_status ON public.active_cycles (user_id, status);

-- ─────────────────────────────────────────────
-- Completed Workouts
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.completed_workouts (
  id              uuid PRIMARY KEY,
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  active_cycle_id uuid NOT NULL,
  program_id      text NOT NULL,
  week            integer NOT NULL,
  day             integer,
  session_id      text,
  completed_at    timestamptz NOT NULL,
  duration        integer,
  notes           text,
  updated_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.completed_workouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "CompletedWorkouts: owner access" ON public.completed_workouts
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS completed_workouts_user_date ON public.completed_workouts (user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS completed_workouts_cycle ON public.completed_workouts (user_id, active_cycle_id);

-- ─────────────────────────────────────────────
-- Completed Sets
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.completed_sets (
  id                  uuid PRIMARY KEY,
  user_id             uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_id          uuid NOT NULL REFERENCES public.completed_workouts(id) ON DELETE CASCADE,
  exercise_id         text NOT NULL,
  set_number          integer NOT NULL,
  prescribed_weight   numeric,
  actual_weight       numeric NOT NULL,
  prescribed_reps     integer NOT NULL,
  actual_reps         integer NOT NULL,
  rpe                 numeric,
  rest_seconds        integer,
  override_reason     text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.completed_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "CompletedSets: owner access" ON public.completed_sets
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS completed_sets_workout ON public.completed_sets (workout_id);
CREATE INDEX IF NOT EXISTS completed_sets_exercise ON public.completed_sets (user_id, exercise_id);

-- ─────────────────────────────────────────────
-- Personal Records
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.personal_records (
  id          uuid PRIMARY KEY,
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  exercise_id text NOT NULL,
  type        text NOT NULL CHECK (type IN ('weight', 'volume')),
  value       numeric NOT NULL,
  workout_id  uuid NOT NULL,
  date        timestamptz NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "PersonalRecords: owner access" ON public.personal_records
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS personal_records_user_exercise ON public.personal_records (user_id, exercise_id);
CREATE INDEX IF NOT EXISTS personal_records_date ON public.personal_records (user_id, date DESC);
