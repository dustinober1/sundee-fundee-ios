# Technology Stack

**Project:** Workout Tracking
**Researched:** 2026-02-17

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Next.js** | 16 (App Router) | Meta-framework | Fast refresh, robust routing, server actions for Supabase integration. |
| **React** | 19 | UI Library | Ecosystem dominance, hooks for state. |
| **TypeScript** | 5.x | Language | Safety for complex data models (Workouts/Sets). |

### Database

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Dexie.js** | 5.x | Local DB | IndexedDB wrapper. Strong typing, "LiveQuery" hooks. |
| **Supabase** | v2 | Remote DB | PostgresaaS. easy auth, row-level security, simple JS client. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Recharts** | Latest | Visualization | Rendering 1RM and Volume progress charts. |
| **Framer Motion**| Latest | Animations | Page transitions, success confetti, interactive elements. |
| **Zod** | Latest | Validation | Validating JSON imports/exports and form inputs. |
| **date-fns** | Latest | Dates | Manipulating workout dates (lighter than Moment). |
| **Playwright** | Latest | E2E Testing | Testing critical flows (logging, sync) in mobile viewports. |

## Installation

```bash
# Core
npm install next react react-dom dexie dexie-react @supabase/supabase-js

# UI
npm install framer-motion recharts lucide-react clsx tailwind-merge

# Utilities
npm install zod date-fns uuid

# Dev
npm install -D @types/react @types/node typescript postcss tailwindcss
npm install -D @playwright/test
```

## Sources

- [Context7](https://context7.com)
- [Next.js Docs](https://nextjs.org)
- [Dexie.js](https://dexie.org)
