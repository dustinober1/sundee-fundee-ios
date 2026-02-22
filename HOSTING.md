HOSTING GUIDE for Sundee‑Fundee

Summary

This document lists recommended hosting approaches for Sundee‑Fundee (an iOS‑first SwiftUI + SwiftData app) and short pros/cons and next steps for each option.

1) Native iOS (Recommended when no custom server is needed) — CloudKit / iCloud
- Use the iCloud container (iCloud.com.sundeefundee.app) with SwiftData ModelContainer for automatic sync and Sign in with Apple integration.
- Pros: Minimal operational overhead, native SwiftData <-> CloudKit sync, good privacy (data stored in user iCloud), straightforward UX for iOS users.
- Cons: Apple‑only; limited server‑side business logic and cross‑platform access.

When to choose: App will remain iOS-only and most data is user-scoped (workouts, PRs, cycle data).

2) Cross-platform backend (Recommended when you need a server, web client, or shared relational data) — Supabase (recommended) or Firebase
- Supabase: Postgres database, Row-Level Security, realtime features, edge functions (good for relational data and web clients).
- Firebase: Firestore/Realtime, excellent mobile SDKs and auth, strong serverless functions ecosystem.
- Pros: Full control over server-side logic, easier to serve web/Android clients, analytics, centralized backups.
- Cons: Operational cost, need to manage auth mapping (Sign in with Apple -> server users), additional infra complexity.

When to choose: You need cross-platform clients, central analytics, multi-user shared data, or custom server logic.

3) Web frontend / Next.js hosting
- Vercel (recommended) for Next.js App Router deployments. Netlify or Render are good alternatives. Use S3 + CloudFront for large static assets.
- When web SSR or SEO matters, pick Vercel for zero-config Next.js deployments.

4) Serverless & Cloud Providers
- Use AWS Lambda / API Gateway, or GCP Cloud Functions, or Vercel Edge Functions for serverless endpoints.
- Use managed DBs (RDS, Cloud SQL) or Supabase for Postgres-backed workloads.

CI/CD and iOS distribution
- Use GitHub Actions for CI (lint, tests, xcodegen generate, xcodebuild). Use Fastlane for code signing and TestFlight/App Store uploads (or Xcode Cloud if preferred).
- Store secrets (App Store, Supabase/Firebase keys) in GitHub Actions secrets; never commit keys.

Operational & privacy notes
- CloudKit: ensure entitlements and iCloud container are configured and test CloudKit sync flows thoroughly.
- Server-backed: enforce TLS, encrypt sensitive data at rest, follow GDPR/CCPA practices if applicable.

Decision checklist
- Apple-only mobile + minimal server: CloudKit.
- Need relational DB & cross-platform API: Supabase.
- Primary web client + SSR: Vercel + Supabase/Firebase.
- Heavy custom server logic: AWS/GCP serverless + managed DB.

Next steps
- Decide primary hosting model.
- If CloudKit: confirm iCloud container and entitlements (iCloud.com.sundeefundee.app) and test SwiftData sync.
- If server-backed: prototype auth mapping (Sign in with Apple -> Supabase/Firebase user) and add CI secrets and env configuration.
