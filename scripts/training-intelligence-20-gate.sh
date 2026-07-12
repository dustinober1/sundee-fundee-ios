#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE="$ROOT/SundeeFundee"
APP="$ROOT/SundeeFundeeApp"
SCHEMA="$APP/cloudkit-schema.json"
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'

step() { printf '\n== %s ==\n' "$1"; }
fail() { printf 'Gate failed: %s\n' "$1" >&2; exit 1; }

step 'Release-action safety assertions'
[[ "${TRAINING_INTELLIGENCE_GATE_ALLOW_STORE_ACTIONS:-0}" != 1 ]] \
  || fail 'store actions are disabled; never set TRAINING_INTELLIGENCE_GATE_ALLOW_STORE_ACTIONS=1'
FASTFILE="$APP/fastlane/Fastfile"
[[ -f "$FASTFILE" ]] || fail "missing Fastfile: $FASTFILE"
rg -q 'lane[[:space:]]+:release' "$FASTFILE" \
  || fail 'Fastfile is missing the documented :release lane declaration'
rg -q 'upload_to_app_store' "$FASTFILE" \
  || fail 'Fastfile :release lane no longer declares upload_to_app_store; review its store-action policy'
rg -q 'submit_for_review:[[:space:]]*true' "$FASTFILE" \
  || fail 'Fastfile :release lane no longer declares submit_for_review: true; review its store-action policy'
echo 'Fastfile :release lane contains upload/submit definitions; this validation gate never invokes that lane.'

