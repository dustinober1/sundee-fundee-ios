# Sundee Fundee Admin CMS — Design Spec

## Overview

Replace the standalone `wod-dashboard/` with a full content management system integrated into the main `web-app/` as an `/admin` route group. The CMS provides production data management for all platform entities: users, subscriptions, training content, blog posts, AI oversight, and analytics.

## Key Decisions

- **Project structure:** Admin lives inside `web-app/src/app/(admin)/admin/` — shared dependencies, single Vercel deploy
- **Auth:** Firebase Auth with admin allowlist (`admins/{uid}` Firestore collection)
- **Data access:** Direct Firebase Admin SDK + Stripe API against production
- **Navigation:** Fixed sidebar (desktop-oriented admin layout)
- **Content editing:** Tiptap WYSIWYG editor for blog and support articles
- **Analytics:** Firestore-based operational metrics now; behavioral analytics (PostHog/Mixpanel) later
- **Migration:** WODs, Programs, Benchmarks move from local JSON files to Firestore. CloudKit sync removed entirely.

---

## 1. Route Structure

```
src/app/(admin)/
├── layout.tsx                      # Admin shell: sidebar + auth gate
├── admin/
│   ├── page.tsx                    # Dashboard (analytics overview)
│   ├── users/
│   │   └── page.tsx                # User management
│   ├── subscriptions/
│   │   └── page.tsx                # Subscription/billing overview
│   ├── workouts/
│   │   ├── wods/page.tsx           # WOD management
│   │   ├── programs/page.tsx       # Program management
│   │   └── benchmarks/page.tsx     # Benchmark management
│   ├── content/
│   │   ├── blog/page.tsx           # Blog post editor
│   │   └── support/page.tsx        # Support articles
│   ├── ai/
│   │   ├── page.tsx                # Generated workout history
│   │   ├── prompts/page.tsx        # Prompt management
│   │   └── rate-limits/page.tsx    # Rate limit config
│   ├── catalog/
│   │   └── page.tsx                # Exercise catalog (editable)
│   └── settings/
│       └── page.tsx                # Admin settings, allowlist
```

## 2. Auth & Middleware

### Admin Allowlist

New top-level Firestore collection:

```typescript
// admins/{uid}
interface AdminUser {
  email: string;
  role: string;       // "admin"
  addedAt: string;    // ISO timestamp
}
```

### Middleware

Extend `src/middleware.ts` to add `/admin/:path*` to protected routes (checks `__session` cookie presence).

### Server-Side Auth Gate

The `(admin)/layout.tsx` server component:
1. Calls `getAuthUser()` to verify session
2. Checks `admins/{uid}` document exists
3. Redirects unauthorized users to `/dashboard`

### API Auth Helper

```typescript
// src/lib/admin-auth.ts
async function requireAdmin(request: Request): Promise<AuthUser> {
  const user = await getAuthUser();
  if (!user) throw new Response("Unauthorized", { status: 401 });
  const adminDoc = await db.collection("admins").doc(user.uid).get();
  if (!adminDoc.exists) throw new Response("Forbidden", { status: 403 });
  return user;
}
```

Every `/api/admin/*` route calls `requireAdmin()` before processing.

## 3. Design System

### Approach

Reuse existing `src/components/ui/` (Button, Card, Input, FormAlert, Art Deco elements). Add admin-specific components under `src/components/admin/`.

### Design Tokens (Existing — No Changes)

| Token | Value | Usage |
|---|---|---|
| Cream | `#f4f0df` | Content background |
| Navy | `#0d1a40` | Sidebar, text, borders |
| Orange | `#f27319` | Active states, CTAs |
| Gold | `#d9b34d` | Section labels, decorative |
| Card BG | `#fcfaf2` | Cards, table rows |
| Separator | `#e0d9c7` | Borders, dividers |
| Text Secondary | `#596180` | Muted text |
| Error | `#d92626` | Destructive actions |

