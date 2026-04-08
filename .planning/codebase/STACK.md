---
name: Technology Stack
type: codebase-map
focus: tech
created: 2026-04-08
---

# Technology Stack

**Analysis Date:** 2026-04-08

## Languages

**Primary:**
- TypeScript 5.x - Web app (`web-app/`), Cloud Functions (`firebase/functions/`), domain logic, API routes, React components
- Swift 6.0 (strict concurrency) - iOS app (`SundeeFundee/` Swift Package, `SundeeFundeeApp/` Xcode project)

**Secondary:**
- JavaScript (ESM) - PostCSS config, ESLint config, next-sitemap config
- Python 3 - Marketing screenshot generation scripts (`scripts/generate_appstore_marketing.py`, `scripts/generate_ipad_marketing.py`)
- MDX - Blog content (`content/blog/`)
- CSS (Tailwind) - Styling via `@tailwindcss/postcss` v4

## Runtime

**Environment:**
- Node.js 25.x (development machine: v25.9.0)
- Cloud Functions require Node 20 (`firebase/functions/package.json` engines field)
- iOS: deployment target iOS 18.0, requires arm64
- Swift 6.3 toolchain (swiftlang-6.3.0.123.5)

**Package Manager:**
- npm 11.x (web app and Cloud Functions; lockfiles present at `web-app/package-lock.json` and `firebase/functions/package-lock.json`)
- Swift Package Manager (iOS; `SundeeFundee/Package.swift`)

## Frameworks

**Core:**
- Next.js 16.2.1 - Web app framework (App Router, React Server Components, Turbopack in dev)
- React 19.2.4 - UI library
- SwiftUI - iOS native UI (`SundeeFundeeKit/UI/` views)
- Firebase Functions 6.3.0 - Cloud Functions runtime (2nd gen, `onCall`)

**Testing:**
- Vitest 4.1.2 - Unit testing framework (web app domain layer)
- Vitest coverage-v8 4.1.2 - Coverage provider
- XCTest - iOS unit tests (`SundeeFundeeKitTests` target)

**Build/Dev:**
- Turbopack - Dev bundler (enabled via `turbopack: {}` in `web-app/next.config.ts`)
- TypeScript 5.x - Type checking (web app target ES2018, functions target ES2022)
- ESLint 9.x with `eslint-config-next` - Linting (config: `web-app/eslint.config.mjs`)
- Tailwind CSS 4 via `@tailwindcss/postcss` - Styling (config: `web-app/postcss.config.mjs`)
- Serwist 9.5.7 - PWA service worker generation (config: `web-app/next.config.ts`)
- XcodeGen (`project.yml`) - Xcode project generation for iOS app
- Xcode 16.0+ - iOS build tool

## Key Dependencies

**Critical:**
- `firebase` 12.11.0 - Client SDK: Auth, Firestore (web app)
- `firebase-admin` 13.7.0 - Admin SDK: server-side Auth verification, Firestore access (web app API routes and Cloud Functions)
- `stripe` 21.0.1 - Payment processing: checkout sessions, webhooks, billing portal
- `@google/genai` ^1.47.0 - Vertex AI Gemini client for web app AI workout generation
- `@google-cloud/vertexai` ^1.9.0 - Vertex AI Gemini client for Cloud Functions
- `next` 16.2.1 - Core framework

**Infrastructure:**
- `@serwist/next` 9.5.7 - PWA service worker integration with Next.js
- `next-sitemap` 4.2.3 - Sitemap and robots.txt generation on build
- `gray-matter` 4.0.3 - MDX/YAML frontmatter parsing (blog posts)
- `sanitize-html` 2.17.2 - HTML sanitization
- `@tiptap/*` 3.21.0 - Rich text editor (code-block, image, link, placeholder extensions)

**Development:**
- `tsx` 4.21.0 - TypeScript execution helper
- `@types/node` 20.x, `@types/react` 19.x, `@types/react-dom` 19.x - Type definitions

## Configuration

**Environment:**
- Path alias: `@/*` maps to `./src/*` (TypeScript and Vitest)
- TypeScript strict mode enabled in all projects
- Swift strict concurrency: `SWIFT_STRICT_CONCURRENCY: complete`
- ESLint: core-web-vitals + typescript configs from `eslint-config-next`
- Turbopack enabled in dev mode; Serwist disabled in dev (webpack/Turbopack conflict)

**Build:**
- `web-app/next.config.ts` - Next.js config with Serwist PWA, Firebase Auth rewrites, security headers
- `web-app/tsconfig.json` - TypeScript config (ES2018 target, bundler module resolution)
- `firebase/functions/tsconfig.json` - Functions TypeScript config (ES2022 target, commonjs output to `lib/`)
- `web-app/vitest.config.ts` - Test config (globals, node environment, v8 coverage on `src/lib/domain/**`)
- `web-app/postcss.config.mjs` - PostCSS with `@tailwindcss/postcss`
- `web-app/next-sitemap.config.js` - Sitemap generation (excludes API and protected routes)
- `web-app/eslint.config.mjs` - ESLint flat config
- `SundeeFundee/Package.swift` - Swift Package (iOS 18, macOS 15, watchOS 11)
- `SundeeFundeeApp/project.yml` - XcodeGen project config

**iOS App Signing:**
- Bundle ID: `com.sundeefundee.app`
- Development team: `87VVCMCW3F`
- Code signing: Automatic (`CODE_SIGN_STYLE` not hardcoded)
- Widgets extension: `com.sundeefundee.app.widgets`
- App Group: `group.com.sundeefundee.shared`

## Platform Requirements

**Development:**
- Node.js 20+ (Cloud Functions engine requirement; dev machine runs 25.x)
- npm 11.x
- Xcode 16.0+ with Swift 6.0+
- Firebase CLI (for Cloud Functions deployment)
- Vercel CLI (for web app deployment)

**Production:**
- Web app: Vercel (Next.js 16, App Router, SSR)
- Cloud Functions: Google Cloud (us-central1, 512MiB memory, 120s timeout)
- iOS app: Apple App Store (iOS 18.0+)
- Database: Cloud Firestore (NoSQL, us-central1)
- AI: Vertex AI Gemini (us-central1)

---

*Stack analysis: 2026-04-08*
