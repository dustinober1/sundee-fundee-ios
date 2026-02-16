export type ExperienceLevel = 'beginner' | 'intermediate' | 'advanced';
export type PrimaryGoal = 'strength' | 'hypertrophy' | 'explosiveness';

export interface User {
  id: string;
  name: string;
  experienceLevel: ExperienceLevel;
  primaryGoal: PrimaryGoal;
  createdAt: Date;
  syncedAt?: Date;
}

export type SyncStatus = 'synced' | 'syncing' | 'pending' | 'offline' | 'disabled';
