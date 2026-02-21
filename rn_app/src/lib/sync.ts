import {
  getPendingSyncJobs,
  markSyncJobDone,
  markSyncJobFailed,
  type SyncQueueJob,
} from './db';
import { getSupabaseClient, hasSupabaseConfig } from './supabase';

type SyncPayload = Record<string, string | number | null>;

function parsePayload(job: SyncQueueJob): SyncPayload {
  try {
    return JSON.parse(job.payload) as SyncPayload;
  } catch (error) {
    throw new Error(`Invalid sync payload for job ${job.id}: ${String(error)}`);
  }
}

async function pushSyncJob(job: SyncQueueJob): Promise<void> {
  const supabase = getSupabaseClient();
  const payload = parsePayload(job);

  if (job.operation === 'delete') {
    const { error } = await supabase.from(job.tableName).delete().eq('id', job.recordId);
    if (error) {
      throw new Error(error.message);
    }
    return;
  }

  const { error } = await supabase.from(job.tableName).upsert(payload, { onConflict: 'id' });
  if (error) {
    throw new Error(error.message);
  }
}

export async function syncPendingChanges(limit = 20): Promise<{
  total: number;
  synced: number;
  failed: number;
}> {
  if (!hasSupabaseConfig()) {
    return { total: 0, synced: 0, failed: 0 };
  }

  const jobs = await getPendingSyncJobs(limit);
  let synced = 0;
  let failed = 0;

  for (const job of jobs) {
    try {
      await pushSyncJob(job);
      await markSyncJobDone(job.id);
      synced += 1;
    } catch (error) {
      await markSyncJobFailed(job.id, String(error));
      failed += 1;
    }
  }

  return { total: jobs.length, synced, failed };
}

export function scheduleBackgroundSync(intervalMs = 1000 * 60 * 5) {
  const intervalId = setInterval(() => {
    void syncPendingChanges().catch(error => {
      console.warn('Background sync failed', error);
    });
  }, intervalMs);

  return () => clearInterval(intervalId);
}
