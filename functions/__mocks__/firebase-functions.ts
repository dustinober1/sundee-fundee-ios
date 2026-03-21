// Mock for firebase-functions/v2/https

export class HttpsError extends Error {
  code: string;
  details?: unknown;
  constructor(code: string, message: string, details?: unknown) {
    super(message);
    this.name = 'HttpsError';
    this.code = code;
    this.details = details;
  }
}

// Captures the handler so tests can call it directly
let _lastHandler: ((request: MockCallableRequest) => Promise<unknown>) | null = null;

export interface MockCallableRequest {
  auth?: { uid: string; token?: Record<string, unknown> } | null;
  data: Record<string, unknown>;
}

export function onCall(
  _optionsOrHandler:
    | { secrets?: unknown[]; region?: string }
    | ((request: MockCallableRequest) => Promise<unknown>),
  handler?: (request: MockCallableRequest) => Promise<unknown>
) {
  const fn = typeof _optionsOrHandler === 'function' ? _optionsOrHandler : handler!;
  _lastHandler = fn;
  // Return a callable wrapper that tests can invoke
  return async (request: MockCallableRequest) => fn(request);
}

export function getLastHandler() {
  return _lastHandler;
}

// onRequest mock — returns an async wrapper so tests can invoke it directly
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function onRequest(
  _optionsOrHandler:
    | { secrets?: unknown[]; region?: string }
    | ((request: unknown, response: unknown) => Promise<void>),
  handler?: (request: unknown, response: unknown) => Promise<void>
) {
  const fn = typeof _optionsOrHandler === 'function' ? _optionsOrHandler : handler!;
  return async (request: unknown, response: unknown) => fn(request, response);
}
