"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";
import { calculateCycleStatus } from "@/lib/domain";
import type { CycleSettings, CycleStatusResult } from "@/lib/domain";
import { coerceStoredDateToLocalDate, formatDateInputValue } from "@/lib/date-input";
import {
  optionalTrimmedString,
  requireDateInput,
  requireFiniteNumber,
  requireOneOf,
  requireTrimmedString,
} from "@/lib/write-validation";

export interface PeriodLogRecord {
  id: string;
  startDate: string;
  endDate?: string;
  flowLevel: "light" | "medium" | "heavy";
  symptoms?: string[];
  notes?: string;
}

// ---------------------------------------------------------------------------
// getPeriodLogs
// ---------------------------------------------------------------------------

export async function getPeriodLogs(): Promise<PeriodLogRecord[]> {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "periodLogs")
    .orderBy("startDate", "desc")
    .get();

  return snapshot.docs.flatMap((doc) => {
    const data = doc.data();
    const startDate = coerceStoredDateToLocalDate(data.startDate);

    if (!startDate) return [];

    const endDate = coerceStoredDateToLocalDate(data.endDate);

    return [{
      id: doc.id,
      flowLevel: (data.flowLevel as PeriodLogRecord["flowLevel"]) ?? "medium",
      symptoms: Array.isArray(data.symptoms) ? data.symptoms.filter((value): value is string => typeof value === "string") : undefined,
      notes: typeof data.notes === "string" ? data.notes : undefined,
      startDate: formatDateInputValue(startDate),
      ...(endDate ? { endDate: formatDateInputValue(endDate) } : {}),
    }];
  });
}

// ---------------------------------------------------------------------------
// getCycleSettings
// ---------------------------------------------------------------------------

export async function getCycleSettings() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userCollection(user.uid, "cycleSettings").doc("default").get();
  return doc.exists ? doc.data() : null;
}

// ---------------------------------------------------------------------------
// saveCycleSettings
// ---------------------------------------------------------------------------

export async function saveCycleSettings(settings: {
  averageCycleLengthDays: number;
  averagePeriodLengthDays: number;
  lutealPhaseLengthDays: number;
}) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const averageCycleLengthDays = requireFiniteNumber(
    settings.averageCycleLengthDays,
    "Average cycle length",
    { integer: true, min: 1 }
  );
  const averagePeriodLengthDays = requireFiniteNumber(
    settings.averagePeriodLengthDays,
    "Average period length",
    { integer: true, min: 1 }
  );
  const lutealPhaseLengthDays = requireFiniteNumber(
    settings.lutealPhaseLengthDays,
    "Luteal phase length",
    { integer: true, min: 1 }
  );

  await userCollection(user.uid, "cycleSettings").doc("default").set(
    {
      averageCycleLengthDays,
      averagePeriodLengthDays,
      lutealPhaseLengthDays,
      updatedAt: new Date(),
    },
    { merge: true }
  );
}

// ---------------------------------------------------------------------------
// logPeriod (enhanced)
// ---------------------------------------------------------------------------

export async function logPeriod(data: {
  startDate: string;
  endDate?: string;
  flowLevel: "light" | "medium" | "heavy";
  symptoms?: string[];
  notes?: string;
}) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const startDate = requireDateInput(data.startDate, "Start date");
  const endDate = data.endDate ? requireDateInput(data.endDate, "End date") : undefined;
  if (endDate && endDate < startDate) {
    throw new Error("End date cannot be earlier than start date.");
  }

  const flowLevel = requireOneOf(data.flowLevel, ["light", "medium", "heavy"], "Flow level");
  const symptoms = data.symptoms?.map((symptom) => symptom.trim()).filter(Boolean);
  const notes = optionalTrimmedString(data.notes);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const doc: Record<string, any> = {
    startDate,
    flowLevel,
  };

  if (endDate) {
    doc.endDate = endDate;
  }
  if (symptoms && symptoms.length > 0) {
    doc.symptoms = symptoms;
  }
  if (notes) {
    doc.notes = notes;
  }

  await userCollection(user.uid, "periodLogs").add(doc);
}

export async function deletePeriodLog(periodLogId: string) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const id = requireTrimmedString(periodLogId, "Period log");
  await userCollection(user.uid, "periodLogs").doc(id).delete();
}

// ---------------------------------------------------------------------------
// getCycleStatus (shared — usable from any page)
// ---------------------------------------------------------------------------

export async function getCycleStatus(): Promise<CycleStatusResult | null> {
  const user = await getAuthUser();
  if (!user) return null;

  const [logsSnap, settingsDoc] = await Promise.all([
    userCollection(user.uid, "periodLogs").orderBy("startDate", "desc").get(),
    userCollection(user.uid, "cycleSettings").doc("default").get(),
  ]);

  const settings: CycleSettings = {
    averageCycleLengthDays: (settingsDoc.data()?.averageCycleLengthDays as number) ?? 28,
    averagePeriodLengthDays: (settingsDoc.data()?.averagePeriodLengthDays as number) ?? 5,
    lutealPhaseLengthDays: (settingsDoc.data()?.lutealPhaseLengthDays as number) ?? 14,
  };

  const periodLogs = logsSnap.docs.map((doc) => {
    const d = doc.data();
    const startDate = coerceStoredDateToLocalDate(d.startDate);
    const endDate = coerceStoredDateToLocalDate(d.endDate);

    if (!startDate) return null;

    return {
      startDate,
      endDate: endDate ?? undefined,
    };
  }).filter((log): log is { startDate: Date; endDate: Date | undefined } => log !== null);

  return calculateCycleStatus(periodLogs, settings, new Date());
}
