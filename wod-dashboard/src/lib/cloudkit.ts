// CloudKit configuration for WOD Admin Dashboard
// All CloudKit calls are proxied through /api/cloudkit to avoid CORS issues.
// The API token is stored server-side only (CLOUDKIT_API_TOKEN, no NEXT_PUBLIC_ prefix).

export async function cloudKitFetch(path: string, body?: object) {
  const response = await fetch('/api/cloudkit', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ path, body }),
  });

  return response.json();
}
