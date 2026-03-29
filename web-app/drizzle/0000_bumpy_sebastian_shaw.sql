CREATE TABLE `accounts` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`type` text NOT NULL,
	`provider` text NOT NULL,
	`provider_account_id` text NOT NULL,
	`refresh_token` text,
	`access_token` text,
	`expires_at` integer,
	`token_type` text,
	`scope` text,
	`id_token` text,
	`session_state` text,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `benchmark_definitions` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text DEFAULT '',
	`name` text NOT NULL,
	`category` text NOT NULL,
	`workout_description` text NOT NULL,
	`scoring_type` text NOT NULL,
	`is_predefined` integer DEFAULT false,
	`sort_order` integer DEFAULT 0
);
--> statement-breakpoint
CREATE TABLE `benchmark_results` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`definition_id` text NOT NULL,
	`score_value` real NOT NULL,
	`notes` text DEFAULT '',
	`performed_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`definition_id`) REFERENCES `benchmark_definitions`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `completed_sets` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`workout_id` text NOT NULL,
	`exercise_name` text NOT NULL,
	`set_index` integer NOT NULL,
	`prescribed_reps` text NOT NULL,
	`actual_reps` integer,
	`prescribed_weight_kg` real,
	`actual_weight_kg` real,
	`is_completed` integer DEFAULT false,
	`completed_at` integer NOT NULL,
	`actual_time_seconds` real,
	`scoring_type` text,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`workout_id`) REFERENCES `completed_workouts`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `completed_workouts` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`active_cycle_id` text,
	`program_id` text,
	`enrollment_id` text,
	`week` integer,
	`day` integer,
	`session_id` text,
	`completed_at` integer NOT NULL,
	`duration_seconds` integer DEFAULT 0,
	`notes` text,
	`perceived_effort` integer,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `conditioning_prs` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`exercise_id` text NOT NULL,
	`scoring_type` text NOT NULL,
	`best_value` real NOT NULL,
	`weight_kg` real,
	`achieved_at` integer NOT NULL,
	`workout_id` text,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `custom_program_records` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`program_json` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `cycle_adaptation_preferences` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`adaptation_enabled` integer DEFAULT true,
	`fallback_phase` text DEFAULT 'follicular',
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `cycle_settings` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`average_cycle_length_days` integer DEFAULT 28,
	`average_period_length_days` integer DEFAULT 5,
	`luteal_phase_length_days` integer DEFAULT 14,
	`is_tracking_enabled` integer DEFAULT true,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `enrolled_programs` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`program_id` text NOT NULL,
	`start_date` integer NOT NULL,
	`current_week` integer DEFAULT 1,
	`current_day` integer DEFAULT 1,
	`status` text DEFAULT 'active',
	`completed_at` integer,
	`canceled_at` integer,
	`completed_weeks_raw` text DEFAULT '',
	`last_synced_at` integer,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `enrollment_events` (
	`id` text PRIMARY KEY NOT NULL,
	`enrollment_id` text NOT NULL,
	`event_type` text NOT NULL,
	`occurred_at` integer NOT NULL,
	`program_id` text,
	FOREIGN KEY (`enrollment_id`) REFERENCES `enrolled_programs`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `generated_workout_records` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`workout_json` text NOT NULL,
	`is_favorite` integer DEFAULT false,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `injury_profiles` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`location` text DEFAULT '',
	`movement_limitations` text DEFAULT '',
	`recovery_goal` text DEFAULT '',
	`status` text DEFAULT 'active',
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	`resolved_at` integer,
	`recovery_phase` text DEFAULT 'acute',
	`location_regions_raw` text DEFAULT '',
	`acknowledged_disclaimer_ids_raw` text DEFAULT '',
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `lift_maxes` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`exercise_id` text NOT NULL,
	`weight_kg` real NOT NULL,
	`date` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `one_rep_maxes` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`exercise_id` text NOT NULL,
	`weight_kg` real NOT NULL,
	`date` integer NOT NULL,
	`is_estimated` integer DEFAULT false,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `pain_logs` (
	`id` text PRIMARY KEY NOT NULL,
	`injury_profile_id` text NOT NULL,
	`pain_level` integer NOT NULL,
	`workout_id` text,
	`notes` text,
	`recorded_at` integer NOT NULL,
	`trigger_exercise` text,
	`symptom_type` text,
	`intensity_context` text,
	FOREIGN KEY (`injury_profile_id`) REFERENCES `injury_profiles`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `period_logs` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`start_date` integer NOT NULL,
	`end_date` integer,
	`flow_level` text DEFAULT 'medium',
	`notes` text,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `personal_records` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`exercise_id` text NOT NULL,
	`rep_max_type` text NOT NULL,
	`weight_kg` real NOT NULL,
	`reps` integer NOT NULL,
	`achieved_at` integer NOT NULL,
	`workout_id` text,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`session_token` text NOT NULL,
	`user_id` text NOT NULL,
	`expires` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `sessions_session_token_unique` ON `sessions` (`session_token`);--> statement-breakpoint
CREATE TABLE `subscriptions` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`stripe_customer_id` text NOT NULL,
	`stripe_subscription_id` text,
	`tier` text DEFAULT 'free',
	`status` text DEFAULT 'active',
	`current_period_end` integer,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `symptom_logs` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`date` integer NOT NULL,
	`symptom_id` text NOT NULL,
	`severity` integer NOT NULL,
	`notes` text,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `users` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text,
	`email` text NOT NULL,
	`email_verified` integer,
	`image` text,
	`experience_level` text DEFAULT 'beginner',
	`primary_goal` text DEFAULT 'strength',
	`gender` text DEFAULT 'prefer_not_to_say',
	`weight_unit` text DEFAULT 'lb',
	`cycle_tracking_enabled` integer DEFAULT false,
	`onboarding_complete` integer DEFAULT false,
	`created_at` integer NOT NULL,
	`profile_updated_at` integer
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);--> statement-breakpoint
CREATE TABLE `verification_tokens` (
	`identifier` text NOT NULL,
	`token` text NOT NULL,
	`expires` integer NOT NULL
);
