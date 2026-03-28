# Pricing & AI Model Update

**Date:** 2026-03-28
**Scope:** Mechanical value/string replacements across codebase — no architectural or behavioral changes.

## Summary

Update subscription pricing from $6.99/$12.99 to $4.99/$9.99 (monthly) and replace Anthropic model references (Haiku/Sonnet) with Cloudflare Workers AI models under new "Sundee AI" branding.

## Pricing Changes

| Product | Old Price | New Price |
|---------|-----------|-----------|
| Plus Monthly | $6.99 | $4.99 |
| Plus Annual | $54.99 | $39.99 |
| Premium Monthly | $12.99 | $9.99 |
| Premium Annual | $99.99 | $79.99 |

## AI Model Changes

| Tier | Old Model ID | New Model ID | Old Display | New Display |
|------|-------------|-------------|-------------|-------------|
| Free | `"on-device"` | `"on-device"` (unchanged) | On-device | On-device |
| Plus | `"haiku"` | `"@cf/qwen/qwen3-30b-a3b-fp8"` | Haiku | Sundee AI |
| Premium | `"sonnet"` | `"@cf/nvidia/nemotron-3-120b-a12b"` | Sonnet | Sundee AI Pro |

Future Ultra tier will use "Sundee AI Ultra" (not part of this change).

## Files to Modify

### Domain Layer
- **`SubscriptionTier.swift`** — Monthly/annual prices, `aiModelIdentifier` values, display descriptions

### UI Layer
- **`PaywallView.swift`** — Fallback prices, highlight copy, comparison table model names
- **`ManageSubscriptionView.swift`** — Tier description copy

### StoreKit Config
- **`SundeeFundee.storekit`** — Display prices and product descriptions

### Tests
- **`SubscriptionTests.swift`** — All price assertions, model string assertions, description assertions

## Approach

Single pass through all files. No feature flags, no backwards compatibility shims.

- **Prices:** Direct number replacements at every location.
- **Model identifiers:** String replacements. These are internal routing strings only used when the Cloudflare Worker proxy is wired up (future sub-project), so changing them now is safe.
- **User-facing copy:** "Haiku-powered" becomes "Sundee AI-powered", "Sonnet-powered" becomes "Sundee AI Pro-powered". Applies to descriptions, highlights, comparison rows, and value propositions.
- **Tests:** Update all existing assertions to match new values. No new tests needed.
- **Build + full test suite run** to confirm nothing was missed.

## Out of Scope

- App Store Connect price changes (requires App Store action, separate TODO)
- StoreKit entitlement re-enablement (Sub-project 4)
- Cloudflare Worker proxy implementation (Sub-project 2)
- New features or behavioral changes
