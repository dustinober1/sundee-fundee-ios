import * as SQLite from 'expo-sqlite';

const db = SQLite.openDatabase('sundee.db');

const CURRENT_SCHEMA_VERSION = 1;

export interface UserProfile {
  id: string;
  name: string;
  experienceLevel: string;
  goal: string;
  createdAt: string;
}

export interface ActiveCycleRecord {
  id: string;
  programId: string;
  cycleName: string;
  currentWeek: number;
  currentSessionId: string | null;
  currentPhase: string | null;
  status: 'active' | 'completed' | 'paused';
  syncId: string | null;
  updatedAt: string;
}

export interface LoggedSetInput {
  exerciseId: string;
  setNumber: number;
  prescribedWeight: number;
  actualWeight: number;
  prescribedReps: number;
  actualReps: number;
}

export interface SaveWorkoutInput {
  activeCycleId: string | null;
  programId: string;
  week: number;
  sessionId: string;
  durationSeconds: number;
  notes?: string;
  sets: LoggedSetInput[];
}

export interface WorkoutSummary {
  id: string;
  programId: string;
  week: number;
  sessionId: string;
  completedAt: string;
  durationSeconds: number | null;
  notes: string | null;
}

export interface WeeklyVolumePoint {
  weekKey: string;
  totalVolume: number;
}

export interface OneRmPoint {
  date: string;
  value: number;
}

export interface SyncQueueJob {
  id: string;
  tableName: string;
  recordId: string;
  payload: string;
  operation: 'upsert' | 'delete';
  attempts: number;
  lastError: string | null;
}

type SqlValue = string | number | null;
type SqlRecord = Record<string, SqlValue>;

function createId(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}

export function executeSqlAsync(
  sql: string,
  params: SQLite.SQLStatementArg[] = []
): Promise<SQLite.SQLResultSet> {
  return new Promise((resolve, reject) => {
    db.transaction(tx => {
      tx.executeSql(
        sql,
        params,
        (_, result) => resolve(result),
        (_, error) => {
          reject(error);
          return false;
        }
      );
    });
  });
}

async function queryRows<T extends SqlRecord>(
  sql: string,
  params: SQLite.SQLStatementArg[] = []
): Promise<T[]> {
  const result = await executeSqlAsync(sql, params);
  const rows: T[] = [];
  for (let i = 0; i < result.rows.length; i += 1) {
    rows.push(result.rows.item(i) as T);
  }
  return rows;
}

async function queueSyncUpsert(
  tableName: string,
  recordId: string,
  payload: Record<string, SqlValue>
): Promise<void> {
  const id = createId('sync');
  await executeSqlAsync(
    `INSERT INTO sync_queue (id, table_name, record_id, payload, operation, attempts, last_error, created_at)
     VALUES (?, ?, ?, ?, 'upsert', 0, NULL, datetime('now'));`,
    [id, tableName, recordId, JSON.stringify(payload)]
  );
}

