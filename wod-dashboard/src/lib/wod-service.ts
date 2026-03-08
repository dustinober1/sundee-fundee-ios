import { WOD, WODFormData, ProgramExercise } from '@/types/wod';
import { getPublicDB } from './cloudkit';

let schemaEnsured = false;

/**
 * In CloudKit Development, saving a record auto-creates the record type and fields.
 * We use this to bootstrap the WOD schema on first use.
 */
async function ensureSchema(): Promise<void> {
  if (schemaEnsured) return;

  const db = getPublicDB();

  // Try a lightweight query first — if it succeeds the type already exists
  // CloudKit JS does NOT throw on errors — it resolves with { hasErrors: true }
  const queryResp = await db.performQuery({ recordType: 'WOD' });

  if (!queryResp.hasErrors) {
    schemaEnsured = true;
    return;
  }

  // Check if the error is specifically about a missing record type
  const isNotFound = queryResp.errors?.some((e: any) =>
    e.ckErrorCode === 'NOT_FOUND' ||
    e.ckErrorCode === 'UNKNOWN_ERROR' ||
    (e.reason || '').includes('record_type') ||
    (e.serverErrorCode || '') === 'NOT_FOUND'
  );

  if (!isNotFound) {
    // Some other error (auth, network, etc.) — don't try to bootstrap
    console.warn('CloudKit query error (not a missing schema):', queryResp.errors);
    schemaEnsured = true;
    return;
  }

  console.log('WOD record type not found — bootstrapping schema...');

  // Save a seed record to auto-create the record type and all fields
  const seedRecord = {
    recordType: 'WOD',
    recordName: 'wod-schema-seed',
    fields: {
      id:            { value: 'wod-schema-seed' },
      date:          { value: '1970-01-01' },
      title:         { value: '__schema_seed__' },
      description:   { value: '' },
      templateType:  { value: 'strength' },
      publishDate:   { value: '1970-01-01' },
      status:        { value: 'draft' },
      exercisesJSON: { value: '[]' },
    },
  };

  const saveResp = await db.saveRecords([seedRecord]);
  if (saveResp.hasErrors) {
    console.error('Schema bootstrap save failed:', saveResp.errors);
    schemaEnsured = true;
    return;
  }

  console.log('WOD schema created. Cleaning up seed record...');

  // Clean up the seed record
  const delResp = await db.deleteRecords([{ recordName: 'wod-schema-seed', recordType: 'WOD' }]);
  if (delResp.hasErrors) {
    console.warn('Seed record cleanup failed (non-critical):', delResp.errors);
  }

  schemaEnsured = true;
}

function recordToWOD(record: any): WOD {
  return {
    id: record.fields.id?.value || '',
    date: record.fields.date?.value || '',
    title: record.fields.title?.value || '',
    description: record.fields.description?.value || '',
    templateType: record.fields.templateType?.value || 'strength',
    publishDate: record.fields.publishDate?.value || record.fields.date?.value || '',
    status: record.fields.status?.value || 'published',
    exercises: parseExercisesJSON(record.fields.exercisesJSON?.value),
  };
}

function parseExercisesJSON(json: string | undefined): ProgramExercise[] {
  if (!json) return [];
  try {
    return JSON.parse(json);
  } catch {
    return [];
  }
}

export async function fetchWODs(): Promise<WOD[]> {
  await ensureSchema();
  const db = getPublicDB();
  const query = { recordType: 'WOD', sortBy: [{ fieldName: 'date', ascending: false }] };

  const response = await db.performQuery(query);

  if (response.hasErrors) {
    const msg = response.errors?.[0]?.reason || 'Failed to fetch WODs';
    console.error('CloudKit query errors:', response.errors);
    throw new Error(msg);
  }

  return (response.records || []).map(recordToWOD);
}

export async function fetchWODByID(id: string): Promise<WOD | null> {
  const db = getPublicDB();

  try {
    const response = await db.fetchRecords([{ recordName: id, recordType: 'WOD' }]);

    if (response.hasErrors || !response.records?.length) {
      return null;
    }

    return recordToWOD(response.records[0]);
  } catch {
    return null;
  }
}

export async function saveWOD(data: WODFormData, originalDate?: string): Promise<WOD> {
  await ensureSchema();
  const db = getPublicDB();
  const recordName = `wod-${data.date}`;

  const fields = {
    id: { value: recordName },
    date: { value: data.date },
    title: { value: data.title },
    description: { value: data.description },
    templateType: { value: data.templateType },
    publishDate: { value: data.publishDate },
    status: { value: data.status },
    exercisesJSON: { value: JSON.stringify(data.exercises) },
  };

  // If the date changed, delete the old record first
  if (originalDate && originalDate !== data.date) {
    const oldRecordName = `wod-${originalDate}`;
    const delResp = await db.deleteRecords([{ recordName: oldRecordName, recordType: 'WOD' }]);
    if (delResp.hasErrors) {
      console.warn('Failed to delete old WOD record:', delResp.errors);
    }
  }

  // Try to fetch the existing record to get its recordChangeTag for updates
  let record: any = { recordType: 'WOD', recordName, fields };

  const fetchResp = await db.fetchRecords([{ recordName, recordType: 'WOD' }]);
  if (!fetchResp.hasErrors && fetchResp.records?.length) {
    const existing = fetchResp.records[0];
    record.recordChangeTag = existing.recordChangeTag;
  }

  const response = await db.saveRecords([record]);

  if (response.hasErrors) {
    const errorMsg = response.errors?.[0]?.reason || 'Failed to save WOD';
    throw new Error(errorMsg);
  }

  return recordToWOD(response.records[0]);
}

export async function deleteWOD(id: string): Promise<void> {
  const db = getPublicDB();

  const response = await db.deleteRecords([{ recordName: id, recordType: 'WOD' }]);

  if (response.hasErrors) {
    const errorMsg = response.errors?.[0]?.reason || 'Failed to delete WOD';
    throw new Error(errorMsg);
  }
}
