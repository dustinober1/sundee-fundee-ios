// CloudKit JS client-side integration
// Uses Apple's CloudKit JS SDK loaded via script tag in layout.tsx
// User must sign in with Apple ID to write to Public DB

const CONTAINER_ID = 'iCloud.com.sundeefundee.app';

let cloudKitConfigured = false;

function getCloudKit(): any {
  const ck = (window as any).CloudKit;
  if (!ck) {
    throw new Error('CloudKit JS not loaded. Make sure the script tag is in layout.tsx.');
  }
  return ck;
}

export function configureCloudKit() {
  if (cloudKitConfigured) return;

  const CloudKit = getCloudKit();
  const apiToken = process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN;

  if (!apiToken) {
    console.error('NEXT_PUBLIC_CLOUDKIT_API_TOKEN not set');
    return;
  }

  CloudKit.configure({
    containers: [{
      containerIdentifier: CONTAINER_ID,
      apiTokenAuth: {
        apiToken,
        persist: true,
      },
      environment: (process.env.NEXT_PUBLIC_CLOUDKIT_ENV as string) || 'development',
    }],
  });

  cloudKitConfigured = true;
}

export function getContainer(): any {
  configureCloudKit();
  return getCloudKit().getDefaultContainer();
}

export function getPublicDB(): any {
  return getContainer().publicCloudDatabase;
}

export async function signIn(): Promise<any> {
  const container = getContainer();
  return container.setUpAuth();
}

export async function isSignedIn(): Promise<boolean> {
  try {
    const container = getContainer();
    const userIdentity = await container.fetchCurrentUserIdentity();
    return !!userIdentity;
  } catch {
    return false;
  }
}
