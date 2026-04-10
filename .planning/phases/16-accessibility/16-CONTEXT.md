# Phase 16: Accessibility - Context

**Gathered:** 2026-04-10
**Status:** Ready for planning

<domain>
## Phase Boundary

The app is usable by people relying on VoiceOver, Dynamic Type, and sufficient color contrast. Add meaningful VoiceOver labels, use relative font sizing for body text, and ensure Art Deco theme colors meet WCAG AA contrast ratios.

</domain>

<decisions>
## Implementation Decisions

### VoiceOver & Dynamic Type
- Add `.accessibilityLabel()` and `.accessibilityHint()` to all interactive elements without labels
- Use SwiftUI's built-in relative sizing for all body text; keep display headings fixed-size

### Color Contrast
- Adjust Art Deco colors minimally (darken orange, lighten cream) until WCAG AA passes
- Verify contrast ratios manually via calculation + Xcode Accessibility Inspector

### Claude's Discretion
- Which specific elements need VoiceOver labels
- Exact color adjustments to meet AA
- Dynamic Type edge cases (charts, badges, compact UI)

</decisions>

<code_context>
## Existing Code Insights

Codebase context will be gathered during plan-phase research.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — use standard accessibility best practices.

</specifics>

<deferred>
## Deferred Ideas

None.

</deferred>