### Typography (Existing — No Changes)

- **Playfair Display** — page titles, section headings
- **Inter** — body text, table content, form labels
- **JetBrains Mono** — section labels, IDs, status badges

### New Admin Components

Located in `src/components/admin/`:

| Component | Purpose |
|---|---|
| `admin-sidebar.tsx` | Navy sidebar with grouped nav sections, orange active state |
| `admin-header.tsx` | Top bar with breadcrumbs, page title, user info |
| `admin-shell.tsx` | Combines sidebar + header + content area |
| `data-table.tsx` | Reusable table: sorting, filtering, pagination, row selection, bulk actions |
| `stat-card.tsx` | Dashboard metric card: value, label, trend, sparkline |
| `detail-panel.tsx` | Right-side panel for editing records |
| `rich-text-editor.tsx` | Tiptap WYSIWYG wrapper with HTML output |
| `search-command.tsx` | Cmd+K command palette for quick nav |
| `empty-state.tsx` | Empty state with icon, message, action |
| `confirm-dialog.tsx` | Modal confirmation for destructive actions |

### Sidebar Navigation Groups

```
OVERVIEW
  Dashboard

TRAINING
  WODs
  Programs
  Benchmarks
  Exercise Catalog

CONTENT
  Blog Posts
  Support Articles

USERS
  User Management
  Subscriptions

AI
  Generated Workouts
  Prompts
  Rate Limits

SYSTEM
  Settings
```

Section labels use the existing `SectionLabel` pattern: gold, monospace, uppercase, letter-spaced.

### Layout

- Sidebar: 240px fixed left, navy background, cream text
- Header bar: top strip with page title, admin user email, sign-out
- Content area: `flex-1` scrollable, cream background
- No bottom nav — completely separate from the `(features)` layout

## 4. Data Layer

### New Firestore Collections (Top-Level, Admin-Managed)

| Collection | Document ID | Purpose |
|---|---|---|
| `admins/{uid}` | Firebase UID | Admin allowlist with role |
| `wods/{id}` | Slug ID | Workout of the Day definitions |
| `programs/{id}` | Slug ID | Multi-week program definitions |
| `benchmarkDefinitions/{id}` | Exists already | Benchmark catalog |
| `exerciseCatalog/{id}` | Slug ID | Editable exercise reference |
| `blogPosts/{slug}` | URL slug | Blog content (replaces MDX files) |
| `supportArticles/{slug}` | URL slug | Support page content |
| `aiPrompts/{id}` | Auto-generated | AI generation prompt templates |
| `adminSettings/config` | Single doc | Rate limit defaults, feature flags |

### Existing User Collections (Read-Only from Admin)

| Collection | Admin Access |
|---|---|
| `users/{uid}` | Read profiles, stats |
| `users/{uid}/subscription/current` | Read subscription status |
| `users/{uid}/completedWorkouts/{id}` | Read workout history |
| `users/{uid}/generatedWorkoutRecords/{id}` | Read AI-generated workouts |
| `users/{uid}/aiUsage/{date}` | Read rate limit usage |
| `users/{uid}/benchmarkResults/{id}` | Read benchmark scores |

### Admin Firestore Helpers

```typescript
// src/lib/admin-firestore.ts
adminCollection(name: string)                          // Top-level admin collection
adminDoc(name: string, id: string)                     // Single admin document
allUsers(options?: { limit, orderBy, cursor })          // Paginated user list
userById(uid: string)                                  // Single user with profile
userSubcollection(uid: string, name: string)           // User subcollection query
```

All admin writes verify the caller is in the `admins` collection.

### Blog Content Model

```typescript
interface BlogPost {
  slug: string;
  title: string;
  description: string;
  author: string;
  date: string;
  tags: string[];
  image?: string;
  content: string;        // HTML from WYSIWYG editor
  status: "draft" | "published";
  publishedAt?: string;
  updatedAt: string;
}
```

