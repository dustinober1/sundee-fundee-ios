export function getErrorMessage(error: unknown, fallback = "Something went wrong. Please try again."): string {
  if (error instanceof Error && error.message.trim()) {
    return error.message;
  }
  return fallback;
}
