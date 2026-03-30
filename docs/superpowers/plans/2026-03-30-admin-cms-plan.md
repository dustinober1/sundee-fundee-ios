# Admin CMS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the standalone `wod-dashboard/` with a full CMS integrated into `web-app/` under `/admin`, covering training content, users, subscriptions, blog, AI oversight, and analytics.

**Architecture:** Admin pages live in `src/app/(admin)/admin/` with a sidebar layout, Firebase Auth + admin allowlist for access control, and Firestore as the single data store (replacing JSON files and CloudKit). All existing UI primitives and Art Deco design tokens are reused.

**Tech Stack:** Next.js 16, React 19, Tailwind CSS 4, Firebase Admin SDK, Stripe API, Tiptap (WYSIWYG), sanitize-html, Vitest

---

## File Structure Overview

### New Files

```
web-app/src/
├── app/(admin)/
│   ├── layout.tsx                              # Admin shell with auth gate
│   └── admin/
│       ├── page.tsx                            # Dashboard home
│       ├── users/page.tsx                      # User management
│       ├── subscriptions/page.tsx              # Subscription overview
│       ├── workouts/
│       │   ├── wods/page.tsx                   # WOD management
│       │   ├── programs/page.tsx               # Program management
│       │   └── benchmarks/page.tsx             # Benchmark management
│       ├── content/
│       │   ├── blog/page.tsx                   # Blog editor
│       │   └── support/page.tsx                # Support articles
│       ├── ai/
│       │   ├── page.tsx                        # AI generation history
│       │   ├── prompts/page.tsx                # Prompt management
│       │   └── rate-limits/page.tsx            # Rate limit config
│       ├── catalog/page.tsx                    # Exercise catalog (editable)
│       └── settings/page.tsx                   # Admin settings
├── app/api/admin/
│   ├── stats/route.ts                          # Dashboard stats
│   ├── users/route.ts                          # User list
│   ├── users/[uid]/route.ts                    # User detail
│   ├── wods/route.ts                           # WOD CRUD
│   ├── wods/[id]/route.ts                      # Single WOD
│   ├── programs/route.ts                       # Program CRUD
│   ├── programs/[id]/route.ts                  # Single program
│   ├── benchmarks/route.ts                     # Benchmark CRUD
│   ├── benchmarks/[id]/route.ts                # Single benchmark
│   ├── catalog/route.ts                        # Exercise catalog CRUD
│   ├── catalog/[id]/route.ts                   # Single exercise
│   ├── blog/route.ts                           # Blog CRUD
│   ├── blog/[slug]/route.ts                    # Single post
│   ├── support/route.ts                        # Support article CRUD
│   ├── support/[slug]/route.ts                 # Single article
│   ├── ai/generations/route.ts                 # AI generation list
│   ├── ai/prompts/route.ts                     # Prompt CRUD
│   ├── ai/prompts/[id]/route.ts                # Single prompt
│   ├── settings/route.ts                       # Admin settings
│   ├── export/[collection]/route.ts            # JSON export
│   └── import/[collection]/route.ts            # JSON import
├── components/admin/
│   ├── admin-shell.tsx                         # Sidebar + header + content wrapper
│   ├── admin-sidebar.tsx                       # Nav sidebar
│   ├── admin-header.tsx                        # Top header bar
│   ├── data-table.tsx                          # Reusable sortable/filterable table
│   ├── detail-panel.tsx                        # Right-side editor panel
│   ├── stat-card.tsx                           # Dashboard metric card
│   ├── rich-text-editor.tsx                    # Tiptap WYSIWYG wrapper
│   ├── search-command.tsx                      # Cmd+K command palette
│   ├── empty-state.tsx                         # Empty state component
│   └── confirm-dialog.tsx                      # Destructive action confirmation
├── lib/
│   ├── admin-auth.ts                           # requireAdmin() helper
│   ├── admin-firestore.ts                      # Admin Firestore helpers
│   ├── sanitize.ts                             # HTML sanitization wrapper
│   └── domain/admin-types.ts                   # Admin-specific type definitions
scripts/
└── migrate-to-firestore.ts                     # One-time migration script
```

### Modified Files

```
web-app/src/middleware.ts                       # Add /admin/* to protected routes
web-app/src/lib/blog.ts                         # Switch from MDX files to Firestore
web-app/src/app/(marketing)/blog/page.tsx       # Read from Firestore
web-app/src/app/(marketing)/blog/[slug]/page.tsx # Read from Firestore
web-app/package.json                            # Add Tiptap + sanitize-html, remove gray-matter/next-mdx-remote
web-app/firestore.rules                         # Add admin collection rules
```

### Deleted (Post-Migration)

```
wod-dashboard/                                  # Entire directory
content/blog/*.mdx                              # Blog posts moved to Firestore
```

---

## Task 1: Install Dependencies

**Files:**
- Modify: `web-app/package.json`

- [ ] **Step 1: Install Tiptap and sanitize-html packages**

```bash
cd web-app && npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-link @tiptap/extension-image @tiptap/extension-code-block-lowlight @tiptap/extension-placeholder @tiptap/pm sanitize-html && npm install -D @types/sanitize-html
```

- [ ] **Step 2: Verify build still passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
cd web-app && git add package.json package-lock.json && git commit -m "chore: add Tiptap WYSIWYG editor and sanitize-html dependencies"
```

---

## Task 2: Admin Type Definitions

**Files:**
- Create: `web-app/src/lib/domain/admin-types.ts`
- Test: `web-app/src/lib/domain/__tests__/admin-types.test.ts`

- [ ] **Step 1: Write tests for type helpers and encode/decode functions**

```typescript
// web-app/src/lib/domain/__tests__/admin-types.test.ts
import { describe, it, expect } from "vitest";
import {
  type ExerciseValue,
  type ProgramExercise,
  encodeExerciseValue,
  decodeExerciseValue,
  exerciseToFirestore,
  exerciseFromFirestore,
  slugify,
} from "../admin-types";

describe("ExerciseValue encode/decode", () => {
  it("encodes fixed value as number", () => {
    expect(encodeExerciseValue({ type: "fixed", value: 5 })).toBe(5);
  });

  it("encodes amrap as string", () => {
    expect(encodeExerciseValue({ type: "amrap" })).toBe("AMRAP");
  });

  it("encodes range as array", () => {
    expect(encodeExerciseValue({ type: "range", low: 8, high: 12 })).toEqual([8, 12]);
  });

  it("encodes text as string", () => {
    expect(encodeExerciseValue({ type: "text", text: "Max effort" })).toBe("Max effort");
  });

  it("decodes number as fixed", () => {
    expect(decodeExerciseValue(5)).toEqual({ type: "fixed", value: 5 });
  });

  it("decodes AMRAP string as amrap", () => {
    expect(decodeExerciseValue("AMRAP")).toEqual({ type: "amrap" });
  });

  it("decodes amrap case-insensitive", () => {
    expect(decodeExerciseValue("amrap")).toEqual({ type: "amrap" });
  });

  it("decodes 2-element array as range", () => {
    expect(decodeExerciseValue([8, 12])).toEqual({ type: "range", low: 8, high: 12 });
  });

  it("decodes hyphenated string as range", () => {
    expect(decodeExerciseValue("8-12")).toEqual({ type: "range", low: 8, high: 12 });
  });

  it("decodes numeric string as fixed", () => {
    expect(decodeExerciseValue("5")).toEqual({ type: "fixed", value: 5 });
  });

  it("decodes arbitrary string as text", () => {
    expect(decodeExerciseValue("Max effort")).toEqual({ type: "text", text: "Max effort" });
  });
});

describe("exerciseToFirestore / exerciseFromFirestore", () => {
  it("round-trips a full exercise", () => {
    const exercise: ProgramExercise = {
      exercise: "Back Squat",
      variant: "Low Bar",
      sets: { type: "fixed", value: 5 },
      reps: { type: "range", low: 3, high: 5 },
      percent1RM: 0.8,
      restMinutes: 3,
      notes: "Pause at bottom",
      bodyweightOnly: false,
    };
    const encoded = exerciseToFirestore(exercise);
    const decoded = exerciseFromFirestore(encoded);
    expect(decoded).toEqual(exercise);
  });

  it("normalizes percent1RM > 1.5 as divided by 100", () => {
    const encoded = { exercise: "Bench", sets: 3, reps: 5, percent1RM: 80 };
    const decoded = exerciseFromFirestore(encoded);
    expect(decoded.percent1RM).toBe(0.8);
  });

  it("omits undefined optional fields", () => {
    const exercise: ProgramExercise = {
      exercise: "Push-up",
      sets: { type: "fixed", value: 3 },
      reps: { type: "fixed", value: 10 },
    };
    const encoded = exerciseToFirestore(exercise);
    expect(encoded).not.toHaveProperty("variant");
    expect(encoded).not.toHaveProperty("percent1RM");
    expect(encoded).not.toHaveProperty("restMinutes");
    expect(encoded).not.toHaveProperty("notes");
    expect(encoded).not.toHaveProperty("bodyweightOnly");
  });
});

