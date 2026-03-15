export class GoogleGenerativeAI {
  constructor(_apiKey: string) {}

  getGenerativeModel(_config: unknown, _opts?: unknown) {
    return {
      generateContent: jest.fn(),
    };
  }
}
