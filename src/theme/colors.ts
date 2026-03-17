/**
 * Art Deco color palette for Sundee Fundee.
 *
 * Primary palette inspired by 1920s Art Deco: warm cream backgrounds,
 * deep navy typography, and vibrant orange accents.
 */

// ─── Primary Palette ──────────────────────────────────────────────────────────

/** Warm cream — primary background color */
export const CREAM = '#F4F0DF';

/** Deep navy — primary text and structural elements */
export const NAVY = '#0D1A40';

/** Vibrant orange — accent, CTAs, highlights */
export const ORANGE = '#F2731A';

// ─── Extended Palette ─────────────────────────────────────────────────────────

/** Light cream — card surfaces, slightly elevated backgrounds */
export const CREAM_LIGHT = '#FAF7EF';

/** Dark navy — headings, strong emphasis */
export const NAVY_DARK = '#08102A';

/** Medium navy — secondary text on light backgrounds */
export const NAVY_MEDIUM = '#1E3A6E';

/** Orange hover/pressed state */
export const ORANGE_DARK = '#D45F0E';

/** Orange subtle — tinted backgrounds, badges */
export const ORANGE_LIGHT = '#FDE8D5';

/** Soft red for errors and destructive actions */
export const RED = '#C0392B';

/** Muted grey for disabled states */
export const GREY = '#9B9B9B';

/** Light grey for borders and dividers */
export const GREY_LIGHT = '#E0DDD4';

// ─── Semantic Aliases ─────────────────────────────────────────────────────────

/** Primary background — use for screen backgrounds */
export const background = CREAM;

/** Primary text color — use for body text and headings */
export const text = NAVY;

/** Accent color — use for CTAs, active states, highlights */
export const accent = ORANGE;

/** Surface color — use for cards and elevated panels */
export const surface = CREAM_LIGHT;

/** Error color — use for error messages and destructive UI */
export const error = RED;

/** Border/divider color */
export const border = GREY_LIGHT;

/** Disabled/muted text */
export const textMuted = GREY;

/** Secondary text (lighter than primary, darker than muted) */
export const textSecondary = NAVY_MEDIUM;