describe("slugify", () => {
  it("lowercases and replaces spaces with hyphens", () => {
    expect(slugify("My Cool Program")).toBe("my-cool-program");
  });

  it("removes non-alphanumeric characters", () => {
    expect(slugify("Hello, World!")).toBe("hello-world");
  });

  it("collapses multiple hyphens", () => {
    expect(slugify("foo---bar")).toBe("foo-bar");
  });

  it("trims leading and trailing hyphens", () => {
    expect(slugify("--hello--")).toBe("hello");
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd web-app && npm test -- src/lib/domain/__tests__/admin-types.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Implement admin types**

```typescript
// web-app/src/lib/domain/admin-types.ts

// --- ExerciseValue (migrated from wod-dashboard) ---

export type ExerciseValue =
  | { type: "fixed"; value: number }
  | { type: "amrap" }
  | { type: "range"; low: number; high: number }
  | { type: "text"; text: string };

export type ExerciseValueJSON = number | string | [number, number];

export function encodeExerciseValue(val: ExerciseValue): ExerciseValueJSON {
  switch (val.type) {
    case "fixed":
      return val.value;
    case "amrap":
      return "AMRAP";
    case "range":
      return [val.low, val.high];
    case "text":
      return val.text;
  }
}

export function decodeExerciseValue(raw: ExerciseValueJSON): ExerciseValue {
  if (Array.isArray(raw) && raw.length === 2) {
    return { type: "range", low: raw[0], high: raw[1] };
  }
  if (typeof raw === "number") {
    return { type: "fixed", value: Math.trunc(raw) };
  }
  if (typeof raw === "string") {
    if (raw.toLowerCase() === "amrap") return { type: "amrap" };
    const hyphen = raw.match(/^(\d+)-(\d+)$/);
    if (hyphen) return { type: "range", low: Number(hyphen[1]), high: Number(hyphen[2]) };
    if (/^\d+$/.test(raw)) return { type: "fixed", value: Number(raw) };
    return { type: "text", text: raw };
  }
  return { type: "text", text: String(raw) };
}

// --- ProgramExercise ---

export interface ProgramExercise {
  exercise: string;
  variant?: string;
  sets: ExerciseValue;
  reps: ExerciseValue;
  percent1RM?: number;
  restMinutes?: number;
  notes?: string;
  bodyweightOnly?: boolean;
}

export interface ProgramExerciseFirestore {
  exercise: string;
  variant?: string;
  sets: ExerciseValueJSON;
  reps: ExerciseValueJSON;
  percent1RM?: number;
  restMinutes?: number;
  notes?: string;
  bodyweightOnly?: boolean;
}

export function exerciseToFirestore(ex: ProgramExercise): ProgramExerciseFirestore {
  const result: ProgramExerciseFirestore = {
    exercise: ex.exercise,
    sets: encodeExerciseValue(ex.sets),
    reps: encodeExerciseValue(ex.reps),
  };
  if (ex.variant !== undefined) result.variant = ex.variant;
  if (ex.percent1RM !== undefined) result.percent1RM = ex.percent1RM;
  if (ex.restMinutes !== undefined) result.restMinutes = ex.restMinutes;
  if (ex.notes !== undefined) result.notes = ex.notes;
  if (ex.bodyweightOnly !== undefined) result.bodyweightOnly = ex.bodyweightOnly;
  return result;
}

export function exerciseFromFirestore(json: ProgramExerciseFirestore): ProgramExercise {
  const result: ProgramExercise = {
    exercise: json.exercise,
    sets: decodeExerciseValue(json.sets),
    reps: decodeExerciseValue(json.reps),
  };
  if (json.variant !== undefined) result.variant = json.variant;
  if (json.percent1RM !== undefined) {
    result.percent1RM = json.percent1RM > 1.5 ? json.percent1RM / 100 : json.percent1RM;
  }
  if (json.restMinutes !== undefined) result.restMinutes = json.restMinutes;
  if (json.notes !== undefined) result.notes = json.notes;
  if (json.bodyweightOnly !== undefined) result.bodyweightOnly = json.bodyweightOnly;
  return result;
}

// --- Slugify ---

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/[\s-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

// --- WOD ---

export interface WOD {
  id: string;
  date: string;
  title: string;
  description: string;
  exercises: ProgramExercise[];
}

// --- Program ---

export interface ProgramPhase {
  id: string;
  name: string;
  goal: string;
  weekRange: number[];
}

export interface ProgramSession {
  sessionId: string;
  sessionName: string;
  sessionType: string;
  focus: string;
  exercises: ProgramExercise[];
}

export interface ProgramWeek {
  week: number;
  phaseId?: string;
  isTestWeek?: boolean;
  sessions: ProgramSession[];
}

export interface ProgramPhaseAdjustmentSettings {
  loadMultiplier: number;
  setsMultiplier: number;
  repsMultiplier: number;
}

export interface ProgramCycleAdjustmentProfile {
  fallbackPhase: string;
  lowConfidenceScale: number;
  phaseSettings: Record<string, ProgramPhaseAdjustmentSettings>;
}

export interface Program {
  id: string;
  name: string;
  category: string;
  description: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  difficulty: string;
  phases: ProgramPhase[];
  weeks: ProgramWeek[];
  cycleAdjustmentProfile?: ProgramCycleAdjustmentProfile;
}

// --- Benchmark ---

export interface BenchmarkDefinition {
  id: string;
  name: string;
  category: string;
  workoutDescription: string;
  scoringTypeRaw: string;
  sortOrder: number;
}

// --- Blog ---

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  author: string;
  date: string;
  tags: string[];
  image?: string;
  content: string;
  status: "draft" | "published";
  publishedAt?: string;
  updatedAt: string;
}

// --- Support ---

export interface SupportArticle {
  slug: string;
  title: string;
  content: string;
  sortOrder: number;
  status: "draft" | "published";
  updatedAt: string;
}

// --- Exercise Catalog ---

export interface CatalogExercise {
  id: string;
  name: string;
  category: string;
  subcategory?: string;
  scoring?: string;
}

// --- Admin ---

export interface AdminUser {
  email: string;
  role: string;
  addedAt: string;
}

// --- AI Prompts ---

export interface AiPrompt {
  id: string;
  name: string;
  description: string;
  promptText: string;
  modelConfig: {
    temperature: number;
    maxTokens: number;
  };
  updatedAt: string;
}

// --- Admin Settings ---

export interface AdminSettings {
  rateLimits: {
    free: number;
    plus: number;
    premium: number;
  };
  featureFlags: Record<string, boolean>;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd web-app && npm test -- src/lib/domain/__tests__/admin-types.test.ts
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
cd web-app && git add src/lib/domain/admin-types.ts src/lib/domain/__tests__/admin-types.test.ts && git commit -m "feat: add admin CMS type definitions with encode/decode helpers"
```

---

## Task 3: Admin Auth Helper

**Files:**
- Create: `web-app/src/lib/admin-auth.ts`
- Modify: `web-app/src/middleware.ts`

- [ ] **Step 1: Create admin auth helper**

```typescript
// web-app/src/lib/admin-auth.ts
import { getAuthUser, type AuthUser } from "./firestore";
import { db } from "./firebase-admin";

export async function requireAdmin(): Promise<AuthUser> {
  const user = await getAuthUser();
  if (!user) {
    throw new Error("UNAUTHORIZED");
  }
  const adminDoc = await db.collection("admins").doc(user.uid).get();
  if (!adminDoc.exists) {
    throw new Error("FORBIDDEN");
  }
  return user;
}

export async function isAdmin(uid: string): Promise<boolean> {
  const adminDoc = await db.collection("admins").doc(uid).get();
  return adminDoc.exists;
}
```

- [ ] **Step 2: Update middleware to protect admin routes**

Add `/admin/:path*` to the matcher array in `web-app/src/middleware.ts`. The existing middleware checks for the `__session` cookie and redirects to `/sign-in` if missing. Add this path to the existing matcher:

```typescript
// In the config.matcher array, add:
"/admin/:path*",
```

- [ ] **Step 3: Verify build passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd web-app && git add src/lib/admin-auth.ts src/middleware.ts && git commit -m "feat: add admin auth helper and protect /admin routes in middleware"
```

---

## Task 4: Admin Firestore Helpers

**Files:**
- Create: `web-app/src/lib/admin-firestore.ts`

- [ ] **Step 1: Create admin Firestore helpers**

```typescript
// web-app/src/lib/admin-firestore.ts
import { db } from "./firebase-admin";

export function adminCollection(name: string) {
  return db.collection(name);
}

export function adminDoc(name: string, id: string) {
  return db.collection(name).doc(id);
}

export async function allUsers(options?: {
  limit?: number;
  orderBy?: string;
  direction?: "asc" | "desc";
  startAfter?: string;
}) {
  let query = db.collection("users").orderBy(
    options?.orderBy ?? "email",
    options?.direction ?? "asc"
  );
  if (options?.startAfter) {
    const cursor = await db.collection("users").doc(options.startAfter).get();
    if (cursor.exists) {
      query = query.startAfter(cursor);
    }
  }
  if (options?.limit) {
    query = query.limit(options.limit);
  }
  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({ uid: doc.id, ...doc.data() }));
}

export async function userById(uid: string) {
  const doc = await db.collection("users").doc(uid).get();
  if (!doc.exists) return null;
  return { uid: doc.id, ...doc.data() };
}

export async function userSubcollection(uid: string, name: string) {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection(name)
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}
```

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
cd web-app && git add src/lib/admin-firestore.ts && git commit -m "feat: add admin Firestore query helpers"
```

---

## Task 5: HTML Sanitization Helper

**Files:**
- Create: `web-app/src/lib/sanitize.ts`

- [ ] **Step 1: Create sanitization wrapper**

```typescript
// web-app/src/lib/sanitize.ts
import sanitizeHtml from "sanitize-html";

const ALLOWED_TAGS = [
  "h1", "h2", "h3", "h4", "h5", "h6",
  "p", "br", "hr",
  "strong", "em", "u", "s", "code", "pre",
  "ul", "ol", "li",
  "a", "img",
  "blockquote",
  "table", "thead", "tbody", "tr", "th", "td",
  "div", "span",
];

const ALLOWED_ATTRIBUTES: Record<string, string[]> = {
  a: ["href", "title", "target", "rel"],
  img: ["src", "alt", "width", "height"],
  code: ["class"],
  pre: ["class"],
  div: ["class"],
  span: ["class"],
};

export function sanitize(html: string): string {
  return sanitizeHtml(html, {
    allowedTags: ALLOWED_TAGS,
    allowedAttributes: ALLOWED_ATTRIBUTES,
    allowedSchemes: ["http", "https", "mailto"],
  });
}
```

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add src/lib/sanitize.ts && git commit -m "feat: add HTML sanitization helper for safe content rendering"
```

---

## Task 6: Firestore Security Rules

**Files:**
- Modify: `web-app/firestore.rules`

- [ ] **Step 1: Add admin collection rules**

Add the following rules to `web-app/firestore.rules` inside the `match /databases/{database}/documents` block:

```
    // Admin allowlist — read by admins only, write via Admin SDK
    match /admins/{uid} {
      allow read: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
      allow write: if false;
    }

    // Admin-managed content collections
    match /wods/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    match /programs/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    match /exerciseCatalog/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    match /blogPosts/{slug} {
      allow read: if true;
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    match /supportArticles/{slug} {
      allow read: if true;
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    match /aiPrompts/{id} {
      allow read: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    match /adminSettings/{doc} {
      allow read: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
```

- [ ] **Step 2: Deploy rules**

```bash
firebase deploy --only firestore:rules
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add firestore.rules && git commit -m "feat: add Firestore security rules for admin collections"
```

---

## Task 7: Admin UI Components — Shell, Sidebar, Header

**Files:**
- Create: `web-app/src/components/admin/admin-sidebar.tsx`
- Create: `web-app/src/components/admin/admin-header.tsx`
- Create: `web-app/src/components/admin/admin-shell.tsx`

- [ ] **Step 1: Create admin sidebar**

```tsx
// web-app/src/components/admin/admin-sidebar.tsx
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV_GROUPS = [
  {
    label: "OVERVIEW",
    items: [{ name: "Dashboard", href: "/admin" }],
  },
  {
    label: "TRAINING",
    items: [
      { name: "WODs", href: "/admin/workouts/wods" },
      { name: "Programs", href: "/admin/workouts/programs" },
      { name: "Benchmarks", href: "/admin/workouts/benchmarks" },
      { name: "Exercise Catalog", href: "/admin/catalog" },
    ],
  },
  {
    label: "CONTENT",
    items: [
      { name: "Blog Posts", href: "/admin/content/blog" },
      { name: "Support Articles", href: "/admin/content/support" },
    ],
  },
  {
    label: "USERS",
    items: [
      { name: "User Management", href: "/admin/users" },
      { name: "Subscriptions", href: "/admin/subscriptions" },
    ],
  },
  {
    label: "AI",
    items: [
      { name: "Generated Workouts", href: "/admin/ai" },
      { name: "Prompts", href: "/admin/ai/prompts" },
      { name: "Rate Limits", href: "/admin/ai/rate-limits" },
    ],
  },
  {
    label: "SYSTEM",
    items: [{ name: "Settings", href: "/admin/settings" }],
  },
] as const;

export function AdminSidebar() {
  const pathname = usePathname();

  function isActive(href: string) {
    if (href === "/admin") return pathname === "/admin";
    return pathname.startsWith(href);
  }

  return (
    <aside className="w-60 shrink-0 bg-navy text-cream min-h-screen flex flex-col">
      <div className="px-5 py-6">
        <Link href="/admin" className="font-heading text-xl text-orange">
          Sundee Fundee
        </Link>
        <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold mt-1">
          ADMIN
        </p>
      </div>
      <nav className="flex-1 px-3 pb-6 overflow-y-auto">
        {NAV_GROUPS.map((group) => (
          <div key={group.label} className="mb-5">
            <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold px-2 mb-2">
              {group.label}
            </p>
            {group.items.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={`block px-3 py-2 rounded-button text-sm font-medium transition-colors ${
                  isActive(item.href)
                    ? "bg-orange text-white"
                    : "text-cream/70 hover:text-orange hover:bg-white/5"
                }`}
              >
                {item.name}
              </Link>
            ))}
          </div>
        ))}
      </nav>
    </aside>
  );
}
```

- [ ] **Step 2: Create admin header**

```tsx
// web-app/src/components/admin/admin-header.tsx
"use client";

import { useAuth } from "@/components/providers/auth-provider";

interface AdminHeaderProps {
  title: string;
}

export function AdminHeader({ title }: AdminHeaderProps) {
  const { user } = useAuth();

  return (
    <header className="h-14 border-b border-separator bg-card-bg flex items-center justify-between px-6">
      <h1 className="font-heading text-lg text-navy">{title}</h1>
      <div className="flex items-center gap-3">
        <span className="text-sm text-text-secondary">
          {user?.email}
        </span>
      </div>
    </header>
  );
}
```

- [ ] **Step 3: Create admin shell**

```tsx
// web-app/src/components/admin/admin-shell.tsx
import { AdminSidebar } from "./admin-sidebar";

interface AdminShellProps {
  children: React.ReactNode;
}

export function AdminShell({ children }: AdminShellProps) {
  return (
    <div className="flex min-h-screen bg-cream">
      <AdminSidebar />
      <div className="flex-1 flex flex-col min-h-screen overflow-hidden">
        {children}
      </div>
    </div>
  );
}
```

- [ ] **Step 4: Verify build passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
cd web-app && git add src/components/admin/ && git commit -m "feat: add admin shell, sidebar, and header components"
```

---

## Task 8: Admin UI Components — DataTable, DetailPanel, StatCard, EmptyState, ConfirmDialog

**Files:**
- Create: `web-app/src/components/admin/data-table.tsx`
- Create: `web-app/src/components/admin/detail-panel.tsx`
- Create: `web-app/src/components/admin/stat-card.tsx`
- Create: `web-app/src/components/admin/empty-state.tsx`
- Create: `web-app/src/components/admin/confirm-dialog.tsx`

- [ ] **Step 1: Create DataTable component**

```tsx
// web-app/src/components/admin/data-table.tsx
"use client";

import { useState, useMemo } from "react";

export interface Column<T> {
  key: string;
  header: string;
  render?: (row: T) => React.ReactNode;
  sortable?: boolean;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  rowKey: (row: T) => string;
  onRowClick?: (row: T) => void;
  selectedKey?: string | null;
  searchPlaceholder?: string;
  searchFn?: (row: T, query: string) => boolean;
  emptyMessage?: string;
}

export function DataTable<T>({
  columns,
  data,
  rowKey,
  onRowClick,
  selectedKey,
  searchPlaceholder = "Search...",
  searchFn,
  emptyMessage = "No data found.",
}: DataTableProps<T>) {
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<string | null>(null);
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");

  const filtered = useMemo(() => {
    if (!search || !searchFn) return data;
    return data.filter((row) => searchFn(row, search.toLowerCase()));
  }, [data, search, searchFn]);

  const sorted = useMemo(() => {
    if (!sortKey) return filtered;
    return [...filtered].sort((a, b) => {
      const aVal = (a as Record<string, unknown>)[sortKey];
      const bVal = (b as Record<string, unknown>)[sortKey];
      if (aVal == null || bVal == null) return 0;
      const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
      return sortDir === "asc" ? cmp : -cmp;
    });
  }, [filtered, sortKey, sortDir]);

  function handleSort(key: string) {
    if (sortKey === key) {
      setSortDir(sortDir === "asc" ? "desc" : "asc");
    } else {
      setSortKey(key);
      setSortDir("asc");
    }
  }

  return (
    <div className="flex flex-col h-full">
      {searchFn && (
        <div className="p-3 border-b border-separator">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={searchPlaceholder}
            className="w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40 focus:border-orange"
          />
        </div>
      )}
      <div className="flex-1 overflow-y-auto">
        {sorted.length === 0 ? (
          <p className="p-6 text-center text-text-secondary text-sm">{emptyMessage}</p>
        ) : (
          <table className="w-full text-sm">
            <thead className="sticky top-0 bg-navy/5 border-b border-separator">
              <tr>
                {columns.map((col) => (
                  <th
                    key={col.key}
                    className={`text-left px-4 py-2.5 font-mono text-[11px] tracking-wider uppercase text-text-secondary ${
                      col.sortable ? "cursor-pointer hover:text-navy select-none" : ""
                    }`}
                    onClick={col.sortable ? () => handleSort(col.key) : undefined}
                  >
                    {col.header}
                    {sortKey === col.key && (sortDir === "asc" ? " \u2191" : " \u2193")}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sorted.map((row) => {
                const key = rowKey(row);
                return (
                  <tr
                    key={key}
                    onClick={() => onRowClick?.(row)}
                    className={`border-b border-separator/50 transition-colors ${
                      onRowClick ? "cursor-pointer" : ""
                    } ${
                      selectedKey === key
                        ? "bg-orange/10"
                        : "hover:bg-orange/5"
                    }`}
                  >
                    {columns.map((col) => (
                      <td key={col.key} className="px-4 py-3">
                        {col.render
                          ? col.render(row)
                          : String((row as Record<string, unknown>)[col.key] ?? "")}
                      </td>
                    ))}
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Create DetailPanel component**

```tsx
// web-app/src/components/admin/detail-panel.tsx
"use client";

interface DetailPanelProps {
  title: string;
  onClose?: () => void;
  actions?: React.ReactNode;
  children: React.ReactNode;
}

export function DetailPanel({ title, onClose, actions, children }: DetailPanelProps) {
  return (
    <div className="flex flex-col h-full border-l border-separator bg-card-bg">
      <div className="flex items-center justify-between px-5 py-4 border-b border-separator">
        <h2 className="font-heading text-lg text-navy">{title}</h2>
        <div className="flex items-center gap-2">
          {actions}
          {onClose && (
            <button
              onClick={onClose}
              className="text-text-secondary hover:text-navy text-lg leading-none"
              aria-label="Close"
            >
              ×
            </button>
          )}
        </div>
      </div>
      <div className="flex-1 overflow-y-auto p-5">{children}</div>
    </div>
  );
}
```

- [ ] **Step 3: Create StatCard component**

```tsx
// web-app/src/components/admin/stat-card.tsx
interface StatCardProps {
  label: string;
  value: string | number;
  trend?: string;
  trendUp?: boolean;
}

export function AdminStatCard({ label, value, trend, trendUp }: StatCardProps) {
  return (
    <div className="bg-card-bg rounded-card p-spacing-lg border border-separator">
      <div className="h-0.5 w-8 bg-gold mb-3 rounded-full" />
      <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold mb-1">
        {label}
      </p>
      <p className="font-heading text-2xl text-navy">{value}</p>
      {trend && (
        <p
          className={`text-xs mt-1 ${
            trendUp ? "text-green-600" : "text-error"
          }`}
        >
          {trend}
        </p>
      )}
    </div>
  );
}
```

- [ ] **Step 4: Create EmptyState component**

```tsx
// web-app/src/components/admin/empty-state.tsx
import { Button } from "@/components/ui/button";

interface EmptyStateProps {
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
}

export function EmptyState({ title, description, actionLabel, onAction }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
      <p className="font-heading text-lg text-navy mb-2">{title}</p>
      <p className="text-sm text-text-secondary mb-6 max-w-sm">{description}</p>
      {actionLabel && onAction && (
        <Button variant="primary" onClick={onAction}>
          {actionLabel}
        </Button>
      )}
    </div>
  );
}
```

- [ ] **Step 5: Create ConfirmDialog component**

```tsx
// web-app/src/components/admin/confirm-dialog.tsx
"use client";

import { Button } from "@/components/ui/button";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = "Delete",
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-navy/40" onClick={onCancel} />
      <div className="relative bg-card-bg rounded-card p-6 shadow-lg max-w-sm w-full mx-4">
        <h3 className="font-heading text-lg text-navy mb-2">{title}</h3>
        <p className="text-sm text-text-secondary mb-6">{message}</p>
        <div className="flex gap-3 justify-end">
          <Button variant="secondary" onClick={onCancel}>
            Cancel
          </Button>
          <Button variant="destructive" onClick={onConfirm}>
            {confirmLabel}
          </Button>
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 6: Verify build passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
cd web-app && git add src/components/admin/ && git commit -m "feat: add admin DataTable, DetailPanel, StatCard, EmptyState, and ConfirmDialog components"
```

---

## Task 9: Rich Text Editor (Tiptap)

**Files:**
- Create: `web-app/src/components/admin/rich-text-editor.tsx`

- [ ] **Step 1: Create Tiptap WYSIWYG wrapper**

```tsx
// web-app/src/components/admin/rich-text-editor.tsx
"use client";

import { useEditor, EditorContent } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import LinkExtension from "@tiptap/extension-link";
import Image from "@tiptap/extension-image";
import Placeholder from "@tiptap/extension-placeholder";

interface RichTextEditorProps {
  content: string;
  onChange: (html: string) => void;
  placeholder?: string;
}

function MenuBar({ editor }: { editor: ReturnType<typeof useEditor> }) {
  if (!editor) return null;

  const btnClass = (active: boolean) =>
    `px-2 py-1 text-xs font-mono rounded ${
      active ? "bg-orange text-white" : "bg-card-bg text-navy hover:bg-navy/5"
    }`;

  return (
    <div className="flex flex-wrap gap-1 border-b border-separator p-2">
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
        className={btnClass(editor.isActive("heading", { level: 2 }))}
      >
        H2
      </button>
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
        className={btnClass(editor.isActive("heading", { level: 3 }))}
      >
        H3
      </button>
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleBold().run()}
        className={btnClass(editor.isActive("bold"))}
      >
        B
      </button>
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleItalic().run()}
        className={btnClass(editor.isActive("italic"))}
      >
        I
      </button>
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleBulletList().run()}
        className={btnClass(editor.isActive("bulletList"))}
      >
        List
      </button>
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleOrderedList().run()}
        className={btnClass(editor.isActive("orderedList"))}
      >
        1. List
      </button>
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleBlockquote().run()}
        className={btnClass(editor.isActive("blockquote"))}
      >
        Quote
      </button>
      <button
        type="button"
        onClick={() => editor.chain().focus().toggleCodeBlock().run()}
        className={btnClass(editor.isActive("codeBlock"))}
      >
        Code
      </button>
      <button
        type="button"
        onClick={() => {
          const url = window.prompt("Link URL:");
          if (url) editor.chain().focus().setLink({ href: url }).run();
        }}
        className={btnClass(editor.isActive("link"))}
      >
        Link
      </button>
      <button
        type="button"
        onClick={() => {
          const url = window.prompt("Image URL:");
          if (url) editor.chain().focus().setImage({ src: url }).run();
        }}
        className={btnClass(false)}
      >
        Image
      </button>
    </div>
  );
}

