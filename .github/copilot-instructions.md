# Copilot MCP Tool Usage Policy

When using MCP tools in this repository, call them sequentially.

## Jtest Parsing Rule
- Prefer shell tools and custom scripts to parse Jtest report files and coverage XML when they are faster or better suited for the workflow.
- Use Jtest MCP tooling when shell parsing fails, output is malformed, or MCP-only data is required (for example, rule documentation or line-level coverage).
- Report which parser path was used (shell/custom or MCP).

## Baseline Artifact Snapshot Rule
- Complete run definition: `jtest-build` in `both` mode plus `jtest-run-ut` for all tests.
- For complete runs, maintain a `target/jtest/baseline` snapshot for reuse by later workflows.
- In `jtest-build` complete runs (`both`) on the configured baseline branch only, copy `target/jtest/jtest.data.json` to `target/jtest/baseline/jtest.data.json`.
- In `jtest-run-ut` complete runs (all tests) on the configured baseline branch only, copy `report/report.xml` to `target/jtest/baseline/report.xml` and `report/coverage.xml` to `target/jtest/baseline/coverage.xml` when those files are produced.
- Create `target/jtest/baseline` if missing.

## Coverage Artifact Resolution
- Resolve coverage XML in this order:
	1) `target/jtest/baseline/coverage.xml`
	2) `report/coverage.xml`
	3) `target/jtest/coverage.xml` (legacy fallback for backward compatibility)

## Mode Selection Matrix
- Jtest mode selection belongs to the matching vendor-provided Jtest skill.
- `workflow-delivery` owns cross-phase order; it does not duplicate Jtest
	procedures.

## Required behavior
- Run MCP tool calls one at a time.
- Wait for each MCP tool call to fully complete before starting the next one.
- Use the result of the previous MCP call to decide the next action.
- Do not batch or parallelize MCP calls, including `multi_tool_use.parallel`.

## Skill Loading
- Load a skill only after its trigger matches the request or workflow phase.
- Do not preload unrelated vendor skill bodies, examples, or reference files.
- Vendor-provided Jtest, virtualization, and SOAVirt upload skills remain
	authoritative and should not be copied, merged, or rewritten by orchestration
	guidance.

If multiple MCP actions are needed, execute them in strict sequence: call, wait, evaluate, then call the next.

