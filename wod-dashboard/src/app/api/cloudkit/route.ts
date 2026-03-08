import { NextRequest, NextResponse } from 'next/server';

const CONTAINER_ID = 'iCloud.com.sundeefundee.app';
const CLOUDKIT_BASE_URL = 'https://api.apple-cloudkit.com';

export async function POST(request: NextRequest) {
  const { path, body } = await request.json();

  if (!path || typeof path !== 'string') {
    return NextResponse.json({ error: 'path is required' }, { status: 400 });
  }

  const apiToken = process.env.CLOUDKIT_API_TOKEN;
  const environment = process.env.CLOUDKIT_ENV || 'development';

  if (!apiToken) {
    return NextResponse.json({ error: 'CloudKit API token not configured' }, { status: 500 });
  }

  const url = `${CLOUDKIT_BASE_URL}/database/1/${CONTAINER_ID}/${environment}/public${path}`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiToken}`,
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error('CloudKit proxy error:', error);
    return NextResponse.json({ error: 'CloudKit request failed' }, { status: 502 });
  }
}
