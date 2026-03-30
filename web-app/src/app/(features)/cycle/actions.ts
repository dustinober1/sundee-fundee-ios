"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";
import { calculateCycleStatus } from "@/lib/domain";
import type { CycleSettings, CycleStatusResult } from "@/lib/domain";

// ---------------------------------------------------------------------------
// getPeriodLogs
// ---------------------------------------------------------------------------

export async function getPeriodLogs() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "periodLogs")
    .orderBy("startDate", "desc")
    .get();

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return snapshot.docs.map((doc) => ({ id: doc.id, ...(doc.data() as any) }));
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

  await userCollection(user.uid, "cycleSettings").doc("default").set(
    {
      averageCycleLengthDays: settings.averageCycleLengthDays,
      averagePeriodLengthDays: settings.averagePeriodLengthDays,
      lutealPhaseLengthDays: settings.lutealPhaseLengthDays,
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

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const doc: Record<string, any> = {
    startDate: new Date(data.startDate),
    flowLevel: data.flowLevel,
  };

  if (data.endDate) {
    doc.endDate = new Date(data.endDate);
  }
  if (data.symptoms && data.symptoms.length > 0) {
    doc.symptoms = data.symptoms;
  }
  if (data.notes && data.notes.trim().length > 0) {
    doc.notes = data.notes.trim();
  }

  await userCollection(user.uid, "periodLogs").add(doc);
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
    return {
      startDate: (d.startDate as { toDate(): Date }).toDate(),
      endDate: d.endDate ? (d.endDate as { toDate(): Date }).toDate() : undefined,
    };
  });

  return calculateCycleStatus(periodLogs, settings, new Date());
}
