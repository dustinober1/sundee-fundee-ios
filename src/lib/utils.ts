import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function roundToNearestFive(value: number): number {
  return Math.round(value / 5) * 5;
}

export function generateId(): string {
  return crypto.randomUUID();
}
