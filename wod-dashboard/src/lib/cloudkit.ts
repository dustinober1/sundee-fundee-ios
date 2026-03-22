"use client";

import type { WOD, Program, BenchmarkDefinition } from "@/lib/types";
import { exerciseToJSON } from "@/lib/types";

// ─── CloudKit API (server-side proxy with S2S auth) ─────────────────────────

async function cloudKitRequest(
  method: "POST" | "GET",
  path: string,
  body?: any
): Promise<any> {
  const res = await fetch("/api/cloudkit/request", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ckMethod: method, path, body }),
  });
  const data = await res.json();
  if (data.error) throw new Error(data.error);
  return data;
}

// ─── WOD Records ────────────────────────────────────────────────────────────

export async function saveWODRecord(wod: WOD): Promise<void> {
  const record = {
    recordType: "WOD",
    recordName: wod.id,
    fields: {
      id: { value: wod.id },
      date: { value: wod.date },
      title: { value: wod.title },
      description: { value: wod.description },
      exercisesJSON: { value: JSON.stringify(wod.exercises.map(exerciseToJSON)) },
    },
  };

  const data = await cloudKitRequest("POST", "records/modify", {
    operations: [{ operationType: "forceReplace", record }],
  });

  if (data.hasErrors || data.records?.[0]?.serverErrorCode) {
    const reason = data.records?.[0]?.reason ?? data.reason ?? "Unknown error";
    throw new Error(`CloudKit save failed: ${reason}`);
  }
}

// ─── Program Records ────────────────────────────────────────────────────────

export async function saveProgramRecord(program: Program): Promise<void> {
  const record = {
    recordType: "Program",
    recordName: program.id,
    fields: {
      id: { value: program.id },
      name: { value: program.name },
      category: { value: program.category },
      description: { value: program.description },
      durationWeeks: { value: program.durationWeeks },
      sessionsPerWeek: { value: program.sessionsPerWeek },
      difficulty: { value: program.difficulty },
      phasesJSON: { value: JSON.stringify(program.phases) },
      weeksJSON: { value: JSON.stringify(program.weeks) },
      cycleAdjustmentProfileJSON: {
        value: program.cycleAdjustmentProfile
          ? JSON.stringify(program.cycleAdjustmentProfile)
          : null,
      },
    },
  };

  const data = await cloudKitRequest("POST", "records/modify", {
    operations: [{ operationType: "forceReplace", record }],
  });

  if (data.hasErrors || data.records?.[0]?.serverErrorCode) {
    const reason = data.records?.[0]?.reason ?? data.reason ?? "Unknown error";
    throw new Error(`CloudKit save failed: ${reason}`);
  }
}

// ─── Benchmark Records ──────────────────────────────────────────────────────

export async function saveBenchmarkRecord(benchmark: BenchmarkDefinition): Promise<void> {
  const record = {
    recordType: "BenchmarkDefinition",
    recordName: benchmark.id,
    fields: {
      id: { value: benchmark.id },
      name: { value: benchmark.name },
      category: { value: benchmark.category },
      workoutDescription: { value: benchmark.workoutDescription },
      scoringTypeRaw: { value: benchmark.scoringTypeRaw },
      sortOrder: { value: benchmark.sortOrder },
    },
  };

  const data = await cloudKitRequest("POST", "records/modify", {
    operations: [{ operationType: "forceReplace", record }],
  });

  if (data.hasErrors || data.records?.[0]?.serverErrorCode) {
    const reason = data.records?.[0]?.reason ?? data.reason ?? "Unknown error";
    throw new Error(`CloudKit save failed: ${reason}`);
  }
}

// ─── Delete Record ──────────────────────────────────────────────────────────

export async function deleteRecord(
  recordType: string,
  recordName: string
): Promise<void> {
  const data = await cloudKitRequest("POST", "records/modify", {
    operations: [{ operationType: "delete", record: { recordType, recordName } }],
  });

  if (data.hasErrors || data.records?.[0]?.serverErrorCode) {
    const reason = data.records?.[0]?.reason ?? data.reason ?? "Unknown error";
    throw new Error(`CloudKit delete failed: ${reason}`);
  }
}
