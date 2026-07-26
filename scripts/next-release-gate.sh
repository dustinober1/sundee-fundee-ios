#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="${CLOUDKIT_SCHEMA_PATH:-$ROOT/SundeeFundeeApp/cloudkit-schema.json}"
SCHEMA_ONLY=false

case "${1:-}" in
    "")
        ;;
    --schema-only)
        SCHEMA_ONLY=true
        ;;
    *)
        echo "Usage: scripts/next-release-gate.sh [--schema-only]"
        exit 2
        ;;
esac

record_schema() {
    local record_type="$1"
    awk -v record_type="$record_type" '
        $0 ~ "RECORD TYPE " record_type " \\(" { inside = 1 }
        inside { print }
        inside && /\);/ { exit }
    ' "$SCHEMA"
}

require_queryable_record_id() {
    local record_type="$1"
    local block="$2"
    if ! grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE' <<<"$block"; then
        echo "CloudKit schema is missing queryable ___recordID for $record_type."
        exit 1
    fi
}

require_field() {
    local record_type="$1"
    local block="$2"
    local field="$3"
    local field_type="$4"
    if ! grep -Eq "^[[:space:]]*$field[[:space:]]+$field_type([[:space:]]|,)" <<<"$block"; then
        echo "CloudKit schema is missing $record_type.$field as $field_type."
        exit 1
    fi
}

require_exact_application_fields() {
    local record_type="$1"
    local block="$2"
    shift 2
    local actual
    local expected
    actual="$(
        awk '
            $1 ~ /^[A-Za-z][A-Za-z0-9_]*$/ &&
            $2 ~ /^(STRING|INT64|DOUBLE|TIMESTAMP|REFERENCE|LIST<[^>]+>),?$/ {
                print $1
            }
        ' <<<"$block" | LC_ALL=C sort
    )"
    expected="$(printf '%s\n' "$@" | LC_ALL=C sort)"
    if [[ "$actual" != "$expected" ]]; then
        echo "CloudKit schema fields do not exactly match $record_type."
        echo "Expected:"
        echo "$expected"
        echo "Actual:"
        echo "$actual"
        exit 1
    fi
}

PRESENCE_SCHEMA="$(record_schema DailyPresenceRecord)"
if [[ -z "$PRESENCE_SCHEMA" ]]; then
    echo "CloudKit schema is missing DailyPresenceRecord."
    exit 1
fi
require_queryable_record_id "DailyPresenceRecord" "$PRESENCE_SCHEMA"
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" actionEvidenceRaw 'LIST<STRING>'
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" dateCreated STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" dateUpdated STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" dayKey STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" firstOpenDate STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" id STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" modelVersion INT64
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" mostRecentOpenDate STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" participationLevelRaw STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" statusRaw STRING
require_field "DailyPresenceRecord" "$PRESENCE_SCHEMA" timeZoneIdentifier STRING
require_exact_application_fields \
    "DailyPresenceRecord" "$PRESENCE_SCHEMA" \
    actionEvidenceRaw dateCreated dateUpdated dayKey firstOpenDate id modelVersion \
    mostRecentOpenDate participationLevelRaw statusRaw timeZoneIdentifier

REMINDER_SCHEMA="$(record_schema WorkoutReminderSettings)"
if [[ -z "$REMINDER_SCHEMA" ]]; then
    echo "CloudKit schema is missing WorkoutReminderSettings."
    exit 1
fi
require_queryable_record_id "WorkoutReminderSettings" "$REMINDER_SCHEMA"
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" dailyPlanEnabled INT64
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" dailyPlanHour INT64
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" dailyPlanMinute INT64
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" dateUpdated STRING
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" hour INT64
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" id STRING
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" isEnabled INT64
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" minute INT64
require_field "WorkoutReminderSettings" "$REMINDER_SCHEMA" preferredWeekdays 'LIST<INT64>'
require_exact_application_fields \
    "WorkoutReminderSettings" "$REMINDER_SCHEMA" \
    dailyPlanEnabled dailyPlanHour dailyPlanMinute dateUpdated hour id isEnabled minute \
    preferredWeekdays

WORKOUT_SCHEMA="$(record_schema Workout)"
if [[ -z "$WORKOUT_SCHEMA" ]]; then
    echo "CloudKit schema is missing Workout."
    exit 1
fi
require_field "Workout" "$WORKOUT_SCHEMA" kind STRING

if ! grep -q 'RECORD TYPE TodayWorkoutPreference' "$SCHEMA"; then
    echo "CloudKit schema is missing TodayWorkoutPreference."
    exit 1
fi

if ! awk '/RECORD TYPE TodayWorkoutPreference/,/\);/' "$SCHEMA" | grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE'; then
    echo "CloudKit schema is missing queryable ___recordID for TodayWorkoutPreference."
    exit 1
fi

if ! grep -q 'RECORD TYPE DailyReadinessRecord' "$SCHEMA"; then
    echo "CloudKit schema is missing DailyReadinessRecord."
    exit 1
fi

if ! awk '/RECORD TYPE DailyReadinessRecord/,/\);/' "$SCHEMA" | grep -q '"___recordID"[[:space:]]*REFERENCE QUERYABLE'; then
    echo "CloudKit schema is missing queryable ___recordID for DailyReadinessRecord."
    exit 1
fi

if ! awk '/RECORD TYPE DailyReadinessRecord/,/\);/' "$SCHEMA" | grep -q 'schemaVersion[[:space:]]\+INT64'; then
    echo "CloudKit schema is missing schemaVersion for DailyReadinessRecord."
    exit 1
fi

if [[ "$SCHEMA_ONLY" == true ]]; then
    echo "CloudKit schema validation passed."
    exit 0
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
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet test -only-testing:SundeeFundeeTests/StoreKitSupportTipStoreIntegrationTests

cd "$ROOT"
swiftlint --config .swiftlint.yml
