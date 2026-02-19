/**
 * Transforms local (Dexie) records to Supabase row format.
 * Converts camelCase keys to snake_case and Date objects to ISO strings.
 * Injects user_id and updated_at fields.
 */
export function toSupabaseRows<T extends { id: string }>(
  records: T[],
  authUserId: string
): Record<string, unknown>[] {
  return records.map(r => {
    const row: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(r)) {
      const snakeKey = k.replace(/([A-Z])/g, '_$1').toLowerCase();
      row[snakeKey] = v instanceof Date ? v.toISOString() : v;
    }
    row['user_id'] = authUserId;
    row['updated_at'] = new Date().toISOString();
    return row;
  });
}

/**
 * Transforms Supabase rows to local (Dexie) record format.
 * Converts snake_case keys to camelCase and ISO date strings to Date objects.
 * Strips user_id and updated_at fields.
 */
export function fromSupabaseRows(
  rows: Record<string, unknown>[]
): Record<string, unknown>[] {
  return rows.map(row => {
    const record: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(row)) {
      if (k === 'user_id' || k === 'updated_at') continue;
      const camelKey = k.replace(/_([a-z])/g, (_, c: string) => c.toUpperCase());
      record[camelKey] =
        typeof v === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(v)
          ? new Date(v)
          : v;
    }
    return record;
  });
}