### Support Article Model

```typescript
interface SupportArticle {
  slug: string;
  title: string;
  content: string;        // HTML from WYSIWYG editor
  sortOrder: number;
  status: "draft" | "published";
  updatedAt: string;
}
```

### Firestore Security Rules

```
match /admins/{uid} {
  allow read: if request.auth != null
    && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
  allow write: if false;  // Admin SDK only
}

match /wods/{id} {
  allow read: if request.auth != null;
  allow write: if exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}

// Same read/write pattern for: programs, exerciseCatalog, blogPosts,
// supportArticles, aiPrompts, adminSettings
```

User-scoped collections keep existing rules unchanged.

## 5. Feature Sections

### 5A: Dashboard (Home)

**Metrics row (4 stat cards):**
- Total users (7-day trend)
- Active subscriptions by tier (Free / Plus / Premium)
- AI workouts generated today (vs. daily average)
- Workouts completed this week

**Recent activity feed:**
- New user signups (last 7 days)
- Recent AI generations
- Recent subscription changes

**Quick actions:** Create new WOD / Program / Blog Post, jump to user search.

All data queried server-side from Firestore.

### 5B: User Management

**List view (DataTable):**
- Columns: Name, Email, Sign-up Date, Tier, Experience Level, Workouts Completed, Last Active
- Filters: subscription tier, experience level, date range
- Search: by name or email

**Detail panel (read-only):**
- Profile: name, email, gender, experience level, primary goal, weight unit, cycle tracking
- Subscription: tier, billing period, Stripe customer link
- Activity: total workouts, total AI generations, last workout date
- 1RM records, benchmark results, enrolled programs

No user editing from admin. Subscription management via Stripe dashboard link.

### 5C: Subscription Overview

**Summary cards:** Total paying subscribers, MRR, churn (last 30 days), tier breakdown.

**Subscription table:**
- Columns: User, Tier, Status (active/canceled/past_due), Start Date, Period End
- Filters: tier, status
- Click through to user detail or Stripe dashboard

Data source: `users/{uid}/subscription/current` collection. Stripe dashboard links for management actions.

### 5D: WODs, Programs, Benchmarks

Two-panel layout: DataTable on left, DetailPanel editor on right.

**Changes from current wod-dashboard:**
- Data reads/writes go to Firestore (not JSON files)
- No CloudKit publish workflow
- AI generation stays (existing endpoints)
- Program editor retains nested week/session/exercise structure
- Benchmark editor retains scoring type and sort order
- Bulk import/export: JSON upload to seed, JSON download for backup

### 5E: Exercise Catalog (Now Editable)

Promoted from read-only reference to full CRUD:
- Add/edit/delete exercises
- Manage categories (Weightlifting subcategories, Conditioning subcategories)
- Data stored in `exerciseCatalog` Firestore collection
- Autocomplete in WOD/Program editors reads from this collection

### 5F: Content Management

**Blog posts:**
- List: Title, Author, Status (draft/published), Date, Tags
- Editor: title, slug (auto-generated, editable), description, author, date, tags, image URL
- Tiptap WYSIWYG body editor: headings, bold, italic, lists, links, code blocks, images, blockquotes
- Status toggle: Draft / Published
- Live preview panel

**Support articles:** Same editor, simpler metadata (title, slug, content, `sortOrder: number` for display ordering).

### 5G: AI Oversight

**Generated workouts:**
- Aggregated view across all users
- Columns: User, Date, Workout Type, Exercise Count, Generation Time
- Filters: date range, user
- Click to view full workout detail

**Prompt management:**
- List of prompt templates in `aiPrompts` collection
- Editor: name, description, prompt text (monospace code editor), model config (temperature, max tokens)
- Version history as subcollection

**Rate limits:**
- Current config: limits per tier (Free: 0, Plus: 1, Premium: 10)
- Editable via `adminSettings/config`
- Daily usage overview: users hitting limits

