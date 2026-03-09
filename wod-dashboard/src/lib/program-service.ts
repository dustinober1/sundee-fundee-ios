/**
 * Program CRUD for CloudKit — follows wod-service.ts pattern.
 */

import { ProgramFormData, ProgramListItem } from '@/types/program';
import { validateProgram } from './program-validator';
import { getPublicDB } from './cloudkit';

let schemaEnsured = false;

/**
 * Bootstrap the Program record type in CloudKit.
 *
 * In Development: saving a record auto-creates the record type.
 * In Production: record types must be deployed from the Development schema
 * via CloudKit Dashboard first. If the type doesn't exist, we log a warning
 * and set a flag so callers can return empty results gracefully.
 */
let schemaMissing = false;

async function ensureSchema(): Promise<void> {
  if (schemaEnsured) return;

  const db = getPublicDB();
  const queryResp = await db.performQuery({ recordType: 'Program' });

  if (!queryResp.hasErrors) {
    schemaEnsured = true;
    schemaMissing = false;
    return;
  }

  console.log('Program query failed — attempting schema bootstrap...', queryResp.errors);

  const now = new Date().toISOString();
  const seedRecord = {
    recordType: 'Program',
    recordName: 'program-schema-seed',
    fields: {
      id: { value: 'program-schema-seed' },
      name: { value: '__schema_seed__' },
      category: { value: 'general' },
      description: { value: '' },
      durationWeeks: { value: 4 },
      sessionsPerWeek: { value: 3 },
      difficulty: { value: 'beginner' },
      status: { value: 'draft' },
      startDate: { value: '' },
      endDate: { value: '' },
      createdAt: { value: now },
      updatedAt: { value: now },
      weeksJSON: { value: '[]' },
      phasesJSON: { value: '[]' },
      cycleAdjustmentProfileJSON: { value: '' },
    },
  };

  const saveResp = await db.saveRecords([seedRecord]);
  if (saveResp.hasErrors) {
    console.error(
      'Schema bootstrap failed. If running in production, you must first create the ' +
      'Program record type in CloudKit Dashboard (Development environment), then deploy ' +
      'the schema to Production.',
      saveResp.errors,
    );
    schemaEnsured = true;
    schemaMissing = true;
    return;
  }

  console.log('Program schema created. Cleaning up seed record...');

  const delResp = await db.deleteRecords([
    { recordName: 'program-schema-seed', recordType: 'Program' },
  ]);
  if (delResp.hasErrors) {
    console.warn('Seed record cleanup failed (non-critical):', delResp.errors);
  }

  schemaEnsured = true;
  schemaMissing = false;
}

function recordToListItem(record: any): ProgramListItem {
  return {
    id: record.fields.id?.value || '',
    name: record.fields.name?.value || '',
    category: record.fields.category?.value || '',
    description: record.fields.description?.value || '',
    durationWeeks: record.fields.durationWeeks?.value || 0,
    sessionsPerWeek: record.fields.sessionsPerWeek?.value || 0,
    difficulty: record.fields.difficulty?.value || '',
    status: record.fields.status?.value || 'draft',
    startDate: record.fields.startDate?.value || null,
    endDate: record.fields.endDate?.value || null,
    createdAt: record.fields.createdAt?.value,
    updatedAt: record.fields.updatedAt?.value,
  };
}

function recordToProgram(record: any): ProgramFormData {
  const item = recordToListItem(record);
  return {
    ...item,
    durationWeeks: (item.durationWeeks as 4 | 8 | 12) || 4,
    phases: parseJSON(record.fields.phasesJSON?.value, []),
    weeks: parseJSON(record.fields.weeksJSON?.value, []),
    cycleAdjustmentProfile: parseJSON(record.fields.cycleAdjustmentProfileJSON?.value, null),
  };
}

function parseJSON<T>(json: string | undefined, fallback: T): T {
  if (!json) return fallback;
  try {
    return JSON.parse(json);
  } catch {
    return fallback;
  }
}

