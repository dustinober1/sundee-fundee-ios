# Domain Pitfalls

**Domain:** Offline-First Workout Tracking
**Researched:** 2026-02-17

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Naive Sync (Last-Write-Wins)
**What goes wrong:** A user edits a workout on their phone (offline). Then edits the *same* workout on their desktop. When the phone syncs, it overwrites the desktop changes (or vice versa), losing data.
**Why it happens:** Assuming sync is just "pushing the latest state".
**Consequences:** Data loss, user distrust.
**Prevention:** Use **Operational Transformation (OT)** or **CRDTs** (complex) OR simplistic field-level merging (easier). For this MVP, **Upsert with 'updatedAt' timestamp** is the 80/20 solution, but warn the user if a conflict is detected.
**Detection:** Check for `409 Conflict` errors during sync tests.

### Pitfall 2: Over-fetching from IndexedDB
**What goes wrong:** Loading the *entire* workout history to calculate one chart.
**Why it happens:** Dexie makes it easy to `toArray()`.
**Consequences:** App freezes on startup as history grows (300+ workouts).
**Prevention:** Always use `limit()` and `offset()` for lists. Use specialized "summary tables" (e.g., `oneRepMaxes`) for charts so you don't scan the `sets` table.
**Detection:** Monitor render times with React Profiler when loading dashboard.

## Moderate Pitfalls

### Pitfall 1: Timer State Loss
**What goes wrong:** User starts a 3-minute rest timer, switches to Instagram, comes back, and the timer is reset or gone.
**Prevention:** Store timer start timestamp in `localStorage` or `Dexie`. Calculate "time remaining" on mount based on `Date.now() - startTime`. Do *not* rely on `setInterval` state in memory.

### Pitfall 2: Tying Logic to UI
**What goes wrong:** Recommendation logic lives inside a React Component (`useEffect`).
**Why it happens:** Easy to prototype.
**Consequences:** Cannot run recommendations in a background worker or unit test them easily.
**Prevention:** Extract logic to pure TypeScript functions in `src/lib/`.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **Data Layer** | Schema migrations breakage | Test `db.version(x).stores(...)` upgrades carefully. Keep old versions in code. |
| **Sync** | Infinite sync loops | Ensure `synced` flag is set *only* after successful ACK from server. |
| **Charts** | Mobile layout breakage | Use `ResponsiveContainer` (Recharts) and test on small viewports (375px). |

## Sources

- [Dexie.js Best Practices](https://dexie.org/docs/Best-Practices)
- [Offline First Patterns](https://offlinefirst.org/)
