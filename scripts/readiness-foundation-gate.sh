#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$ROOT/SundeeFundeeApp/cloudkit-schema.json"

grep -q 'RECORD TYPE DailyReadinessRecord' "$SCHEMA"
awk '/RECORD TYPE DailyReadinessRecord/,/\);/' "$SCHEMA" \
    | grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE'

cd "$ROOT/SundeeFundee"
swift test --filter Readiness
swift test --filter DailyTrainingContextBuilderTests
swift test --filter DailyReadinessServiceTests
swift test

cd "$ROOT/SundeeFundeeApp"
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

cd "$ROOT"
swiftlint --config .swiftlint.yml
