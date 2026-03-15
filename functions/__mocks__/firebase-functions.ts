export const onCall = (
  _config: unknown,
  handler: (request: unknown) => unknown
) => handler;

export const onRequest = (
  _config: unknown,
  handler: (request: unknown, response: unknown) => unknown
) => handler;

export class HttpsError extends Error {
  constructor(
    public code: string,
    message: string
  ) {
    super(message);
    this.name = "HttpsError";
  }
}
