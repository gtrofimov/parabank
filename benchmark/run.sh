#!/usr/bin/env bash
# benchmark/run.sh — Benchmark run orchestrator
#
# Usage (from parabank root):
#   ./benchmark/run.sh setup    <condition> <N>   # prepare branch, clean state, start timer
#   ./benchmark/run.sh teardown <condition> <N>   # stop timer, cleanup, collect metrics
#
# Conditions: ai-only | ai-jtest
# N: 1, 2, 3   (or "dry" for test runs)
#
# Both setup and teardown must be called from the same working directory (parabank root).
# The log file benchmark/data/run-<condition>-<N>.log is shared between them.

set -euo pipefail

CMD="${1:?Usage: $0 <setup|teardown> <condition> <N>}"
CONDITION="${2:?Condition required: ai-only or ai-jtest}"
RUN_N="${3:?Run number required: 1 2 3}"

BASE_BRANCH="feature/demo-1"
BRANCH="benchmark/${CONDITION}-${RUN_N}"
LOG_FILE="benchmark/data/run-${CONDITION}-${RUN_N}.log"
DOMAIN_TEST_DIR="src/test/java/com/parasoft/parabank/domain"
COPILOT_MULTIPLIER=3   # Claude Sonnet 4.6 billing multiplier

ts()  { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { echo "$*" | tee -a "$LOG_FILE"; }

# ── Find the active transcript file ───────────────────────────────────────────
find_transcript() {
  local tdir
  tdir=$(find ~/.vscode-server/data/User/workspaceStorage -maxdepth 4 \
    -name "transcripts" -type d 2>/dev/null | head -1)
  [ -z "${tdir:-}" ] && return 0
  local newest
  newest=$(ls -t "$tdir"/*.jsonl 2>/dev/null | head -1)
  echo "${newest:-}"
}

count_turns() {
  local transcript="$1"
  [ -f "$transcript" ] || { echo 0; return; }
  grep -c '"assistant\.turn_start"' "$transcript" 2>/dev/null || echo 0
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════
if [ "$CMD" = "setup" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  benchmark/run.sh setup  ${CONDITION}-${RUN_N}"
  echo "════════════════════════════════════════════════════════"

  # 1. Create clean branch from base
  echo "[1/4] Creating branch ${BRANCH} from ${BASE_BRANCH}..."
  git checkout -b "$BRANCH" "$BASE_BRANCH"
  rm -rf reports/ target/

  # 2. Remove pre-existing domain test files (tracked + untracked)
  echo "[2/4] Cleaning domain test files..."
  git rm --ignore-unmatch "${DOMAIN_TEST_DIR}"/*Test.java 2>/dev/null || true
  rm -f "${DOMAIN_TEST_DIR}"/*Test.java
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "benchmark: ${CONDITION}-${RUN_N} — clean slate"
  else
    echo "  (nothing to commit — already clean)"
  fi

  # Verify
  COUNT=$(find "$DOMAIN_TEST_DIR" -maxdepth 1 -name "*Test.java" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$COUNT" -ne 0 ]; then
    echo "ERROR: ${COUNT} domain test files remain after cleanup — aborting" >&2
    exit 1
  fi
  echo "  ✓ domain test dir clean (0 top-level *Test.java)"

  # 3. Capture session context for billing
  echo "[3/4] Capturing session context..."
  TRANSCRIPT=$(find_transcript)
  if [ -n "${TRANSCRIPT:-}" ]; then
    SESSION_ID=$(basename "$TRANSCRIPT" .jsonl)
    TURNS_BEFORE=$(count_turns "$TRANSCRIPT")
    echo "  transcript: $SESSION_ID  turns_before: ${TURNS_BEFORE}"
  else
    SESSION_ID=""
    TURNS_BEFORE=0
    echo "  WARN: no transcript found — billing will show 0"
  fi

  # 4. Write initial log entry
  echo "[4/4] Starting run log: ${LOG_FILE}"
  mkdir -p "$(dirname "$LOG_FILE")"
  # Fresh log for this run
  {
    echo "RUN_ID=${CONDITION}-${RUN_N}  START=$(ts)  CONDITION=${CONDITION}  MODEL=claude-sonnet-4.6"
    [ -n "${SESSION_ID:-}" ] && echo "SESSION_ID=${SESSION_ID}  TURNS_BEFORE=${TURNS_BEFORE}"
  } > "$LOG_FILE"

  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  READY — generate tests now"
  echo "════════════════════════════════════════════════════════"
  if [ "$CONDITION" = "ai-only" ]; then
    echo ""
    echo "  Write unit tests for all top-level classes in:"
    echo "  com.parasoft.parabank.domain (not sub-packages)"
    echo "  to src/test/java/com/parasoft/parabank/domain/"
    echo ""
    echo "  Track ai_self_correct_count (number of times you run"
    echo "  mvn test autonomously). If blocked, add blocked=true"
    echo "  to ${LOG_FILE} and continue to teardown."
  else
    echo ""
    echo "  Invoke the jtest-unit-testing skill with:"
    echo "  export JTEST_SKILLS_CONFIG=\"\$(pwd)/benchmark/jtest-skills.config\""
    echo "  Prompt: Create unit tests for the top-level classes in the"
    echo "          com.parasoft.parabank.domain package (not sub-packages)"
  fi
  echo ""
  echo "  When done: ./benchmark/run.sh teardown ${CONDITION} ${RUN_N}"
  echo ""
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEARDOWN
# ══════════════════════════════════════════════════════════════════════════════
if [ "$CMD" = "teardown" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  benchmark/run.sh teardown  ${CONDITION}-${RUN_N}"
  echo "════════════════════════════════════════════════════════"

  [ ! -f "$LOG_FILE" ] && echo "ERROR: ${LOG_FILE} not found — run setup first" >&2 && exit 1

  # 1. Stop timer + capture turn count BEFORE any teardown tool calls
  END_TS=$(ts)
  TRANSCRIPT=$(find_transcript)
  if [ -n "${TRANSCRIPT:-}" ]; then
    SESSION_ID_LOG=$(grep -oP '\bSESSION_ID=\K\S+' "$LOG_FILE" | tail -1 || echo "")
    TRANSCRIPT_LOG="${TRANSCRIPT%/*}/${SESSION_ID_LOG}.jsonl"
    if [ -n "${SESSION_ID_LOG:-}" ] && [ -f "$TRANSCRIPT_LOG" ]; then
      TURNS_AFTER=$(count_turns "$TRANSCRIPT_LOG")
    else
      TURNS_AFTER=$(count_turns "$TRANSCRIPT")
    fi
    TURNS_BEFORE=$(grep -oP '\bTURNS_BEFORE=\K[0-9]+' "$LOG_FILE" | tail -1 || echo 0)
    MODEL_CALLS=$(( TURNS_AFTER - TURNS_BEFORE ))
    PREMIUM_REQUESTS=$(( MODEL_CALLS * COPILOT_MULTIPLIER ))
    log "END=${END_TS}  TURNS_AFTER=${TURNS_AFTER}  MODEL_CALLS=${MODEL_CALLS}  PREMIUM_REQUESTS=${PREMIUM_REQUESTS}"
  else
    log "END=${END_TS}"
  fi

  # 2. Sub-package cleanup (both conditions)
  echo "[1/5] Sub-package cleanup..."
  SUB_PKG_COUNT=0
  while IFS= read -r f; do
    rm -f "$f"
    SUB_PKG_COUNT=$(( SUB_PKG_COUNT + 1 ))
    echo "  removed: $f"
  done < <(find "$DOMAIN_TEST_DIR" -mindepth 2 -name "*Test.java" 2>/dev/null || true)
  echo "  ✓ sub-package files removed: ${SUB_PKG_COUNT}"

  # 3. Failing-test cleanup (Condition A only — Condition B's UTA step 5 handles this)
  TESTS_REMOVED=0
  if [ "$CONDITION" = "ai-only" ]; then
    echo "[2/5] Failing-test cleanup (Condition A)..."
    DOMAIN_FILES=$(find "$DOMAIN_TEST_DIR" -maxdepth 1 -name "*Test.java" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DOMAIN_FILES" -gt 0 ]; then
      DOMAIN_TESTS=$(find "$DOMAIN_TEST_DIR" -maxdepth 1 -name "*Test.java" \
        | xargs -I{} basename {} .java | paste -s -d',' -)
      mvn test -Dtest="$DOMAIN_TESTS" -q 2>/dev/null || true
      for report in target/surefire-reports/TEST-com.parasoft.parabank.domain.*.xml; do
        [ -f "$report" ] || continue
        f=$(grep -o 'failures="[0-9]*"' "$report" | grep -o '[0-9]*' | head -1)
        e=$(grep -o 'errors="[0-9]*"' "$report" | grep -o '[0-9]*' | head -1)
        if [ "${f:-0}" -gt 0 ] || [ "${e:-0}" -gt 0 ]; then
          cls=$(basename "$report" .xml | sed 's/^TEST-//')
          tf="src/test/java/$(echo "$cls" | tr '.' '/').java"
          [ -f "$tf" ] && rm -f "$tf" && TESTS_REMOVED=$(( TESTS_REMOVED + 1 ))
          echo "  removed failing: $(basename "$tf")"
        fi
      done
    else
      echo "  (no domain tests generated — skipping)"
    fi
    echo "  ✓ tests_removed: ${TESTS_REMOVED}"
  else
    echo "[2/5] Skipping failing-test cleanup (Condition B — UTA handles this)"
  fi
  log "TESTS_REMOVED=${TESTS_REMOVED}"

  # 4. Commit generated tests
  echo "[3/5] Committing generated tests..."
  git add "${DOMAIN_TEST_DIR}/"
  if git diff --cached --quiet; then
    echo "  WARN: no new test files to commit"
    log "TESTS_COMMITTED=0"
  else
    git commit -m "benchmark: ${CONDITION}-${RUN_N} — generated domain tests"
    echo "  ✓ committed"
  fi

  # 5. Collect metrics
  echo "[4/5] Collecting metrics..."
  chmod +x benchmark/data/collect-metrics.sh
  ./benchmark/data/collect-metrics.sh "$RUN_N" "$CONDITION"

  # 6. Full regression check
  echo "[5/5] Regression check (full suite)..."
  mvn test -q 2>/dev/null || true
  REGRESSION=$(grep -r 'failures="[1-9]"\|errors="[1-9]"' \
    target/surefire-reports/TEST-*.xml 2>/dev/null | wc -l | tr -d ' ')
  if [ "$REGRESSION" -gt 0 ]; then
    echo "  !! WARN: ${REGRESSION} regression failure(s) detected"
    log "REGRESSION_WARN=true"
  else
    echo "  ✓ no regressions"
  fi

  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  DONE: ${CONDITION}-${RUN_N}"
  echo "  Results: benchmark/data/run-${CONDITION}-${RUN_N}.json"
  echo "════════════════════════════════════════════════════════"
  echo ""
fi
