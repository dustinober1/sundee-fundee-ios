#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

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
