import { WOD, WODFormData, ProgramExercise } from '@/types/wod';
import { cloudKitFetch } from './cloudkit';

// Convert CloudKit record to WOD
function recordToWOD(record: any): WOD {
  const fields = record.fields;
  return {
    id: fields.id?.value || '',
    date: fields.date?.value || '',
    title: fields.title?.value || '',
    description: fields.description?.value || '',
    templateType: fields.templateType?.value || 'strength',
    publishDate: fields.publishDate?.value || fields.date?.value || '',
    status: fields.status?.value || 'published',
    exercises: parseExercisesJSON(fields.exercisesJSON?.value),
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

// Convert WOD form data to CloudKit record fields
function wodToFields(data: WODFormData) {
  return {
    id: { value: `wod-${data.date}` },
    date: { value: data.date },
    title: { value: data.title },
    description: { value: data.description },
    templateType: { value: data.templateType },
    publishDate: { value: data.publishDate },
    status: { value: data.status },
    exercisesJSON: { value: JSON.stringify(data.exercises) },
  };
}

export async function fetchWODs(): Promise<WOD[]> {
  const response = await cloudKitFetch('/records/query', {
    query: {
      recordType: 'WOD',
      sortBy: [{ fieldName: 'date', ascending: false }],
    },
  });
  return (response.records || []).map(recordToWOD);
}

export async function fetchWODByID(id: string): Promise<WOD | null> {
  const response = await cloudKitFetch('/records/lookup', {
    records: [{ recordName: id }],
  });
  const records = response.records || [];
  if (records.length === 0 || records[0].serverErrorCode) return null;
  return recordToWOD(records[0]);
}

export async function saveWOD(data: WODFormData): Promise<WOD> {
  const recordName = `wod-${data.date}`;
  const response = await cloudKitFetch('/records/modify', {
    operations: [
      {
        operationType: 'forceReplace',
        record: {
          recordType: 'WOD',
          recordName,
          fields: wodToFields(data),
        },
      },
    ],
  });
  const savedRecord = response.records?.[0];
  if (!savedRecord || savedRecord.serverErrorCode) {
    throw new Error(savedRecord?.serverErrorCode || 'Failed to save WOD');
  }
  return recordToWOD(savedRecord);
}

export async function deleteWOD(id: string): Promise<void> {
  await cloudKitFetch('/records/modify', {
    operations: [
      {
        operationType: 'delete',
        record: { recordName: id, recordType: 'WOD' },
      },
    ],
  });
}
