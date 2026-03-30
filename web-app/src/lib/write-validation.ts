export function requireTrimmedString(value: string, field: string): string {
  const trimmed = value.trim();
  if (!trimmed) {
    throw new Error(`${field} is required.`);
  }
  return trimmed;
}

export function optionalTrimmedString(value: string | undefined): string | undefined {
  if (value == null) return undefined;
  const trimmed = value.trim();
  return trimmed ? trimmed : undefined;
}

interface NumberOptions {
  integer?: boolean;
  min?: number;
  max?: number;
}

export function requireFiniteNumber(value: number, field: string, options: NumberOptions = {}): number {
  if (!Number.isFinite(value)) {
    throw new Error(`${field} must be a valid number.`);
  }
  if (options.integer && !Number.isInteger(value)) {
    throw new Error(`${field} must be a whole number.`);
  }
  if (options.min != null && value < options.min) {
    throw new Error(`${field} must be at least ${options.min}.`);
  }
  if (options.max != null && value > options.max) {
    throw new Error(`${field} must be at most ${options.max}.`);
  }
  return value;
}

export function optionalFiniteNumber(
  value: number | undefined,
  field: string,
  options: NumberOptions = {}
): number | undefined {
  if (value == null) return undefined;
  return requireFiniteNumber(value, field, options);
}

export function requireDateInput(value: string, field: string): Date {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) {
    throw new Error(`${field} must be a valid date.`);
  }

  const [, yearRaw, monthRaw, dayRaw] = match;
  const year = Number(yearRaw);
  const month = Number(monthRaw);
  const day = Number(dayRaw);
  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    throw new Error(`${field} must be a valid date.`);
  }

  return date;
}

export function requireOneOf<T extends string>(
  value: string,
  allowed: readonly T[],
  field: string
): T {
  if (!allowed.includes(value as T)) {
    throw new Error(`${field} is invalid.`);
  }
  return value as T;
}
