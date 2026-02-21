import * as SQLite from 'expo-sqlite';

const db = SQLite.openDatabase('sundee.db');

export function executeSqlAsync<T = any>(sql: string, params: any[] = []) {
  return new Promise<T>((resolve, reject) => {
    db.transaction(tx => {
      tx.executeSql(
        sql,
        params,
        (_, result) => resolve(result as unknown as T),
        (_, error) => {
          reject(error);
          return false;
        }
      );
    });
  });
}

export async function initDb() {
  // Example core tables; expand as needed during implementation
  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS completed_workouts (id TEXT PRIMARY KEY, data TEXT, synced INTEGER DEFAULT 0);`
  );
  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS completed_sets (id TEXT PRIMARY KEY, workout_id TEXT, data TEXT, synced INTEGER DEFAULT 0);`
  );
  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS active_cycles (id TEXT PRIMARY KEY, data TEXT, synced INTEGER DEFAULT 0);`
  );
  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY NOT NULL, key TEXT, value TEXT);`
  );
}
