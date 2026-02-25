#!/usr/bin/env bash
set -euo pipefail

PHASE_DIR=".planning/phases/10-verification-evidence-and-regression-guardrails"
ARTIFACTS_ROOT="$PHASE_DIR/artifacts"
RUN_ID=""
ACCOUNT="elizabethober@me.com"
CONFIRM_CANONICAL="false"
CONFIRM_STATE="false"
SHOW_HELP="false"

usage() {
  cat <<'USAGE'
phase10-capture-uat-evidence.sh

Creates deterministic UAT artifact folders and run metadata for Phase 10 evidence.

Usage:
  bash scripts/phase10-capture-uat-evidence.sh [options]

Options:
  --run-id <id>                 Explicit run id (default: utc timestamp)
  --account <email>             Verification account email (default: elizabethober@me.com)
  --confirm-canonical-account   Mark canonical verification account pre-run checklist complete
  --confirm-state-drift-check   Mark state drift check complete
  --help                        Show this help

Pre-run checklist:
  1) canonical account is elizabethober@me.com
  2) onboarding status is complete (no resume prompt)
  3) active enrollment exists for workout start checkpoint
  4) app build + backend mode (emulator/live) is recorded
  5) storage path prepared for session video and checkpoint artifacts

If required checklist flags are missing, the script writes a blocked run record.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="${2:-}"
      shift 2
      ;;
    --account)
      ACCOUNT="${2:-}"
      shift 2
      ;;
    --confirm-canonical-account)
      CONFIRM_CANONICAL="true"
      shift
      ;;
    --confirm-state-drift-check)
      CONFIRM_STATE="true"
      shift
      ;;
    --help)
      SHOW_HELP="true"
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$SHOW_HELP" == "true" ]]; then
  usage
  exit 0
fi

if [[ -z "$RUN_ID" ]]; then
  RUN_ID="run-$(date -u +%Y%m%dT%H%M%SZ)"
fi

RUN_DIR="$ARTIFACTS_ROOT/$RUN_ID"
mkdir -p "$RUN_DIR"/{checkpoints,failures,logs}

METADATA_FILE="$RUN_DIR/run-metadata.md"
{
  echo "# Phase 10 UAT Run Metadata"
  echo
  echo "- run_id: $RUN_ID"
  echo "- timestamp_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- account: $ACCOUNT"
  echo "- pre-run checklist:"
  echo "  - canonical account confirmed: $CONFIRM_CANONICAL"
  echo "  - state drift check confirmed: $CONFIRM_STATE"
} > "$METADATA_FILE"

if [[ "$CONFIRM_CANONICAL" != "true" || "$CONFIRM_STATE" != "true" ]]; then
  {
    echo
    echo "## status"
    echo "blocked"
    echo
    echo "## reason"
    echo "pre-run checklist not complete; canonical account and/or state drift checks missing"
  } >> "$METADATA_FILE"

  echo "Blocked run recorded at $METADATA_FILE"
  exit 2
fi

{
  echo
  echo "## status"
  echo "ready-for-capture"
  echo
  echo "## expected artifacts"
  echo "- checkpoints/login.png"
  echo "- checkpoints/dashboard.png"
  echo "- checkpoints/programs.png"
  echo "- checkpoints/workout-start.png"
  echo "- checkpoints/final-success.png"
  echo "- logs/session-video.mp4"
} >> "$METADATA_FILE"

echo "UAT evidence scaffold created: $RUN_DIR"
