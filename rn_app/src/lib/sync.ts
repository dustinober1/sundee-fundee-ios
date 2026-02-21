import { executeSqlAsync } from './db';
import { supabase } from './supabase';

export async function syncPendingWorkouts() {
  try {
    const res: any = await executeSqlAsync(`SELECT id, data FROM completed_workouts WHERE synced = 0;`);
    const rows = res && res.rows;
    if (!rows || rows.length === 0) return { inserted: 0 };

    let inserted = 0;
    for (let i = 0; i < rows.length; i++) {
      const row = rows.item(i);
      let payload = null;
      try {
        payload = JSON.parse(row.data);
      } catch (e) {
        console.warn('Invalid JSON in completed_workouts row', row.id);
        continue;
      }

      const { error } = await supabase.from('completed_workouts').insert([payload]);
      if (!error) {
        await executeSqlAsync(`UPDATE completed_workouts SET synced = 1 WHERE id = ?;`, [row.id]);
        inserted++;
      }
    }

    return { inserted };
  } catch (err) {
    console.warn('syncPendingWorkouts error', err);
    throw err;
  }
}

export function scheduleBackgroundSync(intervalMs = 1000 * 60 * 5) {
  const id = setInterval(() => {
    syncPendingWorkouts().catch(err => console.warn('background sync failed', err));
  }, intervalMs);
  return () => clearInterval(id);
}
