import { getPublicDB } from './cloudkit';

export interface AdminUser {
  appleUserID: string;
  role: 'owner' | 'coach';
}

// Check if a user is an admin by querying CloudKit for AdminUser records
export async function checkAdminAccess(appleUserID: string): Promise<AdminUser | null> {
  const db = getPublicDB();

  const query = {
    recordType: 'AdminUser',
    filterBy: [{
      fieldName: 'appleUserID',
      comparator: 'EQUALS',
      fieldValue: { value: appleUserID },
    }],
  };

  try {
    const response = await db.performQuery(query);
    const records = response.records || [];
    if (records.length === 0) return null;

    return {
      appleUserID: records[0].fields.appleUserID.value,
      role: records[0].fields.role.value,
    };
  } catch {
    return null;
  }
}

// Add a new admin user
export async function addAdmin(appleUserID: string, role: 'owner' | 'coach'): Promise<void> {
  const db = getPublicDB();

  const record = {
    recordType: 'AdminUser',
    recordName: `admin-${appleUserID}`,
    fields: {
      appleUserID: { value: appleUserID },
      role: { value: role },
    },
  };

  await db.saveRecords([record]);
}

// Remove an admin user
export async function removeAdmin(appleUserID: string): Promise<void> {
  const db = getPublicDB();
  await db.deleteRecords([{ recordName: `admin-${appleUserID}`, recordType: 'AdminUser' }]);
}
