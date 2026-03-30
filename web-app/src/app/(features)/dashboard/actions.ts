"use server";

import { getAuthUser, userCollection, userDoc } from "@/lib/firestore";
import { calculateCycleStatus, getPhaseRecommendation, type CycleSettings, type PeriodLog } from "@/lib/domain";
import type { Timestamp } from "firebase-admin/firestore";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CycleStatusResult {
  currentPhase: string;
  phaseTitle: string;
  trainingRecommendation: string;
}

export interface DashboardStats {
  workoutsThisWeek: number;
  prsThisMonth: number;
  activeProgramName: string | null;
}

export interface ActiveProgram{
  programId: string;
  programName: string;
  currentWeek: number;
  totalWeeks: number;
  sessionName: string;
  duration: string;
  focus: string;
  progressPercent: number;
}

export interface Win{
  id: string;
  type: "pr" | "benchmark" | "first-workout" | "program-complete";
  title: string;
  subtitle: string;
  date: Date;
}

// ---------------------------------------------------------------------------
// Cycle Status
// ---------------------------------------------------------------------------

export async function getCycleStatus(): Promise<CycleStatusResult | null> {
  const user = await getAuthUser();
  if (!user) return null;

  // Check if cycle tracking is enabled
  const userSnap = await userDoc(user.uid).get();
  const userData = userSnap.data();
  if (!userData?.cycleTrackingEnabled) return null;

  // Get cycle settings
  const settingsDoc = await userCollection(user.uid, "cycleSettings").doc("default").get();
  if (!settingsDoc.exists) return null;

  const settings = settingsDoc.data() as CycleSettings;

  // Get period logs
  const logsSnapshot = await userCollection(user.uid, "periodLogs").orderBy("startDate", "desc").limit(6).get();
  const periodLogs: PeriodLog[] = logsSnapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      startDate: (data.startDate as Timestamp).toDate(),
      endDate: data.endDate ? (data.endDate as Timestamp).toDate() : undefined,
    };
  });

  if (periodLogs.length === 0) return null;

  // Calculate cycle status
  const status = calculateCycleStatus(periodLogs, settings);
  if (!status) return null;

  const recommendation = getPhaseRecommendation(status.currentPhase);

  return {
    currentPhase: status.currentPhase,
    phaseTitle: recommendation.title,
    trainingRecommendation: recommendation.intensityRecommendation === "peak"
      ? "Peak performance — go for PRs!"
      : recommendation.intensityRecommendation === "low"
      ? "Take it easy — focus on recovery"
      : "Moderate intensity — steady progress",
  };
}

// ---------------------------------------------------------------------------
// Dashboard Stats
// ---------------------------------------------------------------------------

export async function getDashboardStats(): Promise<DashboardStats>{
  const user = await getAuthUser();
  if (!user) {
    return { workoutsThisWeek: 0, prsThisMonth: 0, activeProgramName: null };
  }

  // Workouts this week
  const now = new Date();
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  startOfWeek.setHours(0, 0, 0, 0);

  const workoutsSnapshot = await userCollection(user.uid, "completedWorkouts")
    .where("completedAt", ">=", startOfWeek)
    .get();
  const workoutsThisWeek = workoutsSnapshot.size;

  // PRs this month
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const maxesSnapshot = await userCollection(user.uid, "oneRepMaxes")
    .orderBy("date", "desc")
    .get();

  // Count unique exercises with new maxes this month
  const exercisesThisMonth = new Set<string>();
  const previousMaxes = new Map<string, number>();

  for (const doc of maxesSnapshot.docs) {
    const data = doc.data();
    const date = (data.date as Timestamp).toDate();
    const exerciseId = data.exerciseId;
    const weight = data.weightKg;

    if (date >= startOfMonth) {
      // Check if this is a new PR (higher than previous)
      const prev = previousMaxes.get(exerciseId);
      if (prev === undefined || weight > prev) {
        exercisesThisMonth.add(exerciseId);
      }
    }
    previousMaxes.set(exerciseId, Math.max(previousMaxes.get(exerciseId) ?? 0, weight));
  }
  const prsThisMonth = exercisesThisMonth.size;

  // Active program name
  const programsSnapshot = await userCollection(user.uid, "enrolledPrograms")
    .where("status", "==", "active")
    .limit(1)
    .get();

  let activeProgramName: string | null = null;
  if (!programsSnapshot.empty) {
    const programData = programsSnapshot.docs[0].data();
    // Program name stored directly or looked up
    activeProgramName = programData.programName ?? "Program";
  }

  return { workoutsThisWeek, prsThisMonth, activeProgramName };
}

// ---------------------------------------------------------------------------
// Active Program
// ---------------------------------------------------------------------------