export function RichTextEditor({ content, onChange, placeholder }: RichTextEditorProps) {
  const editor = useEditor({
    extensions: [
      StarterKit,
      LinkExtension.configure({ openOnClick: false }),
      Image,
      Placeholder.configure({ placeholder: placeholder ?? "Start writing..." }),
    ],
    content,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  return (
    <div className="border border-separator rounded-sm bg-white">
      <MenuBar editor={editor} />
      <EditorContent
        editor={editor}
        className="prose prose-sm max-w-none p-4 min-h-[300px] focus:outline-none [&_.tiptap]:outline-none"
      />
    </div>
  );
}
```

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
cd web-app && git add src/components/admin/rich-text-editor.tsx && git commit -m "feat: add Tiptap WYSIWYG rich text editor component"
```

---

## Task 10: Admin Layout

**Files:**
- Create: `web-app/src/app/(admin)/layout.tsx`

- [ ] **Step 1: Create admin layout with auth gate**

```tsx
// web-app/src/app/(admin)/layout.tsx
import { redirect } from "next/navigation";
import { getAuthUser } from "@/lib/firestore";
import { isAdmin } from "@/lib/admin-auth";
import { AdminShell } from "@/components/admin/admin-shell";

export const metadata = {
  title: "Admin — Sundee Fundee",
};

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getAuthUser();
  if (!user) {
    redirect("/sign-in");
  }

  const admin = await isAdmin(user.uid);
  if (!admin) {
    redirect("/dashboard");
  }

  return <AdminShell>{children}</AdminShell>;
}
```

- [ ] **Step 2: Create admin dashboard placeholder page**

```tsx
// web-app/src/app/(admin)/admin/page.tsx
import { AdminHeader } from "@/components/admin/admin-header";

export default function AdminDashboard() {
  return (
    <>
      <AdminHeader title="Dashboard" />
      <main className="flex-1 overflow-y-auto p-6">
        <p className="text-text-secondary">Dashboard coming soon.</p>
      </main>
    </>
  );
}
```

- [ ] **Step 3: Verify build passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd web-app && git add "src/app/(admin)/" && git commit -m "feat: add admin layout with auth gate and dashboard placeholder"
```

---

## Task 11: Admin API Routes — WODs

**Files:**
- Create: `web-app/src/app/api/admin/wods/route.ts`
- Create: `web-app/src/app/api/admin/wods/[id]/route.ts`

- [ ] **Step 1: Create WOD list/create API route**

```typescript
// web-app/src/app/api/admin/wods/route.ts
import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";
import { exerciseToFirestore } from "@/lib/domain/admin-types";

export async function GET() {
  try {
    await requireAdmin();
    const snapshot = await adminCollection("wods").orderBy("date", "desc").get();
    const wods = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json(wods);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    await requireAdmin();
    const body = await request.json();
    const { id, ...data } = body;
    if (data.exercises) {
      data.exercises = data.exercises.map((ex: Record<string, unknown>) =>
        exerciseToFirestore(ex as any)
      );
    }
    await adminCollection("wods").doc(id).set(data);
    return NextResponse.json({ ok: true, id });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 2: Create single WOD API route**

```typescript
// web-app/src/app/api/admin/wods/[id]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminDoc } from "@/lib/admin-firestore";
import { exerciseToFirestore } from "@/lib/domain/admin-types";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await requireAdmin();
    const { id } = await params;
    const doc = await adminDoc("wods", id).get();
    if (!doc.exists) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json({ id: doc.id, ...doc.data() });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await requireAdmin();
    const { id } = await params;
    const body = await request.json();
    if (body.exercises) {
      body.exercises = body.exercises.map((ex: Record<string, unknown>) =>
        exerciseToFirestore(ex as any)
      );
    }
    await adminDoc("wods", id).set(body, { merge: true });
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    await requireAdmin();
    const { id } = await params;
    await adminDoc("wods", id).delete();
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 3: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 4: Commit**

```bash
cd web-app && git add src/app/api/admin/wods/ && git commit -m "feat: add admin WOD API routes (CRUD)"
```

---

## Task 12: Admin API Routes — Programs, Benchmarks, Catalog

**Files:**
- Create: `web-app/src/app/api/admin/programs/route.ts`
- Create: `web-app/src/app/api/admin/programs/[id]/route.ts`
- Create: `web-app/src/app/api/admin/benchmarks/route.ts`
- Create: `web-app/src/app/api/admin/benchmarks/[id]/route.ts`
- Create: `web-app/src/app/api/admin/catalog/route.ts`
- Create: `web-app/src/app/api/admin/catalog/[id]/route.ts`

These follow the exact same pattern as Task 11. Each route pair provides GET (list), POST (create), GET (single), PATCH (update), DELETE (remove) — all gated by `requireAdmin()` and operating on the corresponding Firestore collection.

- [ ] **Step 1: Create Programs API routes**

Same CRUD pattern as WOD routes, operating on `adminCollection("programs")` / `adminDoc("programs", id)`. For programs, encode exercises within each session of each week:

```typescript
// In POST/PATCH handlers, encode nested exercises:
if (body.weeks) {
  body.weeks = body.weeks.map((week: any) => ({
    ...week,
    sessions: week.sessions.map((session: any) => ({
      ...session,
      exercises: session.exercises.map((ex: any) => exerciseToFirestore(ex)),
    })),
  }));
}
```

- [ ] **Step 2: Create Benchmarks API routes**

Same CRUD pattern, operating on `adminCollection("benchmarkDefinitions")` / `adminDoc("benchmarkDefinitions", id)`. No exercise encoding needed — benchmarks are metadata only.

- [ ] **Step 3: Create Catalog API routes**

Same CRUD pattern, operating on `adminCollection("exerciseCatalog")` / `adminDoc("exerciseCatalog", id)`.

- [ ] **Step 4: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 5: Commit**

```bash
cd web-app && git add src/app/api/admin/programs/ src/app/api/admin/benchmarks/ src/app/api/admin/catalog/ && git commit -m "feat: add admin API routes for programs, benchmarks, and exercise catalog"
```

---

## Task 13: Admin API Routes — Blog, Support, Users, Subscriptions

**Files:**
- Create: `web-app/src/app/api/admin/blog/route.ts`
- Create: `web-app/src/app/api/admin/blog/[slug]/route.ts`
- Create: `web-app/src/app/api/admin/support/route.ts`
- Create: `web-app/src/app/api/admin/support/[slug]/route.ts`
- Create: `web-app/src/app/api/admin/users/route.ts`
- Create: `web-app/src/app/api/admin/users/[uid]/route.ts`
- Create: `web-app/src/app/api/admin/subscriptions/route.ts`

- [ ] **Step 1: Create Blog API routes**

Same CRUD pattern as WODs, operating on `adminCollection("blogPosts")` / `adminDoc("blogPosts", slug)`. POST should auto-set `updatedAt` to current ISO timestamp and default `status` to `"draft"`. Use `sanitize()` from `@/lib/sanitize` to sanitize `content` on write.

- [ ] **Step 2: Create Support Articles API routes**

Same pattern, operating on `adminCollection("supportArticles")` / `adminDoc("supportArticles", slug)`. Sanitize `content` on write.

- [ ] **Step 3: Create Users API routes**

```typescript
// web-app/src/app/api/admin/users/route.ts
import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { allUsers } from "@/lib/admin-firestore";

export async function GET(request: NextRequest) {
  try {
    await requireAdmin();
    const url = new URL(request.url);
    const limit = Number(url.searchParams.get("limit") ?? "50");
    const startAfter = url.searchParams.get("startAfter") ?? undefined;
    const users = await allUsers({ limit, startAfter });
    return NextResponse.json(users);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

```typescript
// web-app/src/app/api/admin/users/[uid]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { userById, userSubcollection } from "@/lib/admin-firestore";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    await requireAdmin();
    const { uid } = await params;
    const user = await userById(uid);
    if (!user) return NextResponse.json({ error: "Not found" }, { status: 404 });

    const [subscription, completedWorkouts, benchmarkResults, oneRepMaxes] =
      await Promise.all([
        userSubcollection(uid, "subscription"),
        userSubcollection(uid, "completedWorkouts"),
        userSubcollection(uid, "benchmarkResults"),
        userSubcollection(uid, "oneRepMaxes"),
      ]);

    return NextResponse.json({
      ...user,
      subscription: subscription[0] ?? null,
      completedWorkoutCount: completedWorkouts.length,
      benchmarkResultCount: benchmarkResults.length,
      oneRepMaxes,
    });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 4: Create Subscriptions API route**

```typescript
// web-app/src/app/api/admin/subscriptions/route.ts
import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";

export async function GET() {
  try {
    await requireAdmin();
    const usersSnapshot = await db.collection("users").get();
    const subscriptions: Record<string, unknown>[] = [];

    for (const userDoc of usersSnapshot.docs) {
      const subDoc = await userDoc.ref.collection("subscription").doc("current").get();
      if (subDoc.exists) {
        subscriptions.push({
          uid: userDoc.id,
          email: userDoc.data()?.email,
          name: userDoc.data()?.name,
          ...subDoc.data(),
        });
      }
    }

    return NextResponse.json(subscriptions);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 5: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 6: Commit**

```bash
cd web-app && git add src/app/api/admin/blog/ src/app/api/admin/support/ src/app/api/admin/users/ src/app/api/admin/subscriptions/ && git commit -m "feat: add admin API routes for blog, support articles, users, and subscriptions"
```

---

## Task 14: Admin API Routes — AI, Settings, Stats, Export/Import

**Files:**
- Create: `web-app/src/app/api/admin/ai/generations/route.ts`
- Create: `web-app/src/app/api/admin/ai/prompts/route.ts`
- Create: `web-app/src/app/api/admin/ai/prompts/[id]/route.ts`
- Create: `web-app/src/app/api/admin/settings/route.ts`
- Create: `web-app/src/app/api/admin/stats/route.ts`
- Create: `web-app/src/app/api/admin/export/[collection]/route.ts`
- Create: `web-app/src/app/api/admin/import/[collection]/route.ts`

- [ ] **Step 1: Create AI generations route**

```typescript
// web-app/src/app/api/admin/ai/generations/route.ts
import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";

export async function GET() {
  try {
    await requireAdmin();
    const usersSnapshot = await db.collection("users").get();
    const generations: Record<string, unknown>[] = [];

    for (const userDoc of usersSnapshot.docs) {
      const recordsSnapshot = await userDoc.ref
        .collection("generatedWorkoutRecords")
        .orderBy("createdAt", "desc")
        .limit(20)
        .get();

      for (const recordDoc of recordsSnapshot.docs) {
        generations.push({
          id: recordDoc.id,
          uid: userDoc.id,
          email: userDoc.data()?.email,
          ...recordDoc.data(),
        });
      }
    }

    generations.sort((a, b) => {
      const aDate = String(a.createdAt ?? "");
      const bDate = String(b.createdAt ?? "");
      return bDate.localeCompare(aDate);
    });

    return NextResponse.json(generations);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 2: Create AI prompts CRUD routes**

Same pattern as other CRUD routes, operating on `adminCollection("aiPrompts")` / `adminDoc("aiPrompts", id)`. Auto-set `updatedAt` on POST/PATCH.

- [ ] **Step 3: Create settings route**

```typescript
// web-app/src/app/api/admin/settings/route.ts
import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminDoc } from "@/lib/admin-firestore";

export async function GET() {
  try {
    await requireAdmin();
    const doc = await adminDoc("adminSettings", "config").get();
    if (!doc.exists) {
      return NextResponse.json({
        rateLimits: { free: 0, plus: 1, premium: 10 },
        featureFlags: {},
      });
    }
    return NextResponse.json(doc.data());
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    await requireAdmin();
    const body = await request.json();
    await adminDoc("adminSettings", "config").set(body, { merge: true });
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 4: Create stats route**

```typescript
// web-app/src/app/api/admin/stats/route.ts
import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { db } from "@/lib/firebase-admin";

export async function GET() {
  try {
    await requireAdmin();

    const usersSnapshot = await db.collection("users").get();
    const totalUsers = usersSnapshot.size;

    const activeSubs = { free: 0, plus: 0, premium: 0 };
    let aiGenerationsToday = 0;
    const today = new Date().toISOString().split("T")[0];

    for (const userDoc of usersSnapshot.docs) {
      const subDoc = await userDoc.ref.collection("subscription").doc("current").get();
      const tier = subDoc.exists ? (subDoc.data()?.tier ?? "free") : "free";
      if (tier in activeSubs) activeSubs[tier as keyof typeof activeSubs]++;

      const aiDoc = await userDoc.ref.collection("aiUsage").doc(today).get();
      if (aiDoc.exists) {
        aiGenerationsToday += aiDoc.data()?.count ?? 0;
      }
    }

    return NextResponse.json({
      totalUsers,
      subscriptions: activeSubs,
      aiGenerationsToday,
    });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 5: Create export/import routes**

```typescript
// web-app/src/app/api/admin/export/[collection]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";

const ALLOWED_COLLECTIONS = ["wods", "programs", "benchmarkDefinitions", "exerciseCatalog", "blogPosts", "supportArticles", "aiPrompts"];

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ collection: string }> }
) {
  try {
    await requireAdmin();
    const { collection } = await params;
    if (!ALLOWED_COLLECTIONS.includes(collection)) {
      return NextResponse.json({ error: "Collection not allowed" }, { status: 400 });
    }
    const snapshot = await adminCollection(collection).get();
    const data = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    return NextResponse.json(data);
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

```typescript
// web-app/src/app/api/admin/import/[collection]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/admin-auth";
import { adminCollection } from "@/lib/admin-firestore";

const ALLOWED_COLLECTIONS = ["wods", "programs", "benchmarkDefinitions", "exerciseCatalog", "blogPosts", "supportArticles", "aiPrompts"];

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ collection: string }> }
) {
  try {
    await requireAdmin();
    const { collection } = await params;
    if (!ALLOWED_COLLECTIONS.includes(collection)) {
      return NextResponse.json({ error: "Collection not allowed" }, { status: 400 });
    }
    const items: Record<string, unknown>[] = await request.json();
    const col = adminCollection(collection);
    let count = 0;
    for (const item of items) {
      const { id, ...data } = item;
      if (typeof id !== "string") continue;
      await col.doc(id).set(data);
      count++;
    }
    return NextResponse.json({ ok: true, imported: count });
  } catch (e) {
    const msg = (e as Error).message;
    if (msg === "UNAUTHORIZED") return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    if (msg === "FORBIDDEN") return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

- [ ] **Step 6: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 7: Commit**

```bash
cd web-app && git add src/app/api/admin/ai/ src/app/api/admin/settings/ src/app/api/admin/stats/ src/app/api/admin/export/ src/app/api/admin/import/ && git commit -m "feat: add admin API routes for AI oversight, settings, stats, and export/import"
```

---

## Task 15: Admin Pages — Dashboard

**Files:**
- Modify: `web-app/src/app/(admin)/admin/page.tsx`

- [ ] **Step 1: Build dashboard page with stats and quick actions**

```tsx
// web-app/src/app/(admin)/admin/page.tsx
"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { AdminStatCard } from "@/components/admin/stat-card";

interface Stats {
  totalUsers: number;
  subscriptions: { free: number; plus: number; premium: number };
  aiGenerationsToday: number;
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/admin/stats")
      .then((r) => r.json())
      .then(setStats)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <AdminHeader title="Dashboard" />
      <main className="flex-1 overflow-y-auto p-6">
        {loading ? (
          <p className="text-text-secondary">Loading...</p>
        ) : stats ? (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
              <AdminStatCard label="Total Users" value={stats.totalUsers} />
              <AdminStatCard
                label="Plus Subscribers"
                value={stats.subscriptions.plus}
              />
              <AdminStatCard
                label="Premium Subscribers"
                value={stats.subscriptions.premium}
              />
              <AdminStatCard
                label="AI Generations Today"
                value={stats.aiGenerationsToday}
              />
            </div>
            <div className="bg-card-bg rounded-card p-spacing-lg border border-separator">
              <p className="font-mono text-[10px] tracking-[0.3em] uppercase text-gold mb-3">
                QUICK ACTIONS
              </p>
              <div className="flex flex-wrap gap-3">
                <a
                  href="/admin/workouts/wods"
                  className="px-4 py-2 bg-orange text-white rounded-button text-sm font-medium hover:bg-orange/90"
                >
                  New WOD
                </a>
                <a
                  href="/admin/workouts/programs"
                  className="px-4 py-2 bg-orange text-white rounded-button text-sm font-medium hover:bg-orange/90"
                >
                  New Program
                </a>
                <a
                  href="/admin/content/blog"
                  className="px-4 py-2 bg-orange text-white rounded-button text-sm font-medium hover:bg-orange/90"
                >
                  New Blog Post
                </a>
                <a
                  href="/admin/users"
                  className="px-4 py-2 bg-card-bg text-navy border border-separator rounded-button text-sm font-medium hover:bg-navy/5"
                >
                  Search Users
                </a>
              </div>
            </div>
          </>
        ) : (
          <p className="text-error">Failed to load stats.</p>
        )}
      </main>
    </>
  );
}
```

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/page.tsx" && git commit -m "feat: add admin dashboard page with stats and quick actions"
```

---

## Task 16: Admin Pages — WOD Management

**Files:**
- Create: `web-app/src/app/(admin)/admin/workouts/wods/page.tsx`

- [ ] **Step 1: Create WOD management page**

Build a client component page that:
1. Fetches WODs from `/api/admin/wods` on mount
2. Shows a `DataTable` with columns: Date, Title, Exercises (count) — using `searchFn` for filtering by title/date
3. On row click, opens a `DetailPanel` with the WOD editor form
4. Editor has fields: date (`input type="date"`), title (text), description (textarea), exercises (dynamic list with add/remove)
5. Each exercise row has: exercise name (text), sets (text), reps (text), percent1RM (number), restMinutes (number), notes (text), bodyweightOnly (checkbox)
6. Save button calls POST to `/api/admin/wods` (new) or PATCH to `/api/admin/wods/[id]` (existing)
7. Delete button with `ConfirmDialog` calls DELETE to `/api/admin/wods/[id]`
8. "New WOD" button clears the editor for a fresh entry
9. WOD ID auto-generated as `wod-${date}`

Import: `AdminHeader`, `DataTable`, `DetailPanel`, `Button`, `Input`, `ConfirmDialog`, `EmptyState`, WOD/ProgramExercise types from `admin-types.ts`, and `decodeExerciseValue`/`encodeExerciseValue`.

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/workouts/wods/" && git commit -m "feat: add admin WOD management page with two-panel editor"
```

---

## Task 17: Admin Pages — Program Management

**Files:**
- Create: `web-app/src/app/(admin)/admin/workouts/programs/page.tsx`

- [ ] **Step 1: Create Program management page**

Two-panel layout with the most complex editor:
1. `DataTable` columns: Name, Category, Duration (weeks), Difficulty
2. Editor sections:
   - Basic info: name (auto-generates slug ID via `slugify()`), category, description, difficulty (select: Beginner/Intermediate/Advanced), sessionsPerWeek (number)
   - Phases: dynamic list with add/remove. Each row: name, goal, weekRange (two number inputs for start/end)
   - Weeks: rendered as collapsible sections. "Add Week" / "Remove Last Week" buttons. Each week shows its phaseId (optional select from phases) and isTestWeek checkbox
   - Sessions per week: "Add Session" / "Remove Session" per week. Each session: sessionName, sessionType, focus, exercises list
   - Exercises: same row pattern as WOD editor (exercise name, sets, reps, percent1RM, restMinutes, notes, bodyweightOnly)
   - Cycle adjustment profile: optional toggle. When enabled, shows per-phase multiplier inputs (loadMultiplier, setsMultiplier, repsMultiplier)
3. CRUD via `/api/admin/programs` and `/api/admin/programs/[id]`

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/workouts/programs/" && git commit -m "feat: add admin program management page with nested week/session editor"
```

---

## Task 18: Admin Pages — Benchmark Management

**Files:**
- Create: `web-app/src/app/(admin)/admin/workouts/benchmarks/page.tsx`

- [ ] **Step 1: Create Benchmark management page**

Two-panel layout:
1. `DataTable` columns: Name, Category, Scoring Type, Sort Order — with search by name
2. Editor: name, category, workoutDescription (textarea, 6 rows), scoringTypeRaw (select with options: `time` "For Time", `reps` "Max Reps", `weight` "Max Weight", `distance` "Distance", `roundsAndReps` "Rounds + Reps"), sortOrder (number input)
3. CRUD via `/api/admin/benchmarks` and `/api/admin/benchmarks/[id]`

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/workouts/benchmarks/" && git commit -m "feat: add admin benchmark management page"
```

---

## Task 19: Admin Pages — Exercise Catalog

**Files:**
- Create: `web-app/src/app/(admin)/admin/catalog/page.tsx`

- [ ] **Step 1: Create Exercise catalog page**

Two-panel layout:
1. `DataTable` columns: Name, Category, Subcategory, Scoring — with search by name
2. Editor: name, category (text input), subcategory (text input, optional), scoring (text input, optional — for conditioning exercises)
3. ID auto-generated via `slugify(name)`
4. CRUD via `/api/admin/catalog` and `/api/admin/catalog/[id]`

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/catalog/" && git commit -m "feat: add admin exercise catalog page (editable)"
```

---

## Task 20: Admin Pages — Blog Editor

**Files:**
- Create: `web-app/src/app/(admin)/admin/content/blog/page.tsx`

- [ ] **Step 1: Create Blog editor page**

Two-panel layout:
1. `DataTable` columns: Title, Author, Status (badge: green "Published" / gray "Draft"), Date, Tags (comma-joined)
2. Search by title
3. Editor fields: title, slug (auto-generated from title via `slugify()`, editable), description (textarea), author (text), date (input type="date"), tags (comma-separated text input, split on save), image URL (text)
4. Status toggle: two buttons — "Draft" and "Published" — styled as toggle group
5. Body: `RichTextEditor` component
6. CRUD via `/api/admin/blog` and `/api/admin/blog/[slug]`
7. On save: auto-set `updatedAt`. On status change to "published": also set `publishedAt`

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/content/blog/" && git commit -m "feat: add admin blog editor page with WYSIWYG"
```

---

## Task 21: Admin Pages — Support Articles

**Files:**
- Create: `web-app/src/app/(admin)/admin/content/support/page.tsx`

- [ ] **Step 1: Create Support articles page**

Two-panel layout:
1. `DataTable` columns: Title, Status (badge), Sort Order
2. Editor: title, slug (auto-generated, editable), content (`RichTextEditor`), sortOrder (number), status toggle (Draft/Published)
3. CRUD via `/api/admin/support` and `/api/admin/support/[slug]`

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/content/support/" && git commit -m "feat: add admin support articles editor page"
```

---

## Task 22: Admin Pages — User Management

**Files:**
- Create: `web-app/src/app/(admin)/admin/users/page.tsx`

- [ ] **Step 1: Create User management page**

Two-panel layout (read-only detail):
1. `DataTable` columns: Name, Email, Tier, Experience Level — with search by name/email
2. On row click, fetches user detail from `/api/admin/users/[uid]`
3. Detail panel sections (all read-only):
   - **Profile:** name, email, gender, experienceLevel, primaryGoal, weightUnit, cycleTrackingEnabled
   - **Subscription:** tier, status, stripeCustomerId (as link to Stripe dashboard)
   - **Activity:** completedWorkoutCount, benchmarkResultCount, oneRepMaxes count
   - **1RM Records:** table of oneRepMaxes (exercise, weight, date)
4. Fetches list from `/api/admin/users`

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/users/" && git commit -m "feat: add admin user management page (read-only)"
```

---

## Task 23: Admin Pages — Subscriptions

**Files:**
- Create: `web-app/src/app/(admin)/admin/subscriptions/page.tsx`

- [ ] **Step 1: Create Subscriptions overview page**

1. Summary stat cards at top: Total Paying, Plus Count, Premium Count (computed from data)
2. `DataTable` columns: User (name + email), Tier, Status (badge: green "active", red "canceled", yellow "past_due"), Start Date, Period End
3. Filter by tier (select dropdown) and status (select dropdown)
4. Row click navigates to `/admin/users` (or could open inline detail)
5. Fetches from `/api/admin/subscriptions`

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/subscriptions/" && git commit -m "feat: add admin subscriptions overview page"
```

---

## Task 24: Admin Pages — AI Oversight

**Files:**
- Create: `web-app/src/app/(admin)/admin/ai/page.tsx`
- Create: `web-app/src/app/(admin)/admin/ai/prompts/page.tsx`
- Create: `web-app/src/app/(admin)/admin/ai/rate-limits/page.tsx`

- [ ] **Step 1: Create AI generations page**

`DataTable` showing generated workouts across users:
1. Columns: User (email), Date (formatted from createdAt), Exercise Count
2. Click row to open `DetailPanel` showing the full workout JSON (formatted as readable content)
3. Fetches from `/api/admin/ai/generations`

- [ ] **Step 2: Create Prompts management page**

Two-panel layout:
1. `DataTable` columns: Name, Description, Updated At
2. Editor: name (text), description (textarea), promptText (`textarea` with `font-mono` class, 12 rows min), temperature (number input, step 0.1, min 0, max 1), maxTokens (number input)
3. CRUD via `/api/admin/ai/prompts` and `/api/admin/ai/prompts/[id]`

- [ ] **Step 3: Create Rate limits page**

Simple form page (no two-panel needed):
1. `AdminHeader` with title "Rate Limits & Settings"
2. Rate limits section: three number inputs for free/plus/premium daily AI limits
3. Feature flags section: table of existing flags with toggle switches, plus "Add Flag" form (key + initial value)
4. Save button calls PATCH to `/api/admin/settings`
5. Fetches current values from `/api/admin/settings` on mount

- [ ] **Step 4: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 5: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/ai/" && git commit -m "feat: add admin AI oversight pages (generations, prompts, rate limits)"
```

---

## Task 25: Admin Pages — Settings

**Files:**
- Create: `web-app/src/app/(admin)/admin/settings/page.tsx`

- [ ] **Step 1: Create Settings page**

Sections:
1. **Admin allowlist:** Fetch admins from a new `/api/admin/settings/admins` GET endpoint (reads `admins` collection). Display as table (email, role, addedAt). "Add Admin" form with email input — POST to create admin doc via Admin SDK. Remove button with `ConfirmDialog`.
2. **Data tools:** Per-collection export button (links to `/api/admin/export/[collection]`, downloads as JSON file). Per-collection import: file input that reads JSON and POSTs to `/api/admin/import/[collection]`.

Note: Create a small additional API route for admin management:

```typescript
// web-app/src/app/api/admin/settings/admins/route.ts
// GET: list all admin docs
// POST: { email, uid } -> create admin doc
// DELETE: { uid } -> delete admin doc
```

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add "src/app/(admin)/admin/settings/" src/app/api/admin/settings/ && git commit -m "feat: add admin settings page (allowlist, data tools)"
```

---

## Task 26: Search Command Palette

**Files:**
- Create: `web-app/src/components/admin/search-command.tsx`
- Modify: `web-app/src/components/admin/admin-shell.tsx`

- [ ] **Step 1: Create command palette component**

```tsx
// web-app/src/components/admin/search-command.tsx
"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

const COMMANDS = [
  { name: "Dashboard", href: "/admin" },
  { name: "WODs", href: "/admin/workouts/wods" },
  { name: "Programs", href: "/admin/workouts/programs" },
  { name: "Benchmarks", href: "/admin/workouts/benchmarks" },
  { name: "Exercise Catalog", href: "/admin/catalog" },
  { name: "Blog Posts", href: "/admin/content/blog" },
  { name: "Support Articles", href: "/admin/content/support" },
  { name: "Users", href: "/admin/users" },
  { name: "Subscriptions", href: "/admin/subscriptions" },
  { name: "AI Generations", href: "/admin/ai" },
  { name: "AI Prompts", href: "/admin/ai/prompts" },
  { name: "Rate Limits", href: "/admin/ai/rate-limits" },
  { name: "Settings", href: "/admin/settings" },
];

export function SearchCommand() {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const router = useRouter();

  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setOpen((prev) => !prev);
      }
      if (e.key === "Escape") setOpen(false);
    }
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  if (!open) return null;

  const filtered = COMMANDS.filter((cmd) =>
    cmd.name.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[20vh]">
      <div className="absolute inset-0 bg-navy/40" onClick={() => setOpen(false)} />
      <div className="relative bg-card-bg rounded-card shadow-lg w-full max-w-md mx-4">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search pages..."
          className="w-full px-4 py-3 text-sm bg-transparent border-b border-separator focus:outline-none"
          autoFocus
        />
        <div className="max-h-64 overflow-y-auto py-2">
          {filtered.map((cmd) => (
            <button
              key={cmd.href}
              onClick={() => {
                router.push(cmd.href);
                setOpen(false);
                setQuery("");
              }}
              className="w-full text-left px-4 py-2.5 text-sm hover:bg-orange/5 transition-colors"
            >
              {cmd.name}
            </button>
          ))}
          {filtered.length === 0 && (
            <p className="px-4 py-2 text-sm text-text-secondary">No results</p>
          )}
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Add SearchCommand to AdminShell**

Update `admin-shell.tsx` to include `<SearchCommand />`:

```tsx
import { SearchCommand } from "./search-command";

export function AdminShell({ children }: AdminShellProps) {
  return (
    <div className="flex min-h-screen bg-cream">
      <AdminSidebar />
      <div className="flex-1 flex flex-col min-h-screen overflow-hidden">
        {children}
      </div>
      <SearchCommand />
    </div>
  );
}
```

- [ ] **Step 3: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 4: Commit**

```bash
cd web-app && git add src/components/admin/search-command.tsx src/components/admin/admin-shell.tsx && git commit -m "feat: add Cmd+K command palette for admin navigation"
```

---

## Task 27: Migrate Public Blog to Firestore

**Files:**
- Modify: `web-app/src/lib/blog.ts`
- Modify: `web-app/src/app/(marketing)/blog/page.tsx`
- Modify: `web-app/src/app/(marketing)/blog/[slug]/page.tsx`

- [ ] **Step 1: Update blog.ts to read from Firestore**

Replace the MDX file reading logic with Firestore queries:

```typescript
// web-app/src/lib/blog.ts
import { db } from "./firebase-admin";
import { sanitize } from "./sanitize";

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  date: string;
  author: string;
  tags: string[];
  image?: string;
  content: string;
}

export async function getAllPosts(): Promise<BlogPost[]> {
  const snapshot = await db
    .collection("blogPosts")
    .where("status", "==", "published")
    .orderBy("date", "desc")
    .get();
  return snapshot.docs.map((doc) => ({
    slug: doc.id,
    title: doc.data().title,
    description: doc.data().description,
    date: doc.data().date,
    author: doc.data().author,
    tags: doc.data().tags ?? [],
    image: doc.data().image,
    content: sanitize(doc.data().content),
  }));
}

export async function getPostBySlug(slug: string): Promise<BlogPost | null> {
  const doc = await db.collection("blogPosts").doc(slug).get();
  if (!doc.exists) return null;
  const data = doc.data()!;
  if (data.status !== "published") return null;
  return {
    slug: doc.id,
    title: data.title,
    description: data.description,
    date: data.date,
    author: data.author,
    tags: data.tags ?? [],
    image: data.image,
    content: sanitize(data.content),
  };
}
```

- [ ] **Step 2: Update blog list page**

Change `getAllPosts()` call to `await getAllPosts()` (it's now async). The list page likely only shows titles/descriptions, so minimal changes beyond making the function call async.

- [ ] **Step 3: Update blog detail page**

Replace `MDXRemote` rendering with sanitized HTML output. Since `blog.ts` now returns sanitized HTML via `sanitize()`, the content is safe to render:

```tsx
<article
  className="prose"
  dangerouslySetInnerHTML={{ __html: post.content }}
/>
```

The `sanitize()` function (from `@/lib/sanitize`) strips all script tags, event handlers, and disallowed elements before the HTML reaches the page. This is applied in `blog.ts` at read time, ensuring the content stored in Firestore is sanitized before rendering.

- [ ] **Step 4: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 5: Commit**

```bash
cd web-app && git add src/lib/blog.ts src/lib/sanitize.ts "src/app/(marketing)/blog/" && git commit -m "feat: migrate public blog from MDX files to Firestore with HTML sanitization"
```

---

## Task 28: Migration Script

**Files:**
- Create: `scripts/migrate-to-firestore.ts`

- [ ] **Step 1: Create migration script**

```typescript
// scripts/migrate-to-firestore.ts
import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { readFileSync, readdirSync } from "fs";
import { join } from "path";
import matter from "gray-matter";

// Initialize Firebase Admin
const app = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
  }),
});
const db = getFirestore(app);

async function migrateWODs() {
  const filePath = join(__dirname, "../wod-dashboard/data/wods.json");
  try {
    const data = JSON.parse(readFileSync(filePath, "utf-8"));
    console.log(`Migrating ${data.length} WODs...`);
    for (const wod of data) {
      const { id, ...rest } = wod;
      await db.collection("wods").doc(id).set(rest);
    }
    console.log("WODs migrated.");
  } catch {
    console.log("No WODs to migrate or file not found.");
  }
}

async function migratePrograms() {
  const filePath = join(__dirname, "../wod-dashboard/data/programs.json");
  try {
    const data = JSON.parse(readFileSync(filePath, "utf-8"));
    console.log(`Migrating ${data.length} Programs...`);
    for (const program of data) {
      const { id, ...rest } = program;
      await db.collection("programs").doc(id).set(rest);
    }
    console.log("Programs migrated.");
  } catch {
    console.log("No Programs to migrate or file not found.");
  }
}

async function migrateBenchmarks() {
  const filePath = join(__dirname, "../wod-dashboard/data/benchmarks.json");
  try {
    const data = JSON.parse(readFileSync(filePath, "utf-8"));
    console.log(`Migrating ${data.length} Benchmarks...`);
    for (const benchmark of data) {
      const { id, ...rest } = benchmark;
      await db.collection("benchmarkDefinitions").doc(id).set(rest);
    }
    console.log("Benchmarks migrated.");
  } catch {
    console.log("No Benchmarks to migrate or file not found.");
  }
}

async function migrateBlogPosts() {
  const blogDir = join(__dirname, "../content/blog");
  try {
    const files = readdirSync(blogDir).filter((f) => f.endsWith(".mdx"));
    console.log(`Migrating ${files.length} blog posts...`);
    for (const file of files) {
      const raw = readFileSync(join(blogDir, file), "utf-8");
      const { data: frontmatter, content } = matter(raw);
      const slug = file.replace(/\.mdx$/, "");
      await db.collection("blogPosts").doc(slug).set({
        title: frontmatter.title ?? "",
        description: frontmatter.description ?? "",
        author: frontmatter.author ?? "",
        date: frontmatter.date ?? "",
        tags: frontmatter.tags ?? [],
        image: frontmatter.image ?? null,
        content: content,
        status: "published",
        publishedAt: frontmatter.date ?? "",
        updatedAt: new Date().toISOString(),
      });
    }
    console.log("Blog posts migrated.");
  } catch {
    console.log("No blog posts to migrate or directory not found.");
  }
}

async function main() {
  console.log("Starting Firestore migration...\n");
  await migrateWODs();
  await migratePrograms();
  await migrateBenchmarks();
  await migrateBlogPosts();
  console.log("\nMigration complete.");
  process.exit(0);
}

main().catch((e) => {
  console.error("Migration failed:", e);
  process.exit(1);
});
```

- [ ] **Step 2: Test migration script runs**

```bash
npx tsx scripts/migrate-to-firestore.ts
```

Expected: Script runs, migrates data (or reports files not found if data directory is empty).

- [ ] **Step 3: Commit**

```bash
git add scripts/migrate-to-firestore.ts && git commit -m "feat: add one-time Firestore migration script for WODs, programs, benchmarks, and blog posts"
```

---

## Task 29: Remove Legacy Code

**Files:**
- Delete: `wod-dashboard/` (entire directory)
- Delete: `content/blog/*.mdx` (after migration verified)
- Modify: `web-app/package.json` (remove `next-mdx-remote`, `gray-matter`)

- [ ] **Step 1: Verify migration is complete**

Check Firestore via the admin export endpoints or Firebase Console to confirm all data is present.

- [ ] **Step 2: Remove legacy dependencies**

```bash
cd web-app && npm uninstall next-mdx-remote gray-matter
```

- [ ] **Step 3: Delete wod-dashboard directory**

```bash
rm -rf wod-dashboard/
```

- [ ] **Step 4: Delete MDX blog files**

```bash
rm -rf content/blog/
```

- [ ] **Step 5: Verify build passes**

```bash
cd web-app && npm run build
```

Expected: Build succeeds with no broken imports.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "chore: remove wod-dashboard, MDX blog files, and legacy dependencies after Firestore migration"
```

---

## Task 30: Update Sitemap Config

**Files:**
- Modify: `web-app/next-sitemap.config.js`

- [ ] **Step 1: Exclude admin routes from sitemap**

Add `/admin` and `/admin/*` to the exclude list in `next-sitemap.config.js`.

- [ ] **Step 2: Verify build passes**

```bash
cd web-app && npm run build
```

- [ ] **Step 3: Commit**

```bash
cd web-app && git add next-sitemap.config.js && git commit -m "chore: exclude admin routes from sitemap"
```

---

## Task 31: Final Verification

- [ ] **Step 1: Run all tests**

```bash
cd web-app && npm test
```

Expected: All tests pass including new admin-types tests.

- [ ] **Step 2: Run linter**

```bash
cd web-app && npm run lint
```

Expected: No lint errors.

- [ ] **Step 3: Run production build**

```bash
cd web-app && npm run build
```

Expected: Build succeeds.

- [ ] **Step 4: Manual smoke test**

Start dev server and verify:
```bash
cd web-app && npm run dev
```

1. Navigate to `/admin` — should redirect to sign-in if not authenticated
2. After signing in as an admin user, `/admin` should show the dashboard with stats
3. Navigate through each sidebar section — all pages load without errors
4. Create/edit/delete a WOD through the admin
5. Create a blog post with the WYSIWYG editor, publish it, verify it appears on `/blog`
6. View users list, click into a user detail
7. Check `/blog` still works (reads from Firestore now)
8. Press Cmd+K — command palette opens and navigates correctly

- [ ] **Step 5: Commit any fixes**

```bash
cd web-app && git add -A && git commit -m "fix: resolve issues found during final verification"
```
