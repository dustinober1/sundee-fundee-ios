interface TimestampLike {
  toDate(): Date;
}

function isTimestampLike(value: unknown): value is TimestampLike {
  return typeof value === "object" && value !== null && "toDate" in value && typeof (value as TimestampLike).toDate === "function";
}

function pad(value: number): string {
  return value.toString().padStart(2, "0");
}

export function parseDateInputValue(value: string): Date {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (match) {
    const [, yearRaw, monthRaw, dayRaw] = match;
    return new Date(Number(yearRaw), Number(monthRaw) - 1, Number(dayRaw));
  }

  const fallback = new Date(value);
  if (Number.isNaN(fallback.getTime())) {
    throw new Error(`Invalid date input: ${value}`);
  }

  return new Date(
    fallback.getUTCFullYear(),
    fallback.getUTCMonth(),
    fallback.getUTCDate()
  );
}

export function formatDateInputValue(date: Date): string {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function coerceStoredDateToLocalDate(value: unknown): Date | null {
  if (value == null) return null;

  if (isTimestampLike(value)) {
    value = value.toDate();
  }

  if (value instanceof Date) {
    return new Date(value.getUTCFullYear(), value.getUTCMonth(), value.getUTCDate());
  }

  if (typeof value === "string") {
    return parseDateInputValue(value);
  }

  return null;
}
