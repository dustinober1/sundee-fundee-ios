# Phase 5: Root Config Cleanup - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

All root-level configuration files for non-iOS platforms are removed.

</domain>

<decisions>
### Claude's Discretion
All implementation choices are at Claude's discretion.

</decisions>

<code_context>
## Existing Code Insights
AUDIT.md Section 2 lists all root files and whether they're needed for iOS.

</code_context>

<specifics>
## Files to Remove
- package.json, package-lock.json — Node.js dependencies
- firebase.json, firestore.indexes.json, .firebaserc — Firebase config
- .dev.vars, wrangler.toml — Cloudflare Workers
- teenybase.ts — Teenybase types
- opencode.json — OpenCode config
- skills-lock.json — Agent skills lockfile
- backlog.md — Backlog tracking

## Files to KEEP
- Logo.jpeg — App logo image
- .mcp.json — MCP server config (XcodeBuildMCP)
- readme.md — Needs rewrite in Phase 7
- AGENTS.md — Needs rewrite (references XcodeBuildMCP)
- .gitignore — Needs update in Phase 6
- CLAUDE.md — Needs rewrite in Phase 7

</specifics>

<deferred>
None.

</deferred>
