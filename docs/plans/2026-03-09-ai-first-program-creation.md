# AI-First Program Creation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reorder the admin program creation flow so AI generation comes first, before filling in metadata.

**Architecture:** Restructure `ProgramMetadataForm.tsx` into a two-path chooser: AI-first (primary) shows prompt + 4 config fields, generates program with auto-name, redirects to editor. Manual path (secondary) expands full form as before.

**Tech Stack:** Next.js, React 19, TypeScript, Tailwind CSS

---

### Task 1: Restructure ProgramMetadataForm.tsx

**Files:**
- Modify: `wod-dashboard/src/components/ProgramMetadataForm.tsx`

**Step 1: Restructure the component**

Replace the current single-form layout with a two-section layout:

**Section 1 (primary): "Generate with AI"**
- AI prompt textarea (large, prominent)
- 4 config pills in a row: duration (4/8/12), sessions/week (1-6), difficulty, category
- "Generate with AI" button (orange, prominent)
- No name, description, or start date fields — these are set after generation

**Section 2 (secondary): "Or build from scratch"**
- Collapsed by default, toggle to expand
- Shows full metadata form (name, category, description, duration, sessions/week, difficulty, start date)
- "Build Manually" button

**Step 2: Update handleGenerateWithAI**

- Auto-generate slug from AI prompt: take first 5 words, slugify, append timestamp suffix for uniqueness
- Auto-set name from prompt (first ~50 chars, title-cased) — admin can rename in editor
- Use `nextSunday()` as default start date
- Rest of logic stays the same (call API, save, redirect to editor)

**Step 3: Verify locally**

Run: `cd wod-dashboard && npm run dev`
- Navigate to `/programs/new`
- Confirm AI section is primary/top
- Confirm manual section is secondary/collapsible
- Test AI generation flow (prompt → generate → redirects to editor)
- Test manual flow still works

**Step 4: Commit**

```bash
git add wod-dashboard/src/components/ProgramMetadataForm.tsx
git commit -m "feat: AI-first program creation flow (issue #99)"
```
