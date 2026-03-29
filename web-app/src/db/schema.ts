import { sqliteTable, text, integer, real } from "drizzle-orm/sqlite-core";

// Auth.js tables
export const users = sqliteTable("users", {
  id: text("id").primaryKey(),
  name: text("name"),
  email: text("email").notNull().unique(),
  emailVerified: integer("email_verified", { mode: "timestamp" }),
  image: text("image"),
  experienceLevel: text("experience_level").default("beginner"),
  primaryGoal: text("primary_goal").default("strength"),
  gender: text("gender").default("prefer_not_to_say"),
  weightUnit: text("weight_unit").default("lb"),
  cycleTrackingEnabled: integer("cycle_tracking_enabled", { mode: "boolean" }).default(false),
  onboardingComplete: integer("onboarding_complete", { mode: "boolean" }).default(false),
  password: text("password"),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull().$defaultFn(() => new Date()),
  profileUpdatedAt: integer("profile_updated_at", { mode: "timestamp" }),
});

export const accounts = sqliteTable("accounts", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  type: text("type").notNull(),
  provider: text("provider").notNull(),
  providerAccountId: text("provider_account_id").notNull(),
  refreshToken: text("refresh_token"),
  accessToken: text("access_token"),
  expiresAt: integer("expires_at"),
  tokenType: text("token_type"),
  scope: text("scope"),
  idToken: text("id_token"),
  sessionState: text("session_state"),
});

export const sessions = sqliteTable("sessions", {
  id: text("id").primaryKey(),
  sessionToken: text("session_token").notNull().unique(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  expires: integer("expires", { mode: "timestamp" }).notNull(),
});

export const verificationTokens = sqliteTable("verification_tokens", {
  identifier: text("identifier").notNull(),
  token: text("token").notNull(),
  expires: integer("expires", { mode: "timestamp" }).notNull(),
});

// Maxes & Personal Records
export const oneRepMaxes = sqliteTable("one_rep_maxes", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  weightKg: real("weight_kg").notNull(),
  date: integer("date", { mode: "timestamp" }).notNull(),
  isEstimated: integer("is_estimated", { mode: "boolean" }).default(false),
});

export const personalRecords = sqliteTable("personal_records", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  repMaxType: text("rep_max_type").notNull(),
  weightKg: real("weight_kg").notNull(),
  reps: integer("reps").notNull(),
  achievedAt: integer("achieved_at", { mode: "timestamp" }).notNull(),
  workoutId: text("workout_id"),
});

export const liftMaxes = sqliteTable("lift_maxes", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  weightKg: real("weight_kg").notNull(),
  date: integer("date", { mode: "timestamp" }).notNull(),
});

export const conditioningPrs = sqliteTable("conditioning_prs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  exerciseId: text("exercise_id").notNull(),
  scoringType: text("scoring_type").notNull(),
  bestValue: real("best_value").notNull(),
  weightKg: real("weight_kg"),
  achievedAt: integer("achieved_at", { mode: "timestamp" }).notNull(),
  workoutId: text("workout_id"),
});

// Programs & Enrollment
export const enrolledPrograms = sqliteTable("enrolled_programs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  programId: text("program_id").notNull(),
  startDate: integer("start_date", { mode: "timestamp" }).notNull(),
  currentWeek: integer("current_week").default(1),
  currentDay: integer("current_day").default(1),
  status: text("status").default("active"),
  completedAt: integer("completed_at", { mode: "timestamp" }),
  canceledAt: integer("canceled_at", { mode: "timestamp" }),
  completedWeeksRaw: text("completed_weeks_raw").default(""),
  lastSyncedAt: integer("last_synced_at", { mode: "timestamp" }),
});

export const enrollmentEvents = sqliteTable("enrollment_events", {
  id: text("id").primaryKey(),
  enrollmentId: text("enrollment_id").notNull().references(() => enrolledPrograms.id, { onDelete: "cascade" }),
  eventType: text("event_type").notNull(),
  occurredAt: integer("occurred_at", { mode: "timestamp" }).notNull(),
  programId: text("program_id"),
});

// Workouts
export const completedWorkouts = sqliteTable("completed_workouts", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  activeCycleId: text("active_cycle_id"),
  programId: text("program_id"),
  enrollmentId: text("enrollment_id"),
  week: integer("week"),
  day: integer("day"),
  sessionId: text("session_id"),
  completedAt: integer("completed_at", { mode: "timestamp" }).notNull(),
  durationSeconds: integer("duration_seconds").default(0),
  notes: text("notes"),
  perceivedEffort: integer("perceived_effort"),
});

