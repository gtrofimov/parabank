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
- Fallback: `report/coverage.xml`.
- Legacy fallback: `target/jtest/coverage.xml`.

## Missing/Stale Coverage Behavior

If all supported coverage sources are missing or stale for requested scope:
1. run `jtest-run-ut` first to refresh test and coverage artifacts
2. continue coverage analysis after UT completes

## Procedure

1. Ensure current working directory is repository root.
2. Pre-heat MCP once per session before coverage analysis.
   - Jtest MCP warm-up: run one minimal Jtest MCP action.
   - DTP MCP warm-up: run one DTP info call, then one DTP build/metadata call.
   - Keep calls sequential.
3. Resolve coverage XML path in this order: baseline, fallback, legacy fallback.
   - If none exists or all are stale, execute `jtest-run-ut` automatically and use the refreshed artifact.
4. Query coverage using `mcp_jtest_query_line_coverage` only (sequential calls, never parallel), against the selected coverage XML path.
5. For each source file in scope, run:
   - `query_type: "coverable"`
   - `query_type: "notcovered"`
6. Compute covered lines as `coverable - notcovered`.
7. Map uncovered lines to methods by reading source files.

## Reporting

Provide:
- total coverable, covered, and not covered lines
- percent coverage
- per-file coverage table
- uncovered lines grouped by method where possible

## Completion Checks
- coverage source file was present or regenerated via UT.
- coverage data was obtained via `mcp_jtest_query_line_coverage`.
- output includes summary and per-file uncovered details.

## Decision Rules
- If user asks for coverage without asking to run tests and coverage is already current, analyze only.
- If user asks for coverage and coverage is missing/stale, run UT automatically then analyze.
- If scope is ambiguous, ask one clarifier: class, package, path, or all.
