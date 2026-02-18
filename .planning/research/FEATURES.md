# Feature Research

**Domain:** Workout Tracking
**Researched:** 2026-02-17

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Workout Logger** | Core utility. Must be fast and frictionless. | Medium | Use `RestTimerContext` for integrated timers. |
| **Progress Charts** | Visual feedback on 1RM and Volume. | Medium | **Recharts** is standard. |
| **Exercise Database** | Need references for form and muscle groups. | Low | Static JSON/TS file is sufficient. |
| **Rest Timer** | Essential for serious lifting. | Low | Must persist state across navigation. |
| **Offline Support** | Gyms often have poor signal. | High | **Dexie.js** + Service Worker critical. |
| **Account/Sync** | Backup data if phone is lost. | Medium | Supabase integration. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Smart Recommendations** | "What weight should I lift next?" reduces friction. | High | Rules engine based on history. |
| **Plateau Detection** | Proactively suggests deloads. | Medium | Algorithm: 3+ stalls = deload. |
| **1RM Estimator** | Calculate max without testing (safer). | Low | Epley/Brzycki formulas. |
| **Sync across Devices** | Start on phone, review on desktop. | High | Requires robust conflict resolution. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Social Feed** | Distracts from utility. Increases moderation burden. | Focus on personal progress sharing (share image). |
| **Video Uploads** | High storage cost and complexity. | Link to YouTube/Instagram. |
| **Hardware Integration** | Bluetooth scale/HR monitor integration is finicky. | Manual entry (keep it simple). |

## Feature Dependencies

```
Workout Logger → Exercise Database (Need exercises to log)
Progress Charts → Workout Logger (Need data to visualize)
Smart Recommendations → Workout Logger (Need history for logic)
Sync → Account (Need user ID to partition data)
```

## MVP Recommendation

Prioritize:
1.  **Workout Logger** (Core loop)
2.  **Exercise Database** (Static content)
3.  **Progress Charts** (Retention hook)
4.  **Offline Support** (Critical UX)

Defer: **Social Features**, **Advanced Analytics** (Wait for data density).

## Sources

- [Competitor Analysis (Strong, Hevy)](https://www.strong.app/)
- [Local-First Case Studies](https://localfirstweb.dev/)