export async function fetchPrograms(): Promise<ProgramListItem[]> {
  await ensureSchema();

  if (schemaMissing) {
    return [];
  }

  const db = getPublicDB();
  const query = {
    recordType: 'Program',
    sortBy: [{ fieldName: 'name', ascending: true }],
  };

  const response = await db.performQuery(query);

  if (response.hasErrors) {
    const msg = response.errors?.[0]?.reason || 'Failed to fetch programs';
    console.error('CloudKit query errors:', response.errors);
    throw new Error(msg);
  }

  return (response.records || []).map(recordToListItem);
}

export async function fetchProgramByID(id: string): Promise<ProgramFormData | null> {
  const db = getPublicDB();

  try {
    const response = await db.fetchRecords([{ recordName: id, recordType: 'Program' }]);

    if (response.hasErrors || !response.records?.length) {
      return null;
    }

    return recordToProgram(response.records[0]);
  } catch {
    return null;
  }
}

export async function saveProgram(data: ProgramFormData): Promise<ProgramFormData> {
  const errors = validateProgram(data);
  if (errors.length > 0) {
    throw new Error(`Validation failed: ${errors.map((e) => e.message).join(', ')}`);
  }

  await ensureSchema();

  if (schemaMissing) {
    throw new Error(
      'Program record type does not exist in CloudKit. Switch NEXT_PUBLIC_CLOUDKIT_ENV ' +
      'to "development" in .env.local, save one program to create the schema, then deploy ' +
      'the schema to Production via CloudKit Dashboard.'
    );
  }

  const db = getPublicDB();
  const now = new Date().toISOString();

  const fields = {
    id: { value: data.id },
    name: { value: data.name },
    category: { value: data.category },
    description: { value: data.description },
    durationWeeks: { value: data.durationWeeks },
    sessionsPerWeek: { value: data.sessionsPerWeek },
    difficulty: { value: data.difficulty },
    status: { value: data.status },
    startDate: { value: data.startDate || '' },
    endDate: { value: data.endDate || '' },
    createdAt: { value: data.createdAt || now },
    updatedAt: { value: now },
    weeksJSON: { value: JSON.stringify(data.weeks) },
    phasesJSON: { value: JSON.stringify(data.phases) },
    cycleAdjustmentProfileJSON: {
      value: data.cycleAdjustmentProfile ? JSON.stringify(data.cycleAdjustmentProfile) : '',
    },
  };

  let record: any = { recordType: 'Program', recordName: data.id, fields };

  // Fetch existing record for recordChangeTag
  const fetchResp = await db.fetchRecords([{ recordName: data.id, recordType: 'Program' }]);
  if (!fetchResp.hasErrors && fetchResp.records?.length) {
    const existing = fetchResp.records[0];
    record.recordChangeTag = existing.recordChangeTag;
  }

  const response = await db.saveRecords([record]);

  if (response.hasErrors) {
    const errorMsg = response.errors?.[0]?.reason || 'Failed to save program';
    throw new Error(errorMsg);
  }

  return recordToProgram(response.records[0]);
}

export async function deleteProgram(id: string): Promise<void> {
  const db = getPublicDB();

  const response = await db.deleteRecords([{ recordName: id, recordType: 'Program' }]);

  if (response.hasErrors) {
    const errorMsg = response.errors?.[0]?.reason || 'Failed to delete program';
    throw new Error(errorMsg);
  }
}

export async function duplicateProgram(
  sourceId: string,
  newId: string
): Promise<ProgramFormData> {
  const source = await fetchProgramByID(sourceId);
  if (!source) {
    throw new Error(`Program '${sourceId}' not found`);
  }

  const now = new Date().toISOString();
  const duplicate: ProgramFormData = {
    ...source,
    id: newId,
    name: `${source.name} (Copy)`,
    status: 'draft',
    createdAt: now,
    updatedAt: now,
  };

  return saveProgram(duplicate);
}