export const completedSets = sqliteTable("completed_sets", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  workoutId: text("workout_id").notNull().references(() => completedWorkouts.id, { onDelete: "cascade" }),
  exerciseName: text("exercise_name").notNull(),
  setIndex: integer("set_index").notNull(),
  prescribedReps: text("prescribed_reps").notNull(),
  actualReps: integer("actual_reps"),
  prescribedWeightKg: real("prescribed_weight_kg"),
  actualWeightKg: real("actual_weight_kg"),
  isCompleted: integer("is_completed", { mode: "boolean" }).default(false),
  completedAt: integer("completed_at", { mode: "timestamp" }).notNull(),
  actualTimeSeconds: real("actual_time_seconds"),
  scoringType: text("scoring_type"),
});

// Injuries & Pain
export const injuryProfiles = sqliteTable("injury_profiles", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  location: text("location").default(""),
  movementLimitations: text("movement_limitations").default(""),
  recoveryGoal: text("recovery_goal").default(""),
  status: text("status").default("active"),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull(),
  resolvedAt: integer("resolved_at", { mode: "timestamp" }),
  recoveryPhase: text("recovery_phase").default("acute"),
  locationRegionsRaw: text("location_regions_raw").default(""),
  acknowledgedDisclaimerIdsRaw: text("acknowledged_disclaimer_ids_raw").default(""),
});

export const painLogs = sqliteTable("pain_logs", {
  id: text("id").primaryKey(),
  injuryProfileId: text("injury_profile_id").notNull().references(() => injuryProfiles.id, { onDelete: "cascade" }),
  painLevel: integer("pain_level").notNull(),
  workoutId: text("workout_id"),
  notes: text("notes"),
  recordedAt: integer("recorded_at", { mode: "timestamp" }).notNull(),
  triggerExercise: text("trigger_exercise"),
  symptomType: text("symptom_type"),
  intensityContext: text("intensity_context"),
});

// Cycle Tracking
export const periodLogs = sqliteTable("period_logs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  startDate: integer("start_date", { mode: "timestamp" }).notNull(),
  endDate: integer("end_date", { mode: "timestamp" }),
  flowLevel: text("flow_level").default("medium"),
  notes: text("notes"),
});

export const symptomLogs = sqliteTable("symptom_logs", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  date: integer("date", { mode: "timestamp" }).notNull(),
  symptomId: text("symptom_id").notNull(),
  severity: integer("severity").notNull(),
  notes: text("notes"),
});

export const cycleSettings = sqliteTable("cycle_settings", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  averageCycleLengthDays: integer("average_cycle_length_days").default(28),
  averagePeriodLengthDays: integer("average_period_length_days").default(5),
  lutealPhaseLengthDays: integer("luteal_phase_length_days").default(14),
  isTrackingEnabled: integer("is_tracking_enabled", { mode: "boolean" }).default(true),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull(),
});

export const cycleAdaptationPreferences = sqliteTable("cycle_adaptation_preferences", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  adaptationEnabled: integer("adaptation_enabled", { mode: "boolean" }).default(true),
  fallbackPhase: text("fallback_phase").default("follicular"),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull(),
});

// Benchmarks
export const benchmarkDefinitions = sqliteTable("benchmark_definitions", {
  id: text("id").primaryKey(),
  userId: text("user_id").default(""),
  name: text("name").notNull(),
  category: text("category").notNull(),
  workoutDescription: text("workout_description").notNull(),
  scoringType: text("scoring_type").notNull(),
  isPredefined: integer("is_predefined", { mode: "boolean" }).default(false),
  sortOrder: integer("sort_order").default(0),
});

export const benchmarkResults = sqliteTable("benchmark_results", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  definitionId: text("definition_id").notNull().references(() => benchmarkDefinitions.id),
  scoreValue: real("score_value").notNull(),
  notes: text("notes").default(""),
  performedAt: integer("performed_at", { mode: "timestamp" }).notNull(),
});

// AI Workouts
export const generatedWorkoutRecords = sqliteTable("generated_workout_records", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  workoutJson: text("workout_json").notNull(),
  isFavorite: integer("is_favorite", { mode: "boolean" }).default(false),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

export const customProgramRecords = sqliteTable("custom_program_records", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  programJson: text("program_json").notNull(),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

// Subscriptions (Stripe)
export const subscriptions = sqliteTable("subscriptions", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  stripeCustomerId: text("stripe_customer_id").notNull(),
  stripeSubscriptionId: text("stripe_subscription_id"),
  tier: text("tier").default("free"),
  status: text("status").default("active"),
  currentPeriodEnd: integer("current_period_end", { mode: "timestamp" }),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull().$defaultFn(() => new Date()),
  updatedAt: integer("updated_at", { mode: "timestamp" }).notNull().$defaultFn(() => new Date()),
});
