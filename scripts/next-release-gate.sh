#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$ROOT/SundeeFundeeApp/cloudkit-schema.json"

if ! grep -q 'RECORD TYPE TodayWorkoutPreference' "$SCHEMA"; then
    echo "CloudKit schema is missing TodayWorkoutPreference."
    exit 1
fi

if ! awk '/RECORD TYPE TodayWorkoutPreference/,/\);/' "$SCHEMA" | grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE'; then
    echo "CloudKit schema is missing queryable ___recordID for TodayWorkoutPreference."
    exit 1
fi

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "swiftlint is not installed. Install SwiftLint, then rerun this gate."
    exit 127
fi

cd "$ROOT/SundeeFundee"
swift test
swift test --filter SupportTip
swift test --filter DeepLinkRouterTests
swift test --filter BestNextWorkoutRequestBuilderTests
swift test --filter CoachPlanFeedbackServiceTests

cd "$ROOT/SundeeFundeeApp"
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

cd "$ROOT"
swiftlint --config .swiftlint.yml
