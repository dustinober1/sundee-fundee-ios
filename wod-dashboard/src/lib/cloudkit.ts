// CloudKit configuration for WOD Admin Dashboard
// API token must be generated at https://developer.apple.com/account/

const CONTAINER_ID = 'iCloud.com.sundeefundee.app';
const CLOUDKIT_BASE_URL = 'https://api.apple-cloudkit.com';

export interface CloudKitConfig {
  containerIdentifier: string;
  apiToken: string;
  environment: 'development' | 'production';
}

export function getCloudKitConfig(): CloudKitConfig {
  return {
    containerIdentifier: CONTAINER_ID,
    apiToken: process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN || '',
    environment:
      (process.env.NEXT_PUBLIC_CLOUDKIT_ENV as
        | 'development'
        | 'production') || 'development',
  };
}

export async function cloudKitFetch(path: string, body?: object) {
  const config = getCloudKitConfig();
  const url = `${CLOUDKIT_BASE_URL}/database/1/${config.containerIdentifier}/${config.environment}/public${path}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${config.apiToken}`,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  return response.json();
}
