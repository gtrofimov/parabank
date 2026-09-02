#!/usr/bin/env bash
# collect-metrics.sh — Phase 4 metrics collection
# Usage:  cd /home/gtrofimov/parasoft/git/parabank
#         ./benchmark/data/collect-metrics.sh <run_number> <condition>
# Output: benchmark/data/run-<condition>-<N>.json
#
# Preconditions:
#   - benchmark/data/run-N.log exists with START=, END=, B_START=, B_END=, TESTS_REMOVED= entries
#   - mvn test has already been run (Surefire reports in target/surefire-reports/)
#   - Failing tests have already been removed (Phase 2 step 6 / Phase 3 step 5)

set -uo pipefail

RUN_N="${1:?Usage: $0 <run_number> <condition>}"
CONDITION="${2:?Usage: $0 <run_number> <condition>}"
BRANCH=$(git branch --show-current)
LOG_FILE="benchmark/data/run-${CONDITION}-${RUN_N}.log"
OUTPUT="benchmark/data/run-${CONDITION}-${RUN_N}.json"

echo "=== collect-metrics.sh: run=${CONDITION}-${RUN_N} branch=${BRANCH} ==="

if [ ! -f "$LOG_FILE" ]; then
  echo "ERROR: log file $LOG_FILE not found" >&2
  exit 1
fi

# ── Timestamps & elapsed ──────────────────────────────────────────────────────
START_TS=$(grep -oP '\bSTART=\K\S+' "$LOG_FILE" | tail -1)
END_TS=$(  grep -oP '\bEND=\K\S+'   "$LOG_FILE" | tail -1)
START_EPOCH=$(date -d "$START_TS" +%s 2>/dev/null || echo 0)
END_EPOCH=$(  date -d "$END_TS"   +%s 2>/dev/null || echo 0)
ELAPSED=$(( END_EPOCH - START_EPOCH ))
echo "  elapsed: ${ELAPSED}s  (${START_TS} → ${END_TS})"

# ── Test file counts (top-level domain only) ──────────────────────────────────
TESTS_GENERATED=$(find src/test/java/com/parasoft/parabank/domain \
  -maxdepth 1 -name "*Test.java" 2>/dev/null | wc -l | tr -d ' ')

