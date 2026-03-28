export interface Env {
  AI: Ai;
  RATE_LIMIT: KVNamespace;
  JWT_SECRET: string;
}

export interface JwtPayload {
  sub: string;
  tier: "plus" | "premium";
  iat: number;
}

export interface WorkoutRequest {
  prompt: string;
  systemInstruction: string;
}

export interface Exercise {
  name: string;
  sets: number;
  reps: string;
  weightKg: number | null;
  restMinutes: number | null;
  notes: string | null;
  bodyweightOnly: boolean;
}

export interface WorkoutResponse {
  coachingSummary: string;
  exercises: Exercise[];
}

export interface ErrorResponse {
  error: string;
  message?: string;
  remaining?: number;
  resetsAt?: string;
}

export type Tier = "plus" | "premium";

export const TIER_LIMITS: Record<Tier, number> = {
  plus: 1,
  premium: 10,
};

export const TIER_MODELS: Record<Tier, string> = {
  plus: "@cf/qwen/qwen3-30b-a3b-fp8",
  premium: "@cf/nvidia/nemotron-3-120b-a12b",
};
