import { WOD, WODFormData, ProgramExercise } from '@/types/wod';
import { getPublicDB } from './cloudkit';

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
  const db = getPublicDB();
  const query = { recordType: 'WOD', sortBy: [{ fieldName: 'date', ascending: false }] };

  const response = await db.performQuery(query);

  if (response.hasErrors) {
    console.error('CloudKit query errors:', response.errors);
    return [];
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

export async function saveWOD(data: WODFormData): Promise<WOD> {
  const db = getPublicDB();
  const recordName = `wod-${data.date}`;

  const record = {
    recordType: 'WOD',
    recordName,
    fields: {
      id: { value: recordName },
      date: { value: data.date },
      title: { value: data.title },
      description: { value: data.description },
      templateType: { value: data.templateType },
      publishDate: { value: data.publishDate },
      status: { value: data.status },
      exercisesJSON: { value: JSON.stringify(data.exercises) },
    },
  };

  const response = await db.saveRecords([record], { zoneName: '_defaultZone' });

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
