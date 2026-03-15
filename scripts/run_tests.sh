#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# run_tests.sh – Convenience runner for Activity Ranking Maestro test suites
#
# Usage:
#   ./scripts/run_tests.sh [suite] [--platform android|ios]
#
# Suites:
#   all             Run every flow (default)
#   smoke           Run only @smoke tagged flows
#   autocomplete    Run only autocomplete flows
#   ranking         Run only activity-ranking flows
#   edge            Run only edge-case flows
#   android         Run only @android-tagged flows
#   ios             Run only @ios-tagged flows
#
# Environment variables:
#   MAESTRO_APP_ID  Package name (Android) or bundle ID (iOS).
#                   Android default: com.example.activityranking
#                   iOS default:     com.example.ActivityRanking
#
# Examples:
#   MAESTRO_APP_ID=com.example.activityranking ./scripts/run_tests.sh smoke
#   MAESTRO_APP_ID=com.example.ActivityRanking ./scripts/run_tests.sh ios
#   ./scripts/run_tests.sh all
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
SUITE="${1:-all}"
APP_ID="${MAESTRO_APP_ID:-com.example.activityranking}"
FLOWS_DIR="$(cd "$(dirname "$0")/.." && pwd)/flows"

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ── Check Maestro is installed ────────────────────────────────────────────────
if ! command -v maestro &>/dev/null; then
  error "Maestro CLI not found. Install it with:"
  echo "  curl -Ls 'https://get.maestro.mobile.dev' | bash"
  exit 1
fi

info "Maestro version: $(maestro --version 2>/dev/null || echo 'unknown')"
info "App ID          : ${APP_ID}"
info "Suite           : ${SUITE}"
info "Flows directory : ${FLOWS_DIR}"
echo ""

# ── Export app ID so subflows can read it ─────────────────────────────────────
export MAESTRO_APP_ID="${APP_ID}"

# ── Run function ──────────────────────────────────────────────────────────────
run_suite() {
  local label="$1"
  shift
  info "Running suite: ${label}"
  maestro test "$@"
  local exit_code=$?
  if [ $exit_code -eq 0 ]; then
    info "Suite '${label}' PASSED"
  else
    error "Suite '${label}' FAILED (exit code: ${exit_code})"
  fi
  return $exit_code
}

# ── Suite dispatch ────────────────────────────────────────────────────────────
case "$SUITE" in
  all)
    run_suite "All flows" \
      "${FLOWS_DIR}/autocomplete" \
      "${FLOWS_DIR}/activity_ranking" \
      "${FLOWS_DIR}/edge_cases"
    ;;

  smoke)
    run_suite "Smoke tests" \
      --include-tags smoke \
      "${FLOWS_DIR}/autocomplete" \
      "${FLOWS_DIR}/activity_ranking"
    ;;

  autocomplete)
    run_suite "Autocomplete" \
      "${FLOWS_DIR}/autocomplete"
    ;;

  ranking)
    run_suite "Activity Ranking" \
      "${FLOWS_DIR}/activity_ranking"
    ;;

  edge)
    run_suite "Edge Cases" \
      "${FLOWS_DIR}/edge_cases"
    ;;

  android)
    run_suite "Android-only" \
      --include-tags android \
      "${FLOWS_DIR}/autocomplete"
    ;;

  ios)
    run_suite "iOS-only" \
      --include-tags ios \
      "${FLOWS_DIR}/autocomplete"
    ;;

  *)
    error "Unknown suite: '${SUITE}'"
    echo ""
    echo "Valid suites: all | smoke | autocomplete | ranking | edge | android | ios"
    exit 1
    ;;
esac
