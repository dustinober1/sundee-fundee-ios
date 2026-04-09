# Phase 6: Gitignore Update - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary
.gitignore reflects iOS-only project with no web platform patterns.

</domain>

<decisions>
### Claude's Discretion
All implementation choices are at Claude's discretion.

</decisions>

<code_context>
## Current .gitignore Analysis
Lines to REMOVE (non-iOS patterns):
- functions/node_modules/ (Firebase Functions)
- node_modules/ (Node.js)
- .next/ (Next.js)
- dist/ (Web build output)
- __pycache__/, *.pyc, .venv/, venv/ (Python — scripts/ deleted)
- coverage/ (Web app test coverage)
- .vercel (Vercel deployment)
- .env*.local (Web app env)
- .env* / !.env.example (generic env — keep for secrets)

Lines to KEEP:
- Xcode section (xcuserstate, DerivedData, etc.)
- Swift Package Manager (.build/, Package.resolved)
- macOS section (.DS_Store, etc.)
- IDE section (.vscode/)
- Secrets section (*.pem, .env*)
- *.log
- GSD baseline section

</code_context>

<specifics>
## New patterns to ADD
- *.ipa (built iOS apps)
- *.dSYM.zip (debug symbols)

</specifics>

<deferred>
None.

</deferred>