export async function initDb() {
  await executeSqlAsync(`PRAGMA foreign_keys = ON;`);

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );`
  );

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      experience_level TEXT NOT NULL,
      goal TEXT NOT NULL,
      created_at TEXT NOT NULL
    );`
  );

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS active_cycles (
      id TEXT PRIMARY KEY,
      program_id TEXT NOT NULL,
      cycle_name TEXT NOT NULL,
      current_week INTEGER NOT NULL DEFAULT 1,
      current_session_id TEXT,
      current_phase TEXT,
      status TEXT NOT NULL DEFAULT 'active',
      sync_id TEXT UNIQUE,
      updated_at TEXT NOT NULL
    );`
  );

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS completed_workouts (
      id TEXT PRIMARY KEY,
      active_cycle_id TEXT,
      program_id TEXT NOT NULL,
      week INTEGER NOT NULL,
      session_id TEXT NOT NULL,
      completed_at TEXT NOT NULL,
      duration_seconds INTEGER,
      notes TEXT,
      sync_id TEXT UNIQUE,
      synced INTEGER NOT NULL DEFAULT 0
    );`
  );

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS completed_sets (
      id TEXT PRIMARY KEY,
      workout_id TEXT NOT NULL,
      exercise_id TEXT NOT NULL,
      set_number INTEGER NOT NULL,
      prescribed_weight REAL NOT NULL,
      actual_weight REAL NOT NULL,
      prescribed_reps INTEGER NOT NULL,
      actual_reps INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      sync_id TEXT UNIQUE,
      synced INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(workout_id) REFERENCES completed_workouts(id) ON DELETE CASCADE
    );`
  );

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS one_rep_maxes (
      id TEXT PRIMARY KEY,
      exercise_id TEXT NOT NULL,
      weight REAL NOT NULL,
      recorded_at TEXT NOT NULL,
      sync_id TEXT UNIQUE,
      synced INTEGER NOT NULL DEFAULT 0
    );`
  );

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS personal_records (
      id TEXT PRIMARY KEY,
      exercise_id TEXT NOT NULL,
      type TEXT NOT NULL,
      value REAL NOT NULL,
      workout_id TEXT NOT NULL,
      recorded_at TEXT NOT NULL,
      sync_id TEXT UNIQUE,
      synced INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(workout_id) REFERENCES completed_workouts(id) ON DELETE CASCADE
    );`
  );

  await executeSqlAsync(
    `CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      payload TEXT NOT NULL,
      operation TEXT NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      last_error TEXT,
      created_at TEXT NOT NULL
    );`
  );

  const rows = await queryRows<{ value: string }>(
    `SELECT value FROM settings WHERE key = 'schema_version' LIMIT 1;`
  );
  if (rows.length === 0) {
    await executeSqlAsync(
      `INSERT INTO settings (key, value) VALUES ('schema_version', ?);`,
      [String(CURRENT_SCHEMA_VERSION)]
    );
  }
}

export async function createOrUpdateUserProfile(input: {
  name: string;
  experienceLevel: string;
  goal: string;
}): Promise<UserProfile> {
  const existing = await queryRows<{
    id: string;
    name: string;
    experience_level: string;
    goal: string;
    created_at: string;
  }>(`SELECT * FROM users ORDER BY created_at DESC LIMIT 1;`);

  if (existing.length > 0) {
    const user = existing[0];
    await executeSqlAsync(
      `UPDATE users SET name = ?, experience_level = ?, goal = ? WHERE id = ?;`,
      [input.name, input.experienceLevel, input.goal, user.id]
    );
    return {
      id: user.id,
      name: input.name,
      experienceLevel: input.experienceLevel,
      goal: input.goal,
      createdAt: user.created_at,
    };
  }

  const id = createId('user');
  const createdAt = new Date().toISOString();
  await executeSqlAsync(
    `INSERT INTO users (id, name, experience_level, goal, created_at) VALUES (?, ?, ?, ?, ?);`,
    [id, input.name, input.experienceLevel, input.goal, createdAt]
  );
  return { id, name: input.name, experienceLevel: input.experienceLevel, goal: input.goal, createdAt };
}

export async function getLatestUserProfile(): Promise<UserProfile | null> {
  const rows = await queryRows<{
    id: string;
    name: string;
    experience_level: string;
    goal: string;
    created_at: string;
  }>(`SELECT * FROM users ORDER BY created_at DESC LIMIT 1;`);
  if (rows.length === 0) return null;
  const row = rows[0];
  return {
    id: row.id,
    name: row.name,
    experienceLevel: row.experience_level,
    goal: row.goal,
    createdAt: row.created_at,
  };
}

export async function startCycle(params: {
  programId: string;
  cycleName: string;
  currentWeek?: number;
  currentSessionId?: string | null;
  currentPhase?: string | null;
}): Promise<ActiveCycleRecord> {
  await executeSqlAsync(
    `UPDATE active_cycles SET status = 'paused', updated_at = datetime('now') WHERE status = 'active';`
  );

  const id = createId('cycle');
  const updatedAt = new Date().toISOString();
  const row = {
    id,
    program_id: params.programId,
    cycle_name: params.cycleName,
    current_week: params.currentWeek ?? 1,
    current_session_id: params.currentSessionId ?? null,
    current_phase: params.currentPhase ?? null,
    status: 'active',
    sync_id: null,
    updated_at: updatedAt,
  };

  await executeSqlAsync(
    `INSERT INTO active_cycles (
      id, program_id, cycle_name, current_week, current_session_id, current_phase, status, sync_id, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);`,
    [
      row.id,
      row.program_id,
      row.cycle_name,
      row.current_week,
      row.current_session_id,
      row.current_phase,
      row.status,
      row.sync_id,
      row.updated_at,
    ]
  );

  await queueSyncUpsert('active_cycles', id, row);

  return {
    id,
    programId: row.program_id,
    cycleName: row.cycle_name,
    currentWeek: row.current_week,
    currentSessionId: row.current_session_id,
    currentPhase: row.current_phase,
    status: 'active',
    syncId: null,
    updatedAt,
  };
}

export async function getActiveCycle(): Promise<ActiveCycleRecord | null> {
  const rows = await queryRows<{
    id: string;
    program_id: string;
    cycle_name: string;
    current_week: number;
    current_session_id: string | null;
    current_phase: string | null;
    status: 'active' | 'completed' | 'paused';
    sync_id: string | null;
    updated_at: string;
  }>(`SELECT * FROM active_cycles WHERE status = 'active' ORDER BY updated_at DESC LIMIT 1;`);

  if (rows.length === 0) return null;
  const row = rows[0];
  return {
    id: row.id,
    programId: row.program_id,
    cycleName: row.cycle_name,
    currentWeek: row.current_week,
    currentSessionId: row.current_session_id,
    currentPhase: row.current_phase,
    status: row.status,
    syncId: row.sync_id,
    updatedAt: row.updated_at,
  };
}

export async function updateActiveCycleProgress(params: {
  cycleId: string;
  currentWeek: number;
  currentSessionId?: string | null;
  currentPhase?: string | null;
}): Promise<void> {
  await executeSqlAsync(
    `UPDATE active_cycles
       SET current_week = ?, current_session_id = ?, current_phase = ?, updated_at = datetime('now')
     WHERE id = ?;`,
    [
      params.currentWeek,
      params.currentSessionId ?? null,
      params.currentPhase ?? null,
      params.cycleId,
    ]
  );
}

export async function saveCompletedWorkout(
  input: SaveWorkoutInput
): Promise<string> {
  const workoutId = createId('workout');
  const completedAt = new Date().toISOString();

  const workoutPayload = {
    id: workoutId,
    active_cycle_id: input.activeCycleId,
    program_id: input.programId,
    week: input.week,
    session_id: input.sessionId,
    completed_at: completedAt,
    duration_seconds: input.durationSeconds,
    notes: input.notes ?? null,
    sync_id: null,
    synced: 0,
  };

  await executeSqlAsync(
    `INSERT INTO completed_workouts (
      id, active_cycle_id, program_id, week, session_id, completed_at, duration_seconds, notes, sync_id, synced
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);`,
    [
      workoutPayload.id,
      workoutPayload.active_cycle_id,
      workoutPayload.program_id,
      workoutPayload.week,
      workoutPayload.session_id,
      workoutPayload.completed_at,
      workoutPayload.duration_seconds,
      workoutPayload.notes,
      workoutPayload.sync_id,
      workoutPayload.synced,
    ]
  );
  await queueSyncUpsert('completed_workouts', workoutId, workoutPayload);

  for (const set of input.sets) {
    const setId = createId('set');
    const setPayload = {
      id: setId,
      workout_id: workoutId,
      exercise_id: set.exerciseId,
      set_number: set.setNumber,
      prescribed_weight: set.prescribedWeight,
      actual_weight: set.actualWeight,
      prescribed_reps: set.prescribedReps,
      actual_reps: set.actualReps,
      created_at: completedAt,
      sync_id: null,
      synced: 0,
    };

    await executeSqlAsync(
      `INSERT INTO completed_sets (
        id, workout_id, exercise_id, set_number, prescribed_weight, actual_weight, prescribed_reps, actual_reps, created_at, sync_id, synced
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);`,
      [
        setPayload.id,
        setPayload.workout_id,
        setPayload.exercise_id,
        setPayload.set_number,
        setPayload.prescribed_weight,
        setPayload.actual_weight,
        setPayload.prescribed_reps,
        setPayload.actual_reps,
        setPayload.created_at,
        setPayload.sync_id,
        setPayload.synced,
      ]
    );
    await queueSyncUpsert('completed_sets', setId, setPayload);
  }

  return workoutId;
}

export async function listCompletedWorkouts(limit = 20): Promise<WorkoutSummary[]> {
  const rows = await queryRows<{
    id: string;
    program_id: string;
    week: number;
    session_id: string;
    completed_at: string;
    duration_seconds: number | null;
    notes: string | null;
  }>(
    `SELECT id, program_id, week, session_id, completed_at, duration_seconds, notes
       FROM completed_workouts
      ORDER BY completed_at DESC
      LIMIT ?;`,
    [limit]
  );

  return rows.map(row => ({
    id: row.id,
    programId: row.program_id,
    week: row.week,
    sessionId: row.session_id,
    completedAt: row.completed_at,
    durationSeconds: row.duration_seconds,
    notes: row.notes,
  }));
}

export async function getWeeklyVolume(limitWeeks = 8): Promise<WeeklyVolumePoint[]> {
  const rows = await queryRows<{ week_key: string; total_volume: number | null }>(
    `SELECT strftime('%Y-%W', w.completed_at) AS week_key,
            SUM(s.actual_weight * s.actual_reps) AS total_volume
       FROM completed_sets s
       JOIN completed_workouts w ON w.id = s.workout_id
      GROUP BY week_key
      ORDER BY week_key DESC
      LIMIT ?;`,
    [limitWeeks]
  );

  return rows
    .map(row => ({
      weekKey: row.week_key,
      totalVolume: row.total_volume ?? 0,
    }))
    .reverse();
}

export async function getEstimatedOneRmHistory(
  exerciseId: string
): Promise<OneRmPoint[]> {
  const rows = await queryRows<{
    created_at: string;
    actual_weight: number;
    actual_reps: number;
  }>(
    `SELECT created_at, actual_weight, actual_reps
       FROM completed_sets
      WHERE exercise_id = ?
      ORDER BY created_at ASC;`,
    [exerciseId]
  );

  return rows.map(row => ({
    date: row.created_at,
    value: row.actual_weight * (1 + row.actual_reps / 30),
  }));
}

export async function getPendingSyncJobs(limit = 20): Promise<SyncQueueJob[]> {
  const rows = await queryRows<{
    id: string;
    table_name: string;
    record_id: string;
    payload: string;
    operation: 'upsert' | 'delete';
    attempts: number;
    last_error: string | null;
  }>(
    `SELECT id, table_name, record_id, payload, operation, attempts, last_error
       FROM sync_queue
      ORDER BY created_at ASC
      LIMIT ?;`,
    [limit]
  );

  return rows.map(row => ({
    id: row.id,
    tableName: row.table_name,
    recordId: row.record_id,
    payload: row.payload,
    operation: row.operation,
    attempts: row.attempts,
    lastError: row.last_error,
  }));
}

export async function markSyncJobDone(jobId: string): Promise<void> {
  await executeSqlAsync(`DELETE FROM sync_queue WHERE id = ?;`, [jobId]);
}

export async function markSyncJobFailed(
  jobId: string,
  errorMessage: string
): Promise<void> {
  await executeSqlAsync(
    `UPDATE sync_queue
       SET attempts = attempts + 1, last_error = ?
     WHERE id = ?;`,
    [errorMessage, jobId]
  );
}