export async function getActiveProgram(): Promise<ActiveProgram | null>{
  const user = await getAuthUser();
  if (!user) return null;

  const snapshot = await userCollection(user.uid, "enrolledPrograms")
    .where("status", "==", "active")
    .limit(1)
    .get();

  if (snapshot.empty) return null;

  const data = snapshot.docs[0].data();

  // Default values - these would ideally come from the program definition
  const totalWeeks = data.totalWeeks || 8;  // Use || to catch 0 as well
  const progressPercent = Math.round((data.currentWeek / totalWeeks) * 100);

  return{
    programId: data.programId,
    programName: data.programName ?? "Training Program",
    currentWeek: data.currentWeek ?? 1,
    totalWeeks,
    sessionName: data.currentSessionName ?? "Today's Session",
    duration: data.sessionDuration ?? "45 min",
    focus: data.sessionFocus ?? "Full Body",
    progressPercent,
  };
}

// ---------------------------------------------------------------------------
// Recent Wins
// ---------------------------------------------------------------------------

export async function getRecentWins(): Promise<Win[]>{
  const user = await getAuthUser();
  if (!user) return [];

  const wins: Win[] = [];
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  // Get PRs (1RM improvements)
  const maxesSnapshot = await userCollection(user.uid, "oneRepMaxes")
    .orderBy("date", "desc")
    .limit(50)
    .get();

  const exerciseMaxHistory = new Map<string, { max: number; date: Date; id: string }[]>();

  for (const doc of maxesSnapshot.docs) {
    const data = doc.data();
    const exerciseId = data.exerciseId;
    const weight = data.weightKg;
    const date = (data.date as Timestamp).toDate();

    if (!exerciseMaxHistory.has(exerciseId)) {
      exerciseMaxHistory.set(exerciseId, []);
    }
    exerciseMaxHistory.get(exerciseId)!.push({ max: weight, date, id: doc.id });
  }

  // Find PRs (new maxes)
  for (const [exerciseId, history] of exerciseMaxHistory) {
    if (history.length < 2) continue;
    const sorted = history.sort((a, b) => b.max - a.max);
    const best = sorted[0];
    if (best.date >= thirtyDaysAgo) {
      wins.push({
        id: `pr-${best.id}`,
        type: "pr",
        title: `New PR — ${exerciseId}`,
        subtitle: `${best.max} kg`,
        date: best.date,
      });
    }
  }

  // Get benchmark improvements
  const benchmarksSnapshot = await userCollection(user.uid, "benchmarkResults")
    .orderBy("date", "desc")
    .limit(20)
    .get();

  const benchmarkHistory = new Map<string, { best: number; date: Date; id: string }[]>();

  for (const doc of benchmarksSnapshot.docs) {
    const data = doc.data();
    const benchmarkId = data.benchmarkId;
    const score = data.score;
    const date = (data.date as Timestamp).toDate();

    if (!benchmarkHistory.has(benchmarkId)) {
      benchmarkHistory.set(benchmarkId, []);
    }
    benchmarkHistory.get(benchmarkId)!.push({ best: score, date, id: doc.id });
  }

  // Find benchmark PRs (better scores)
  for (const [benchmarkId, history] of benchmarkHistory) {
    if (history.length < 2) continue;
    const sorted = history.sort((a, b) => b.best - a.best);
    const best = sorted[0];
    if (best.date >= thirtyDaysAgo) {
      wins.push({
        id: `benchmark-${best.id}`,
        type: "benchmark",
        title: `${benchmarkId} — New Best`,
        subtitle: formatBenchmarkScore(best.best),
        date: best.date,
      });
    }
  }

  // Check for first workout
  const workoutsSnapshot = await userCollection(user.uid, "completedWorkouts")
    .orderBy("completedAt", "asc")
    .limit(1)
    .get();

  if (!workoutsSnapshot.empty) {
    const firstWorkout = workoutsSnapshot.docs[0].data();
    const firstDate = (firstWorkout.completedAt as Timestamp).toDate();
    if (firstDate >= thirtyDaysAgo) {
      wins.push({
        id: "first-workout",
        type: "first-workout",
        title: "First Workout!",
        subtitle: "Welcome to Sundee Fundee",
        date: firstDate,
      });
    }
  }

  // Sort by date desc and limit to 5
  return wins
    .sort((a, b) => b.date.getTime() - a.date.getTime())
    .slice(0, 5);
}

function formatBenchmarkScore(score: number): string{
  if (score > 10000) {
    // roundsAndReps encoding
    const rounds = Math.floor(score / 10000);
    const reps = score % 10000;
    return `${rounds} rounds + ${reps} reps`;
  }
  if (score < 1000) {
    // Likely time in seconds
    const minutes = Math.floor(score / 60);
    const seconds = score % 60;
    return `${minutes}:${String(seconds).padStart(2, "0")}`;
  }
  return `${score}`;
}
