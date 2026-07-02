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
  scripts/cloudkit-schema-deploy.sh [development|production] [validate|import]

Environment:
  CLOUDKIT_MANAGEMENT_TOKEN must be set, or a token must already be saved with:
    xcrun cktool save-token

Optional overrides:
  CLOUDKIT_TEAM_ID
  CLOUDKIT_CONTAINER_ID

Production imports require:
  CONFIRM_PRODUCTION_CLOUDKIT_IMPORT=YES
USAGE
}

case "$ENVIRONMENT" in
    development|production) ;;
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

if [[ "$ENVIRONMENT" == "production" && "$ACTION" == "import" &&
    "${CONFIRM_PRODUCTION_CLOUDKIT_IMPORT:-}" != "YES" ]]; then
    echo "Refusing production import without CONFIRM_PRODUCTION_CLOUDKIT_IMPORT=YES."
    exit 64
fi

if ! xcrun --find cktool >/dev/null 2>&1; then
    echo "cktool was not found. Install Xcode command line tools and try again."
    exit 127
fi

if [[ "$ACTION" == "validate" ]]; then
    xcrun cktool validate-schema \
        --team-id "$TEAM_ID" \
        --container-id "$CONTAINER_ID" \
        --environment "$ENVIRONMENT" \
        --file "$SCHEMA"
else
    xcrun cktool import-schema \
        --team-id "$TEAM_ID" \
        --container-id "$CONTAINER_ID" \
        --environment "$ENVIRONMENT" \
        --validate \
        --file "$SCHEMA"
fi