### 5H: Settings

- Admin allowlist: add/remove admin emails, current admins with roles
- Feature flags: key-value toggles in `adminSettings/config`
- Data tools: export collections as JSON, import from JSON

## 6. API Routes

All under `src/app/api/admin/`:

| Route | Methods | Purpose |
|---|---|---|
| `/api/admin/stats` | GET | Dashboard aggregate stats |
| `/api/admin/users` | GET | Paginated user list with filters |
| `/api/admin/users/[uid]` | GET | Single user detail with subcollections |
| `/api/admin/wods` | GET, POST | List/create WODs |
| `/api/admin/wods/[id]` | GET, PATCH, DELETE | Single WOD CRUD |
| `/api/admin/programs` | GET, POST | List/create programs |
| `/api/admin/programs/[id]` | GET, PATCH, DELETE | Single program CRUD |
| `/api/admin/benchmarks` | GET, POST | List/create benchmarks |
| `/api/admin/benchmarks/[id]` | GET, PATCH, DELETE | Single benchmark CRUD |
| `/api/admin/catalog` | GET, POST | List/create exercises |
| `/api/admin/catalog/[id]` | PATCH, DELETE | Edit/delete exercise |
| `/api/admin/blog` | GET, POST | List/create blog posts |
| `/api/admin/blog/[slug]` | GET, PATCH, DELETE | Single post CRUD |
| `/api/admin/support` | GET, POST | List/create support articles |
| `/api/admin/support/[slug]` | GET, PATCH, DELETE | Single article CRUD |
| `/api/admin/ai/generations` | GET | List AI generations across users |
| `/api/admin/ai/prompts` | GET, POST | List/create prompt templates |
| `/api/admin/ai/prompts/[id]` | PATCH, DELETE | Edit/delete prompts |
| `/api/admin/settings` | GET, PATCH | Read/update admin config |
| `/api/admin/export/[collection]` | GET | JSON export |
| `/api/admin/import/[collection]` | POST | JSON import |

## 7. Dependencies

### Add

```
@tiptap/react
@tiptap/starter-kit
@tiptap/extension-link
@tiptap/extension-image
@tiptap/extension-code-block-lowlight
@tiptap/extension-placeholder
```

### Remove (After Migration)

```
next-mdx-remote
gray-matter
```

## 8. Migration

### One-Time Script: `scripts/migrate-to-firestore.ts`

Run with `npx tsx scripts/migrate-to-firestore.ts`:

1. Read `wod-dashboard/data/wods.json` -> write to `wods` collection
2. Read `wod-dashboard/data/programs.json` -> write to `programs` collection
3. Read `wod-dashboard/data/benchmarks.json` -> merge into `benchmarkDefinitions` collection
4. Read `content/blog/*.mdx` -> parse frontmatter, render MDX to HTML -> write to `blogPosts` collection
5. Read `exercise-catalog.ts` -> write to `exerciseCatalog` collection

Idempotent: uses document IDs as keys, overwrites on re-run.

### Deletions (Post-Migration)

- `wod-dashboard/` — entire directory
- `content/blog/*.mdx` — blog content now in Firestore
- MDX parsing logic in `src/lib/blog.ts` — replaced with Firestore queries
- CloudKit code: `cloudkit.ts`, `cloudkit-server.pem`, CloudKit API routes, `publish-status.json`
- `next-mdx-remote` and `gray-matter` dependencies

### Public Blog Route Update

`/blog` and `/blog/[slug]` switch from MDX file reads to Firestore queries filtered by `status: "published"`. Rendering switches from `next-mdx-remote` to sanitized HTML output.

## 9. Future Phase: Behavioral Analytics

Not in this build. When ready:
- Integrate PostHog or Mixpanel into the main app
- Add event tracking for key user actions
- Query analytics API from admin dashboard
- Add behavioral dashboards (funnels, retention, feature adoption)
