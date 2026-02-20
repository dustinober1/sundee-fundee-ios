# Phase 5: Rebrand — Context

**Phase goal:** Users and developers see "Sundee-Fundee" consistently everywhere the app name appears — browser tabs, metadata, page copy, and config files — with zero functional regression.

**Discussed:** 2026-02-20  
**Areas covered:** A (Display name formatting), B (Onboarding & UI copy tone), C (App metadata & description), D (Audit breadth)

---

## A — Display Name Formatting

- **Primary form:** Always `Sundee-Fundee` — hyphen, mixed case, no exceptions for body copy, headers, or labels.
- **No line-wrap:** Treat `Sundee-Fundee` as a single unbreakable unit (CSS `white-space: nowrap` or `&nbsp;` where needed to prevent the hyphen from splitting across lines).
- **Compact/ultra-short contexts:** `SF` is acceptable for `aria-label` values, `alt` attributes on favicon-adjacent images, and other sub-8-char slots — nowhere visible as primary copy.
- **PWA `short_name`:** `SundeeFundee` (no hyphen, 12 chars — satisfies the 12-char manifest limit). This field lives in Phase 6 but the value is decided here.

---

## B — Onboarding & UI Copy Tone

- **Scope:** Full rewrite — all user-visible copy including onboarding, dashboard, workout screens, progress page, button labels, and empty states. Not a find-and-replace.
- **Tone:** Warm & friendly. Encouraging, casual, like a supportive training partner. Not gym-coach intensity, not minimal/clinical — human and approachable.
- **Tagline:** `Own your gains.` — appears as a sub-headline beneath `Sundee-Fundee` on the onboarding welcome screen (and anywhere a branded sub-headline is appropriate).
- **Guiding principle for rewrite:** Copy should feel like it was written *for* Sundee-Fundee, not ported from a generic app. Every sentence should pass the "does this sound like a supportive training partner?" test.

---

## C — App Metadata & Description

- **`<title>` tag:** `Sundee-Fundee | Own your gains` — same on every route (root, dashboard, workout, progress, settings). No per-page prefix.
- **`<meta name="description">`:** `Track your strength training, log workouts, and own your gains with Sundee-Fundee.`
- **Open Graph tags:** Update in Phase 5.
  - `og:title`: `Sundee-Fundee | Own your gains`
  - `og:description`: same as `<meta name="description">`
- **`apple-mobile-web-app-title`:** `SundeeFundee` (no hyphen — matches PWA `short_name`). Lives in Phase 6 but value is locked here.

---

## D — Audit Breadth

**Files to update:**
- `src/` — all app source files (subject to frozen exceptions below)
- `README.md`
- `CLAUDE.md`
- `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`
- `package.json` → `name` field updated to `"sundee-fundee"`

**Frozen — do not change:**
| Item | Location | Reason |
|------|----------|--------|
| `super('StrengthApp')` | `src/lib/db/dexie.ts` | Changing silently destroys all user IndexedDB data |
| `analyzeStrengthPatterns` (and other domain function names) | Various `src/lib/` files | Domain terminology, not brand |
| `<SelectItem value="strength">` | Onboarding UI | Fitness term, not app name |

**Acceptable remaining hits after audit (`grep -ri "strength"`):**
1. The three frozen items above
2. `"strength"` lowercase used as a fitness noun in UI copy (e.g., "build strength", "strength training", "your strength journey") — these are fitness terms, not brand references

**Audit command (success gate):**
```bash
grep -r "Strength" src/ README.md CLAUDE.md package.json .planning/
# Only acceptable hits: StrengthApp (IDB), analyzeStrengthPatterns, strength as fitness noun
```

---

## Deferred Ideas (out of Phase 5 scope)

- Per-page `<title>` prefixes (e.g., "Dashboard • Sundee-Fundee") — noted for future polish
- Brand color palette / visual identity beyond copy — noted for future design phase
