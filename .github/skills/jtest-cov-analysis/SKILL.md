---
name: jtest-cov-analysis
description: 'Analyze coverage results only. If coverage data is missing or stale, run UT first and then analyze coverage.'
argument-hint: 'Scope: all files, package path, class path, or source file list'
---

# Jtest Coverage Analysis

Analyze coverage from Jtest output.

## When To Use
- User asks for coverage summary, uncovered lines, or coverage gaps.
- UT already ran and coverage data exists.

## Coverage Source
- Primary: `target/jtest/baseline/coverage.xml`.
- Fresh run output: `report/coverage.xml` — produced by every jtestcli run (scoped or full). Prefer this over the baseline when its modification time is more recent than `target/jtest/baseline/coverage.xml`.
- Fallback: `target/jtest/baseline/coverage.xml` when `report/coverage.xml` is absent or older than the baseline.

> **Note:** `target/jtest/coverage.xml` is **not** produced by standalone jtestcli in this project. Do not reference it as a coverage source.

## Missing/Stale Coverage Behavior

If all supported coverage sources are missing or stale for the requested scope:
1. Prefer a **scoped** UT re-run when the request targets a specific class or package — run only the relevant test class(es) via Maven `-Dtest=ClassName`, then run jtestcli with the source file in `-include` (e.g., `path:**/BillPayResult.java`) and use the freshly produced `report/coverage.xml`.
2. Only fall back to running **all tests** (`jtest-run-ut`) when the scope is the entire project or no scoped test class can be identified.
3. Continue coverage analysis after the UT run completes.

## Procedure

1. Ensure current working directory is repository root.
2. Resolve coverage XML path:
   - Check `report/coverage.xml` and `target/jtest/baseline/coverage.xml` modification times.
   - If a jtestcli run was just performed, `report/coverage.xml` will be the most recent — use it.
   - Otherwise use `target/jtest/baseline/coverage.xml` if it exists and is the freshest available.
   - If neither exists or both are stale, execute a **scoped** UT re-run (preferred) or a full `jtest-run-ut`.
   - Store the selected path in `COVERAGE_XML` and use that value for all parser commands.
   - **Do not reference `target/jtest/coverage.xml`** — it is not produced by jtestcli in this project.
3. **Test source validation (mandatory when reporting test contributors):** Extract test class names from the coverage XML and check that each has a corresponding source file in `src/test/java/`. Any referenced test class with no source file is a **ghost test** — its bytecode exists but its source was deleted. For each ghost found:
   - Exclude it from test-contributor attribution.
   - Report it explicitly with label **"stale/deleted — excluded"**.
   - Warn the user that coverage data is partially stale and recommend `mvn clean` followed by a full UT rebuild to produce clean artifacts.

```bash
# Extract test class paths from coverage XML and cross-check against sources
grep -oP '(?<=id=")[^|]+(?=\|)' "$COVERAGE_XML" | sort -u | while read cls; do
  path="src/test/java/$(echo "$cls" | tr '.' '/').java"
  [[ ! -f "$path" ]] && echo "GHOST: $cls ($path)"
done
```

4. Run the coverage parser script to generate structured CSV data for analysis.

```bash
bash .github/skills/jtest-cov-analysis/coverage-gap-analysis.sh --coverage-xml "$COVERAGE_XML" --top 0 --method-top 0 --output csv
```

   Scope examples:

```bash
bash .github/skills/jtest-cov-analysis/coverage-gap-analysis.sh --coverage-xml "$COVERAGE_XML" --include "src/main/java/com/parasoft/parabank/web/controller/" --top 0 --method-top 0 --output csv
bash .github/skills/jtest-cov-analysis/coverage-gap-analysis.sh --coverage-xml "$COVERAGE_XML" --output csv --top 0 > target/jtest/coverage-gaps.csv
```

4. Skill-side analysis and formatting (mandatory):
   - Parse the CSV output from the script.
   - Compute/report totals:
     - coverable elements
     - covered elements
     - uncovered elements
     - percent coverage
   - Render markdown tables in the final response:
     - ranked file-gap table
     - ranked method-gap table with method names
   - Add a prioritized top test-target list (top 5).
5. MCP fallback policy:
   - If precise line-level breakdown is requested, run:

```bash
mcp_jtest_query_line_coverage (sequential per file)
```

   - Use MCP sequentially for selected files and map uncovered lines to methods.
   - If the shell parser fails or output is malformed, fall back to MCP sequentially for the requested scope.

## Reporting

Provide:
- total coverable, covered, and not covered elements
- percent coverage
- per-file coverage table (ranked, markdown)
- method-level coverage table with method names (ranked, markdown)
- top gap candidates for new unit tests
- uncovered lines grouped by method where possible when line-level detail is requested

## Completion Checks
- coverage source file was present or regenerated via UT.
- coverage data was obtained via `coverage-gap-analysis.sh` output (or via MCP fallback when required).
- final response includes markdown file/method tables generated by the skill.

## Decision Rules
- If user asks for coverage without asking to run tests and coverage is already current, analyze only.
- If user asks for coverage and coverage is missing/stale for a **specific class or package**, re-run only the scoped test class(es) (Maven `-Dtest=`) and run jtestcli with the source file in `-include`; read coverage from the freshly produced `report/coverage.xml`.
- If user asks for coverage and coverage is missing/stale for the **whole project**, run `jtest-run-ut` for all tests then analyze from the refreshed `report/coverage.xml` (copy to baseline after).
- If user asks for UT and coverage together, run the appropriate scoped or full UT first, then analyze coverage from the resulting artifact.
- If scope is ambiguous, ask one clarifier: class, package, path, or all.
- Always prefer `coverage-gap-analysis.sh` for coverage ranking and top-gap identification.
- If user asks for precise uncovered line numbers, use MCP line coverage sequentially for the selected scope.
- If shell parser path fails, use MCP sequentially as fallback.
- **If coverage XML references test classes whose source files no longer exist in `src/test/java/`, treat that coverage XML as partially stale.** Report the ghost test names explicitly, exclude them from contributor attribution, and recommend running `mvn clean` followed by a full UT rebuild to produce clean artifacts.
