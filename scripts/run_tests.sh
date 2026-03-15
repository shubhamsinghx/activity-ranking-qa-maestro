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
#   MAESTRO_APP_ID    Package name (Android) or bundle ID (iOS).
#                     Android default: com.example.activityranking
#                     iOS default:     com.example.ActivityRanking
#   RANKING_API_URL   (Optional) Base URL for the ranking API.  When set,
#                     validate_rank_range.js will run live HTTP assertions.
#   REPORTS_DIR       Directory for JUnit XML output.
#                     Default: <repo-root>/reports
#
# Examples:
#   MAESTRO_APP_ID=com.example.activityranking ./scripts/run_tests.sh smoke
#   MAESTRO_APP_ID=com.example.ActivityRanking ./scripts/run_tests.sh ios
#   REPORTS_DIR=/tmp/results ./scripts/run_tests.sh all
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

# ── Paths & defaults ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FLOWS_DIR="${REPO_ROOT}/flows"
SUITE="${1:-all}"
APP_ID="${MAESTRO_APP_ID:-com.example.activityranking}"
REPORTS_DIR="${REPORTS_DIR:-${REPO_ROOT}/reports}"

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
banner()  { echo -e "${BOLD}$*${NC}"; }

# ── Check Maestro is installed ────────────────────────────────────────────────
if ! command -v maestro &>/dev/null; then
  error "Maestro CLI not found. Install it with:"
  echo "  curl -Ls 'https://get.maestro.mobile.dev' | bash"
  exit 1
fi

info "Maestro version : $(maestro --version 2>/dev/null || echo 'unknown')"
info "App ID          : ${APP_ID}"
info "Suite           : ${SUITE}"
info "Flows directory : ${FLOWS_DIR}"
info "Reports dir     : ${REPORTS_DIR}"
echo ""

# ── Export env vars so subflows / JS scripts can read them ───────────────────
export MAESTRO_APP_ID="${APP_ID}"
export RANKING_API_URL="${RANKING_API_URL:-}"

# ── Tracking counters ────────────────────────────────────────────────────────
PASSED_SUITES=()
FAILED_SUITES=()

# ── Device reset helper ───────────────────────────────────────────────────────
# Runs the teardown subflow to neutralise any state left by stateful tests
# (airplane mode, screen rotation, etc.).  We ignore failures here — if the
# teardown itself errors we still want to run the next suite.
reset_device() {
  info "Resetting device state via teardown subflow …"
  maestro test "${FLOWS_DIR}/subflows/00_teardown.yaml" || \
    warn "Teardown returned non-zero; device state may not be fully reset."
}

# ── Run function ──────────────────────────────────────────────────────────────
# run_suite <label> <report-subdir> [extra maestro flags…] <flow-path(s)>
#
# Emits a JUnit XML file to ${REPORTS_DIR}/<report-subdir>/results.xml and
# appends the label to PASSED_SUITES or FAILED_SUITES.
run_suite() {
  local label="$1"
  local report_subdir="$2"
  shift 2

  local out_dir="${REPORTS_DIR}/${report_subdir}"
  mkdir -p "${out_dir}"

  info "Running suite: ${label}"
  maestro test \
    --format junit \
    --output "${out_dir}/results.xml" \
    "$@"
  local exit_code=$?

  if [ ${exit_code} -eq 0 ]; then
    info "Suite '${label}' PASSED"
    PASSED_SUITES+=("${label}")
  else
    error "Suite '${label}' FAILED (exit code: ${exit_code})"
    FAILED_SUITES+=("${label}")
  fi

  return ${exit_code}
}

# ── Suite dispatch ────────────────────────────────────────────────────────────
case "${SUITE}" in
  all)
    run_suite "Autocomplete"    "autocomplete" "${FLOWS_DIR}/autocomplete"
    reset_device
    run_suite "Activity Ranking" "ranking"      "${FLOWS_DIR}/activity_ranking"
    reset_device
    run_suite "Edge Cases"       "edge"         "${FLOWS_DIR}/edge_cases"
    ;;

  smoke)
    run_suite "Smoke" "smoke" \
      --include-tags smoke \
      "${FLOWS_DIR}/autocomplete" \
      "${FLOWS_DIR}/activity_ranking"
    ;;

  autocomplete)
    run_suite "Autocomplete" "autocomplete" "${FLOWS_DIR}/autocomplete"
    ;;

  ranking)
    run_suite "Activity Ranking" "ranking" "${FLOWS_DIR}/activity_ranking"
    ;;

  edge)
    run_suite "Edge Cases" "edge" "${FLOWS_DIR}/edge_cases"
    ;;

  android)
    run_suite "Android-only" "android" \
      --include-tags android \
      "${FLOWS_DIR}/autocomplete" \
      "${FLOWS_DIR}/activity_ranking"
    ;;

  ios)
    run_suite "iOS-only" "ios" \
      --include-tags ios \
      "${FLOWS_DIR}/autocomplete" \
      "${FLOWS_DIR}/activity_ranking"
    ;;

  *)
    error "Unknown suite: '${SUITE}'"
    echo ""
    echo "Valid suites: all | smoke | autocomplete | ranking | edge | android | ios"
    exit 1
    ;;
esac

# ── Final summary ─────────────────────────────────────────────────────────────
echo ""
banner "════════════════════════════════════════"
banner "  TEST RUN SUMMARY"
banner "════════════════════════════════════════"

for s in "${PASSED_SUITES[@]:-}"; do
  [ -n "${s}" ] && echo -e "  ${GREEN}PASSED${NC}  ${s}"
done
for s in "${FAILED_SUITES[@]:-}"; do
  [ -n "${s}" ] && echo -e "  ${RED}FAILED${NC}  ${s}"
done

TOTAL=$(( ${#PASSED_SUITES[@]} + ${#FAILED_SUITES[@]} ))
echo ""
info "${#PASSED_SUITES[@]} / ${TOTAL} suites passed"
info "JUnit reports written to: ${REPORTS_DIR}/"
banner "════════════════════════════════════════"

# Exit 1 if any suite failed
[ ${#FAILED_SUITES[@]} -eq 0 ]