TEST_METHODS=0
TEST_LINES=0
if [ "$TESTS_GENERATED" -gt 0 ]; then
  TEST_METHODS=$(grep -ch "@Test" src/test/java/com/parasoft/parabank/domain/*Test.java \
    2>/dev/null | awk '{s+=$1} END {print s+0}')
  TEST_LINES=$(cat src/test/java/com/parasoft/parabank/domain/*Test.java 2>/dev/null | wc -l | tr -d ' ')
fi
echo "  tests_generated=${TESTS_GENERATED}  test_methods=${TEST_METHODS}  test_lines=${TEST_LINES}"

# ── Surefire pass/fail (domain tests only) ────────────────────────────────────
TESTS_PASSING=0
TESTS_FAILING=0
SUREFIRE_FOUND=0
for report in target/surefire-reports/TEST-com.parasoft.parabank.domain.*.xml; do
  [ -f "$report" ] || continue
  SUREFIRE_FOUND=1
  t=$(grep -o 'tests="[0-9]*"'    "$report" | grep -o '[0-9]*' | head -1)
  f=$(grep -o 'failures="[0-9]*"' "$report" | grep -o '[0-9]*' | head -1)
  e=$(grep -o 'errors="[0-9]*"'   "$report" | grep -o '[0-9]*' | head -1)
  TESTS_PASSING=$(( TESTS_PASSING + ${t:-0} - ${f:-0} - ${e:-0} ))
  TESTS_FAILING=$(( TESTS_FAILING + ${f:-0} + ${e:-0} ))
done
if [ "$SUREFIRE_FOUND" -eq 0 ]; then
  echo "  WARN: no Surefire reports for com.parasoft.parabank.domain.* — run mvn test first"
fi
echo "  tests_passing=${TESTS_PASSING}  tests_failing=${TESTS_FAILING}"

# ── Full-suite regression check ───────────────────────────────────────────────
REGRESSION_FAILURES=0
for report in target/surefire-reports/TEST-*.xml; do
  [ -f "$report" ] || continue
  f=$(grep -o 'failures="[0-9]*"' "$report" | grep -o '[0-9]*' | head -1)
  e=$(grep -o 'errors="[0-9]*"'   "$report" | grep -o '[0-9]*' | head -1)
  REGRESSION_FAILURES=$(( REGRESSION_FAILURES + ${f:-0} + ${e:-0} ))
done
echo "  regression_failures=${REGRESSION_FAILURES}"
if [ "$REGRESSION_FAILURES" -gt 0 ]; then
  echo "  !! WARN: regression failures detected — run may be invalid !!"
fi

# ── Sub-package leak check ────────────────────────────────────────────────────
SUB_PKG_LEAK=$(find src/test/java/com/parasoft/parabank/domain \
  -mindepth 2 -name "*Test.java" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SUB_PKG_LEAK" -gt 0 ]; then
  echo "  !! WARN: sub-package leak detected (${SUB_PKG_LEAK} files) !!"
fi

# ── Billing: read values written by run.sh teardown (preferred) or fallbacks ──
# Priority 1: PREMIUM_REQUESTS= written directly by run.sh teardown (turn-delta × multiplier)
# Priority 2: MODEL_CALLS= × 3 from run.sh teardown
# Priority 3: B_START= / B_END= manual dashboard delta
COPILOT_MULTIPLIER=3

PREMIUM_REQUESTS=$(grep -oP '\bPREMIUM_REQUESTS=\K[0-9]+' "$LOG_FILE" | tail -1 || echo '')
if [ -n "${PREMIUM_REQUESTS:-}" ]; then
  MODEL_CALLS_EST=$(grep -oP '\bMODEL_CALLS=\K[0-9]+' "$LOG_FILE" | tail -1 || echo $(( PREMIUM_REQUESTS / COPILOT_MULTIPLIER )) )
  echo "  billing=auto  model_calls=${MODEL_CALLS_EST}  premium_requests=${PREMIUM_REQUESTS}"
else
  B_START=$(grep -oP '\bB_START=\K[0-9]+' "$LOG_FILE" | tail -1 || echo 0)
  B_END=$(  grep -oP '\bB_END=\K[0-9]+'   "$LOG_FILE" | tail -1 || echo 0)
  PREMIUM_REQUESTS=$(( ${B_END:-0} - ${B_START:-0} ))
  MODEL_CALLS_EST=$(( PREMIUM_REQUESTS / COPILOT_MULTIPLIER ))
  echo "  billing=dashboard  B_START=${B_START}  B_END=${B_END}  premium_requests=${PREMIUM_REQUESTS}"
fi
ESTIMATED_COST=$(printf "%.4f" "$(echo "scale=6; $PREMIUM_REQUESTS * 0.04" | bc 2>/dev/null || echo "0")")
echo "  estimated_cost_usd=${ESTIMATED_COST}"

# ── Other fields from log ─────────────────────────────────────────────────────
TESTS_REMOVED=$(grep "TESTS_REMOVED=" "$LOG_FILE" 2>/dev/null \
  | tail -1 | grep -oP 'TESTS_REMOVED=\K[0-9]+' || echo 0)
BLOCKED=$(grep -q "blocked=true" "$LOG_FILE" 2>/dev/null && echo true || echo false)

# ── Write JSON ────────────────────────────────────────────────────────────────
cat > "$OUTPUT" << ENDJSON
{
  "run_id": "${CONDITION}-${RUN_N}",
  "condition": "${CONDITION}",
  "run_number": "${RUN_N}",
  "branch": "${BRANCH}",
  "start_time_utc": "${START_TS:-unknown}",
  "end_time_utc": "${END_TS:-unknown}",
  "elapsed_seconds": ${ELAPSED},
  "premium_requests_used": ${PREMIUM_REQUESTS},
  "estimated_cost_usd": ${ESTIMATED_COST},
  "model_calls_estimated": ${MODEL_CALLS_EST},
  "tests_generated": ${TESTS_GENERATED},
  "test_methods": ${TEST_METHODS},
  "test_lines": ${TEST_LINES},
  "tests_passing": ${TESTS_PASSING},
  "tests_failing": ${TESTS_FAILING},
  "coverage_line_pct": 0,
  "coverage_branch_pct": 0,
  "fix_iterations": 0,
  "ai_self_correct_count": 0,
  "tests_removed": ${TESTS_REMOVED},
  "blocked": ${BLOCKED},
  "sub_pkg_leak_count": ${SUB_PKG_LEAK},
  "regression_failures": ${REGRESSION_FAILURES}
}
ENDJSON

echo "✓ Written: $OUTPUT"