# Scan executable release scripts and CI workflows for direct store actions. The
# Fastfile is intentionally excluded here because its :release lane is the
# documented definition checked above, not an invocation performed by this gate.
RELEASE_FILES=()
while IFS= read -r file; do RELEASE_FILES+=("$file"); done < <(
    find "$ROOT/scripts" "$APP/fastlane" "$ROOT/.github" -type f \
      \( -name '*.sh' -o -name '*.rb' -o -path '*/.github/workflows/*' \) \
      ! -path "$ROOT/scripts/training-intelligence-20-gate.sh" \
      ! -path "$FASTFILE" -print 2>/dev/null
)
if ((${#RELEASE_FILES[@]} > 0)) && rg -n \
    '(^|[;&|[:space:]])(bundle[[:space:]]+exec[[:space:]]+)?fastlane[[:space:]]+(release|deliver)\b|xcodebuild[[:space:]].*\barchive\b|deliver[[:space:]]+submit\b|upload_to_app_store|submit_for_review|pilot\(|deliver\(|altool|notarytool' \
    "${RELEASE_FILES[@]}" | rg -v ':[[:space:]]*#' >/dev/null; then
    fail 'archive/upload/submission command found in release scripts or CI workflows'
fi
echo 'No archive, upload, deliver, or submit invocation is permitted by this gate.'

step 'CloudKit schema guards'
[[ -s "$SCHEMA" ]] || fail "missing schema: $SCHEMA"
for record in TodayWorkoutPreference DailyReadinessRecord; do
    rg -q "RECORD TYPE $record[[:space:]]*\\(" "$SCHEMA" \
      || fail "schema missing $record"
    awk "/RECORD TYPE $record/,/\\);/" "$SCHEMA" | rg -q '"___recordID"[[:space:]]+REFERENCE QUERYABLE' \
      || fail "$record is missing queryable ___recordID"
done
awk '/RECORD TYPE DailyReadinessRecord/,/\);/' "$SCHEMA" | rg -q 'schemaVersion[[:space:]]+INT64' \
  || fail 'DailyReadinessRecord is missing schemaVersion'
echo 'DailyReadinessRecord and TodayWorkoutPreference schema/index guards passed.'

step 'Privacy-safe source scans'
SOURCE_DIRS=("$PACKAGE/Sources/SundeeFundeeKit" "$APP/SundeeFundee" "$APP/SundeeFundeeWidgets")
if rg -n --glob '*.swift' '(AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|http://)' "${SOURCE_DIRS[@]}" >/dev/null; then
    fail 'secret, private key, or insecure HTTP literal found in Swift sources'
fi
if rg -n --glob '*.swift' 'ShareSanitizedSummary[[:space:]]*\([^)]*(health|cycle|menstrual|pain|symptom|sleep|hrv|privateNote)' \
    "$PACKAGE/Sources/SundeeFundeeKit" >/dev/null; then
    fail 'share payload appears to accept raw health/cycle/pain/private-note fields'
fi
echo 'No credential/insecure transport literals or raw sensitive share fields found.'

step 'Metadata and screenshot presence/dimensions'
METADATA="$APP/fastlane/metadata/en-US"
for file in name subtitle promotional_text keywords description release_notes privacy_url support_url marketing_url; do
    [[ -s "$METADATA/$file.txt" ]] || fail "missing or empty metadata: $file.txt"
done
SCREENSHOTS="$APP/fastlane/screenshots/en-US"
iphone_count=$(find "$SCREENSHOTS" -type f -name 'iPhone 17 Pro-*.png' | wc -l | tr -d ' ')
ipad_count=$(find "$SCREENSHOTS" -type f -name 'iPad Pro 13-inch (M5)-*.png' | wc -l | tr -d ' ')
(( iphone_count >= 1 )) || fail 'no iPhone 17 Pro screenshots found'
(( ipad_count >= 1 )) || fail 'no iPad Pro 13-inch screenshots found'
while IFS= read -r image; do
    dimensions=$(sips -g pixelWidth -g pixelHeight "$image" 2>/dev/null | awk '/pixelWidth|pixelHeight/ { printf "%s%s", (n++ ? "x" : ""), $2 }')
    case "$(basename "$image"):$dimensions" in
        iPhone\ 17\ Pro-*:1206x2622|iPad\ Pro\ 13-inch\ \(M5\)-*:2064x2752) ;;
        *) fail "unexpected screenshot dimensions: $image ($dimensions)" ;;
    esac
done < <(find "$SCREENSHOTS" -type f -name '*.png' -print)
echo "Metadata present; validated $((iphone_count + ipad_count)) screenshots."

step 'Full Swift package tests'
cd "$PACKAGE"
swift test

step 'Training Intelligence targeted tests'
run_targeted() {
    local filter="$1" output test_count
    output="$(swift test --filter "$filter" 2>&1)" || { printf '%s\n' "$output"; return 1; }
    printf '%s\n' "$output"
    test_count="$(printf '%s\n' "$output" | sed -nE 's/.*Executed ([0-9]+) tests?.*/\1/p' | tail -1)"
    if [[ -z "$test_count" ]]; then
        test_count="$(printf '%s\n' "$output" | rg -c 'Test Case .* started' || true)"
    fi
    [[ "$test_count" =~ ^[0-9]+$ ]] && (( test_count > 0 )) \
      || fail "targeted filter '$filter' ran zero tests"
}
run_targeted Readiness
run_targeted Deload
run_targeted Share

step 'Simulator build and UI smoke tests'
cd "$APP"
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination "$DESTINATION" build
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination "$DESTINATION" \
  test -only-testing:SundeeFundeeUITests/SundeeFundeeScreenshotTests

step 'SwiftLint'
cd "$ROOT"
command -v swiftlint >/dev/null 2>&1 || fail 'swiftlint is not installed'
swiftlint --config .swiftlint.yml

step 'Git status cleanliness'
status="$(git -C "$ROOT" status --short)"
if [[ -n "$status" ]]; then
    while IFS= read -r line; do
        [[ "$line" =~ ^\?\?[[:space:]]+(SundeeFundee/\.build/|SundeeFundeeApp/DerivedData/|.*\.xcresult$) ]] \
            || fail "unexpected working-tree change: $line"
    done <<< "$status"
    echo 'Only documented generated test artifacts are present.'
else
    echo 'Git status is clean.'
fi

echo
echo 'Training Intelligence 2.0 release gate passed.'
echo 'This gate does not archive, upload, deliver, or submit the app.'
