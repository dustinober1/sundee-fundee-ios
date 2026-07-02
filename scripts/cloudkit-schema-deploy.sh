#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$ROOT/SundeeFundeeApp/cloudkit-schema.json"
TEAM_ID="${CLOUDKIT_TEAM_ID:-87VVCMCW3F}"
CONTAINER_ID="${CLOUDKIT_CONTAINER_ID:-iCloud.com.sundeefundee.app}"
ENVIRONMENT="${1:-development}"
ACTION="${2:-validate}"

usage() {
    cat <<'USAGE'
Usage:
  scripts/cloudkit-schema-deploy.sh [development] [validate|import]

Environment:
  CLOUDKIT_MANAGEMENT_TOKEN must be set, or a token must already be saved with:
    xcrun cktool save-token

Optional overrides:
  CLOUDKIT_TEAM_ID
  CLOUDKIT_CONTAINER_ID

Production schema deployment is not supported by cktool schema import.
After importing Development, deploy schema changes from CloudKit Dashboard.
USAGE
}

case "$ENVIRONMENT" in
    development) ;;
    production)
        echo "cktool schema validate/import is not applicable to Production."
        echo "Import Development first, then deploy schema changes from CloudKit Dashboard."
        exit 64
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 64
        ;;
esac

case "$ACTION" in
    validate|import) ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 64
        ;;
esac

if ! xcrun --find cktool >/dev/null 2>&1; then
    echo "cktool was not found. Install Xcode command line tools and try again."
    exit 127
fi

LIVE_SCHEMA="$(mktemp "${TMPDIR:-/tmp}/sundee-live-schema.XXXXXX")"
MERGED_SCHEMA="$(mktemp "${TMPDIR:-/tmp}/sundee-merged-schema.XXXXXX")"

cleanup() {
    rm -f "$LIVE_SCHEMA" "$MERGED_SCHEMA"
}
trap cleanup EXIT

xcrun cktool export-schema \
    --team-id "$TEAM_ID" \
    --container-id "$CONTAINER_ID" \
    --environment "$ENVIRONMENT" \
    --output-file "$LIVE_SCHEMA"

cp "$LIVE_SCHEMA" "$MERGED_SCHEMA"

awk '
    FNR == NR {
        if ($0 ~ /^    RECORD TYPE /) {
            live[$3] = 1
        }
        next
    }

    /^    RECORD TYPE / {
        recordType = $3
        printing = !(recordType in live)
        if (printing) {
            print ""
        }
    }

    printing {
        print
    }

    printing && /^    \);/ {
        printing = 0
    }
' "$LIVE_SCHEMA" "$SCHEMA" >> "$MERGED_SCHEMA"

if [[ "$ACTION" == "validate" ]]; then
    xcrun cktool validate-schema \
        --team-id "$TEAM_ID" \
        --container-id "$CONTAINER_ID" \
        --environment "$ENVIRONMENT" \
        --file "$MERGED_SCHEMA"
else
    xcrun cktool import-schema \
        --team-id "$TEAM_ID" \
        --container-id "$CONTAINER_ID" \
        --environment "$ENVIRONMENT" \
        --validate \
        --file "$MERGED_SCHEMA"
fi
