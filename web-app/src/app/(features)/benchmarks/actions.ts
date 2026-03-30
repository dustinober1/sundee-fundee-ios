"use server";

import { getAuthUser, userCollection, db } from "@/lib/firestore";
import { PREDEFINED_BENCHMARKS } from "@/lib/domain";
import {
  optionalTrimmedString,
  requireFiniteNumber,
  requireTrimmedString,
} from "@/lib/write-validation";

export interface BenchmarkResult {
  id: string;
  definitionId: string;
  scoreValue: number;
  notes?: string;
  performedAt: Date | null;
}

export async function getBenchmarkResults(): Promise<BenchmarkResult[]> {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "benchmarkResults")
    .orderBy("performedAt", "desc")
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    // Convert Firestore Timestamp to Date
    const performedAt = data.performedAt?.toDate?.() ?? data.performedAt ?? null;
    return {
      id: doc.id,
      definitionId: data.definitionId,
      scoreValue: data.scoreValue,
      notes: data.notes,
      performedAt,
    } as BenchmarkResult;
  });
}

export async function logBenchmarkResult(data: { definitionId: string; scoreValue: number; notes?: string }) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const definitionId = requireTrimmedString(data.definitionId, "Benchmark");
  const scoreValue = requireFiniteNumber(data.scoreValue, "Score", { min: 0 });
  const notes = optionalTrimmedString(data.notes);

  const predefined = PREDEFINED_BENCHMARKS.find((b) => b.id === definitionId);
  if (predefined) {
    const defRef = db.collection("benchmarkDefinitions").doc(predefined.id);
    const defDoc = await defRef.get();
    if (!defDoc.exists) {
      await defRef.set({
        name: predefined.name,
        category: predefined.category,
        workoutDescription: predefined.workoutDescription,
        scoringType: predefined.scoringType,
        isPredefined: true,
        sortOrder: predefined.sortOrder,
      });
    }
  }

  await userCollection(user.uid, "benchmarkResults").add({
    definitionId,
    scoreValue,
    notes: notes ?? "",
    performedAt: new Date(),
  });
}
