# Sundee Fundee

Cycle-aware strength training — built for the web.

## Stack

| Component | Technology |
|:---|:---|
| **App** | Next.js 16, TypeScript, React 19, Tailwind CSS 4 (PWA) |
| **Hosting** | Cloudflare Pages (via OpenNext adapter) |
| **Database** | Cloudflare D1 (SQLite) with Drizzle ORM |
| **Cache / Sessions** | Cloudflare KV |
| **Auth** | Auth.js (NextAuth v5) + Google & Apple providers |
| **Payments** | Stripe (checkout, portal, webhooks) |
| **AI Workouts** | Next.js API route with Gemini on Vertex AI |
| **Admin** | WOD Dashboard (Next.js) |
| **Blog** | MDX with `next-mdx-remote` |
| **PWA** | Serwist (service worker, offline support) |

## Project Structure

```
sundee-fundee/
├── web-app/                 # Main application (Next.js PWA)
│   ├── src/
│   │   ├── app/
│   │   │   ├── (auth)/      # Sign in / sign up
│   │   │   ├── (features)/  # Dashboard, workouts, programs, maxes, benchmarks, cycle, settings
│   │   │   ├── (marketing)/ # Blog, privacy, terms, support
│   │   │   └── api/         # Auth, AI generation, Stripe webhooks
│   │   ├── components/      # Shared UI components
│   │   ├── db/              # Drizzle schema (19 tables) + migrations
│   │   └── lib/             # Auth config, AI config, entitlement logic, theme, domain logic
│   ├── content/blog/        # MDX blog posts
│   ├── drizzle/             # Database migrations
│   └── public/              # Manifest, icons, generated sitemap
├── wod-dashboard/           # Admin dashboard for WODs, programs, benchmarks
│   └── data/                # Shared JSON data (programs, wods, benchmarks)
├── workers/
│   └── ai-coach/            # Cloudflare Worker — AI workout generation
├── functions/               # Firebase Cloud Functions (legacy)
└── .github/workflows/       # CI: lint, test, build, smoke test
```

## Development

### Prerequisites

- Node.js 22+
- npm

### Setup

```bash
cd web-app
cp .env.example .env.local
# Fill in AUTH_SECRET, AUTH_GOOGLE_ID, AUTH_GOOGLE_SECRET, Stripe keys, etc.
npm install
```

### Run

```bash
npm run dev          # Next.js dev server (http://localhost:3000)
npm run preview      # Cloudflare local preview (wrangler dev)
```

### Test

```bash
npm test             # Run all tests (Vitest)
npm run test:watch   # Watch mode
npm run test:coverage
```

### Lint

```bash
npm run lint         # ESLint
```

### Database

```bash
npx drizzle-kit generate   # Generate migration from schema changes
npx drizzle-kit migrate    # Apply migrations
```

## Environment Variables

```bash
# Auth.js
AUTH_SECRET=              # openssl rand -base64 32
AUTH_GOOGLE_ID=           # Google OAuth client ID
AUTH_GOOGLE_SECRET=       # Google OAuth client secret
AUTH_APPLE_ID=            # Apple Sign-In bundle ID
AUTH_APPLE_SECRET=        # Apple Sign-In key secret

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Firebase Admin / Vertex AI
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
```

Cloudflare bindings (`D1`, `KV`) are configured in `wrangler.jsonc`.

## Deployment

Cloudflare Pages auto-deploys on push to `main`. Manual deploy:

```bash
cd web-app
npm run build:cf     # Build with OpenNext adapter
npm run deploy       # Deploy to Cloudflare Pages
```

## Cycle-Based Training

Training recommendations adapt to menstrual cycle phase:

| Phase | Recommendation |
|-------|---------------|
| **Menstrual** | Low intensity, recovery focus |
| **Follicular** | Moderate, building strength |
| **Ovulation** | Peak intensity, PR attempts |
| **Luteal** | Maintenance, technique work |

## CI/CD

`.github/workflows/ci.yml` runs on every push and PR:

1. **Lint** — ESLint
2. **Test** — Vitest
3. **Build** — Next.js production build
4. **Smoke Test** — Curls `sundeefundee.com` after deploy (main branch only)

## Contributing

1. Run `npm test` and ensure all tests pass before committing.
2. Use Conventional Commits: `feat:`, `fix:`, `docs:`.
3. Never commit secrets, API keys, or `.env.local`.
