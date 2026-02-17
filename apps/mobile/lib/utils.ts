import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function roundToNearestFive(value: number): number {
  // Round to nearest 5, with special handling for small values
  // Values <= 2.5 round to 0, values > 2.5 round to 5
  if (value <= 2.5) return 0;
  return Math.round(value / 5) * 5;
}

export function generateId(): string {
  return crypto.randomUUID();
}
