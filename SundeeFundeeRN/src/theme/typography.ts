/**
 * Typography tokens for Sundee Fundee.
 *
 * Uses system fonts (San Francisco on iOS, Roboto on Android, system-ui on web).
 * Custom Art Deco display fonts are deferred to a later plan.
 *
 * Scale follows a modular approach with clear hierarchy from display → caption.
 */

// ─── Font Sizes ───────────────────────────────────────────────────────────────

export const fontSize = {
  /** Display — hero numbers, large stats */
  display: 48,

  /** Heading 1 — screen titles */
  h1: 32,

  /** Heading 2 — section headers */
  h2: 24,

  /** Heading 3 — card titles, subsections */
  h3: 20,

  /** Heading 4 — list item titles */
  h4: 17,

  /** Body Large — primary body text */
  bodyLarge: 16,

  /** Body — default body text */
  body: 14,

  /** Body Small — secondary body text */
  bodySmall: 13,

  /** Caption — metadata, timestamps, labels */
  caption: 12,

  /** Micro — legal text, fine print */
  micro: 10,
} as const;

// ─── Font Weights ─────────────────────────────────────────────────────────────

export const fontWeight = {
  /** Black — display, hero numbers */
  black: '900' as const,

  /** Extra Bold — h1 headings */
  extraBold: '800' as const,

  /** Bold — h2, h3, button labels */
  bold: '700' as const,

  /** Semi Bold — h4, active navigation items */
  semiBold: '600' as const,

  /** Medium — body emphasis, labels */
  medium: '500' as const,

  /** Regular — default body text */
  regular: '400' as const,

  /** Light — secondary text, captions */
  light: '300' as const,
} as const;

// ─── Line Heights ─────────────────────────────────────────────────────────────

export const lineHeight = {
  tight: 1.15,
  normal: 1.4,
  relaxed: 1.6,
} as const;

// ─── Letter Spacing ───────────────────────────────────────────────────────────

export const letterSpacing = {
  /** Art Deco style — wide tracking for headings */
  wide: 1.5,

  /** Normal tracking for body text */
  normal: 0,

  /** Tight tracking for display numbers */
  tight: -0.5,
} as const;

// ─── Preset Text Styles ───────────────────────────────────────────────────────

/**
 * Preset style objects for common text elements.
 * Use these for consistent typography across the app.
 */
export const textStyles = {
  display: {
    fontSize: fontSize.display,
    fontWeight: fontWeight.black,
    letterSpacing: letterSpacing.tight,
    lineHeight: fontSize.display * lineHeight.tight,
  },

  h1: {
    fontSize: fontSize.h1,
    fontWeight: fontWeight.bold,
    letterSpacing: letterSpacing.wide,
    lineHeight: fontSize.h1 * lineHeight.tight,
  },

  h2: {
    fontSize: fontSize.h2,
    fontWeight: fontWeight.bold,
    letterSpacing: letterSpacing.wide,
    lineHeight: fontSize.h2 * lineHeight.normal,
  },

  h3: {
    fontSize: fontSize.h3,
    fontWeight: fontWeight.semiBold,
    letterSpacing: letterSpacing.normal,
    lineHeight: fontSize.h3 * lineHeight.normal,
  },

  h4: {
    fontSize: fontSize.h4,
    fontWeight: fontWeight.semiBold,
    letterSpacing: letterSpacing.normal,
    lineHeight: fontSize.h4 * lineHeight.normal,
  },

  body: {
    fontSize: fontSize.body,
    fontWeight: fontWeight.regular,
    letterSpacing: letterSpacing.normal,
    lineHeight: fontSize.body * lineHeight.relaxed,
  },

  bodyLarge: {
    fontSize: fontSize.bodyLarge,
    fontWeight: fontWeight.regular,
    letterSpacing: letterSpacing.normal,
    lineHeight: fontSize.bodyLarge * lineHeight.relaxed,
  },

  caption: {
    fontSize: fontSize.caption,
    fontWeight: fontWeight.regular,
    letterSpacing: letterSpacing.normal,
    lineHeight: fontSize.caption * lineHeight.normal,
  },

  button: {
    fontSize: fontSize.bodyLarge,
    fontWeight: fontWeight.bold,
    letterSpacing: letterSpacing.wide,
    lineHeight: fontSize.bodyLarge * lineHeight.tight,
  },
} as const;
