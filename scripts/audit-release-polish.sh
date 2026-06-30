#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Hardcoded UI colors =="
rg -n 'Color\.(red|orange|green|blue|yellow|purple|pink|gray|black|white)' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundeeWidgets || true

echo ""
echo "== User-facing localizedDescription candidates =="
rg -n 'localizedDescription' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundee || true

echo ""
echo "== Bare ProgressView candidates =="
rg -n 'ProgressView\(\)' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundeeWidgets || true

echo ""
echo "== Fixed-size app UI font candidates =="
rg -n '\.font\(\.system\(size:' \
  SundeeFundee/Sources/SundeeFundeeKit/UI \
  SundeeFundeeApp/SundeeFundeeWidgets || true

echo ""
echo "== Haptic call sites =="
rg -n 'HapticFeedback\.' \
  SundeeFundee/Sources/SundeeFundeeKit/UI || true
