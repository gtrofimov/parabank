# Copilot MCP Tool Usage Policy

When using MCP tools in this repository, call them sequentially.

## Jtest Parsing Rule
- ALWAYS use Jtest MCP tools to parse Jtest reports and Jtest coverage XML.
- Do not parse Jtest report files or coverage XML with shell tools or custom scripts when a Jtest MCP tool can provide the data.
- If required Jtest MCP tooling is unavailable, report the blocker and ask for MCP availability instead of falling back to non-MCP parsing.

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

## Skills Agent Pre-Heat Policy (Jtest Agent)
- For any task executed with `Jtest Agent`, run a pre-heat routine once per session before the primary workflow (`jtest-build`, `jtest-run-sa`, `jtest-run-ut`, `jtest-cov-analysis`, or `jtest-create-ut`).
- Keep all MCP calls in this pre-heat routine strictly sequential.

### Required Pre-Heat Sequence
1. Jtest MCP warm-up:
	- Run a small Jtest MCP action first to validate MCP availability and avoid first-call cold start.
	- Keep scope minimal.
2. DTP MCP warm-up:
	- Activate DTP MCP tools.
	- Run one lightweight connectivity/info call.
	- Run one lightweight build/metadata call.
3. Continue to requested workflow only after pre-heat succeeds or is explicitly reported as degraded.

### Failure Handling
- If Jtest MCP pre-heat fails, report the blocker and continue with non-MCP build/run steps only where allowed by the active skill.
- If DTP MCP pre-heat fails, continue Jtest workflow and report DTP as degraded.
- Do not retry more than once during pre-heat.
