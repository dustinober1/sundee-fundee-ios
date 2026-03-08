export interface AdminUser {
  appleUserID: string;
  role: 'owner' | 'coach';
}

// Apple Sign In configuration
// Requires: Services ID configured in Apple Developer Console
// Requires: Domain + return URL verified
export function getAppleSignInConfig() {
  return {
    clientId: process.env.NEXT_PUBLIC_APPLE_CLIENT_ID || '',
    redirectURI: process.env.NEXT_PUBLIC_APPLE_REDIRECT_URI || '',
    scope: 'name email',
    usePopup: true,
  };
}

// Check if a user is an admin by querying CloudKit for AdminUser records
export async function checkAdminAccess(appleUserID: string): Promise<AdminUser | null> {
  const { cloudKitFetch } = await import('./cloudkit');

  const response = await cloudKitFetch('/records/query', {
    query: {
      recordType: 'AdminUser',
      filterBy: [{
        fieldName: 'appleUserID',
        comparator: 'EQUALS',
        fieldValue: { value: appleUserID },
      }],
    },
  });

  const records = response.records || [];
  if (records.length === 0) return null;

  return {
    appleUserID: records[0].fields.appleUserID.value,
    role: records[0].fields.role.value,
  };
}

// Add a new admin user
export async function addAdmin(appleUserID: string, role: 'owner' | 'coach'): Promise<void> {
  const { cloudKitFetch } = await import('./cloudkit');

  await cloudKitFetch('/records/modify', {
    operations: [{
      operationType: 'forceReplace',
      record: {
        recordType: 'AdminUser',
        recordName: `admin-${appleUserID}`,
        fields: {
          appleUserID: { value: appleUserID },
          role: { value: role },
        },
      },
    }],
  });
}

// Remove an admin user
export async function removeAdmin(appleUserID: string): Promise<void> {
  const { cloudKitFetch } = await import('./cloudkit');

  await cloudKitFetch('/records/modify', {
    operations: [{
      operationType: 'delete',
      record: {
        recordName: `admin-${appleUserID}`,
        recordType: 'AdminUser',
      },
    }],
  });
}
