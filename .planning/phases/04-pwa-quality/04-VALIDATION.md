---
phase: 4
slug: pwa-quality
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest 4.1.0 + @testing-library/react 16.3.2 |
| **Config file** | `pwa/vitest.config.ts` |
| **Quick run command** | `cd pwa && npx vitest run src/hooks` |
| **Full suite command** | `cd pwa && npx vitest run` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd pwa && npx vitest run src/hooks`
- **After every plan wave:** Run `cd pwa && npx vitest run`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | PWA-01 | manual | `ls -la pwa/public/icons/ && file pwa/public/icons/*.png` | n/a | ⬜ pending |
| 04-01-02 | 01 | 1 | PWA-01 | manual | `node -e "const s=require('sharp'); s('pwa/public/icons/icon-192.png').metadata().then(m=>console.log(m.width,m.height))"` | n/a | ⬜ pending |
| 04-02-01 | 02 | 1 | PWA-03 | manual | DevTools → Cache Storage → check offline.html entry | n/a | ⬜ pending |
| 04-02-02 | 02 | 1 | PWA-03 | manual | `test -f pwa/public/offline.html && echo OK` | n/a | ⬜ pending |
| 04-03-01 | 03 | 2 | PWA-04 | unit | `cd pwa && npx vitest run src/hooks/useInstallPrompt.test.ts` | ❌ W0 | ⬜ pending |
| 04-04-01 | 04 | 2 | PWA-02 | manual | Lighthouse PWA audit against deployed URL | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pwa/src/hooks/` directory — create if not exists
- [ ] `pwa/src/hooks/useInstallPrompt.test.ts` — stubs for PWA-04 (Android state, iOS state, standalone suppression, sessionStorage dismissal)

*Existing infrastructure covers PWA-01, PWA-02, PWA-03 (manual verification).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Icon PNGs exist and match manifest dimensions | PWA-01 | File output from script, not runtime code | Run `node scripts/generate-icons.mjs`, verify at `pwa/public/icons/` |
| Lighthouse PWA audit green | PWA-02 | Requires deployed URL + Chrome DevTools | Deploy, open Chrome DevTools → Lighthouse → PWA audit |
| Offline page served when offline | PWA-03 | Requires service worker + network simulation | Build, serve via `npx vite preview`, toggle offline in DevTools → Network |
| Maskable icon safe zone | PWA-01 | Visual check at maskable.app | Upload `icon-512.png` to https://maskable.app |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
