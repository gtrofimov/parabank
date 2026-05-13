# Copilot MCP Tool Usage Policy

When using MCP tools in this repository, call them sequentially.

## Jtest Parsing Rule
- Shell tools and custom scripts are allowed to parse Jtest report files and coverage XML when they are faster or better suited for the workflow.
- If required Jtest MCP tooling is unavailable, continue with non-MCP parsing and report which parser path was used.

## Baseline Artifact Snapshot Rule
- Complete run definition: `jtest-build` in `both` mode plus `jtest-run-ut` for all tests.
- For complete runs, maintain a `target/jtest/baseline` snapshot for reuse by later workflows.
- In `jtest-build` complete runs (`both`), copy `target/jtest/jtest.data.json` to `target/jtest/baseline/jtest.data.json`.
- In `jtest-run-ut` complete runs (all tests), copy `report/report.xml` to `target/jtest/baseline/report.xml` and `report/coverage.xml` to `target/jtest/baseline/coverage.xml` when those files are produced.
- Create `target/jtest/baseline` if missing.

## Required behavior
- Run MCP tool calls one at a time.
- Wait for each MCP tool call to fully complete before starting the next one.
- Use the result of the previous MCP call to decide the next action.

## Prohibited behavior
- Do not run MCP tool calls in parallel.
- Do not batch MCP tool calls in a single parallel invocation.
- Do not use `multi_tool_use.parallel` for MCP tools.

If multiple MCP actions are needed, execute them in strict sequence: call, wait, evaluate, then call the next.

