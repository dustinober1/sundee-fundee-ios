---
name: agents
description: Always-loaded project anchor. Read this first. Contains project identity, non-negotiables, commands, and pointer to ROUTER.md for full context.
last_updated: 2026-04-11
---

# Sundee Fundee

## What This Is
A native iOS app for cycle-aware strength training — adapts workout intensity, volume, and recovery recommendations based on menstrual cycle phases.

## Non-Negotiables
- Never write database queries outside `DataClientProtocol` — all persistence goes through the protocol
- All new types must conform to `Sendable` (Swift 6 strict concurrency is enforced project-wide)
- Domain logic stays pure — no framework imports, no side effects in `DomainLayer/`
- Never introduce subscription paywalls, purchase flows, or tier gating — the app is free
- Never submit to App Store without explicit user approval

## Commands
- Build: `cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- Test: `cd SundeeFundee && swift test`
- Generate project: `cd SundeeFundeeApp && xcodegen generate`

## Scaffold Growth
After every task: if no pattern exists for the task type you just completed, create one. If a pattern or context file is now out of date, update it. The scaffold grows from real work, not just setup. See the GROW step in `ROUTER.md` for details.

## Navigation
At the start of every session, read `ROUTER.md` before doing anything else.
For full project context, patterns, and task guidance — everything is there.
