# Copilot MCP Tool Usage Policy

When using MCP tools in this repository, call them sequentially.

## Skill and template location
- Store repository-owned custom agent skills in `.agents/skills/<skill-name>/SKILL.md`.
- Store reusable repository templates in `.agents/templates/<template-name>.*`.
- Use the `.agents` tree for repo-owned workflow, prompt, and config bootstrap assets only.
- Do not add new skills under `.github/skills`.
- Do not create local-only copies of repo templates or workflow files outside the repo-controlled `.agents` tree.

## Config resolution contract
- Every workflow skill that needs runtime settings must source the shared loader from `.agents/skills/workflow-config/scripts/load-orchestration-config.sh`.
- Every workflow skill that needs a DTP build identity must source `.agents/skills/workflow-config/scripts/resolve-build-id.sh`.
- Do not duplicate config-path logic across skills. Use the shared scripts as the single source of truth.
- Repo-owned runtime defaults live in `orchestration.config`.
- Repo-owned prompt templates live in `.agents/templates/`.
- Local secrets stay in `.env` or CI secret storage, not in tracked repo files.

## Jtest Parsing Rule
- Prefer shell tools and custom scripts to parse Jtest report files and coverage XML when they are faster or better suited for the workflow.
- Use Jtest MCP tooling when shell parsing fails, output is malformed, or MCP-only data is required (for example, rule documentation or line-level coverage).
- Report which parser path was used (shell/custom or MCP).

## Baseline Artifact Snapshot Rule
- Complete run definition: `jtest-build` in `both` mode plus `jtest-run-ut` for all tests.
- For complete runs, maintain a `target/jtest/baseline` snapshot for reuse by later workflows.
- In `jtest-build` complete runs (`both`), copy `target/jtest/jtest.data.json` to `target/jtest/baseline/jtest.data.json`.
- In `jtest-run-ut` complete runs (all tests), copy `report/report.xml` to `target/jtest/baseline/report.xml` and `report/coverage.xml` to `target/jtest/baseline/coverage.xml` when those files are produced.
- Create `target/jtest/baseline` if missing.

## Coverage Artifact Resolution
- Resolve coverage XML in this order:
	1) `target/jtest/baseline/coverage.xml`
	2) `report/coverage.xml`
	3) `target/jtest/coverage.xml` (legacy fallback for backward compatibility)

## Mode Selection Matrix
- SA only: use `jtest-build` mode `sa`.
- UT only: use `jtest-build` mode `ut`.
- Coverage only: analyze existing coverage first; if stale or missing, run `jtest-run-ut` (all tests) to refresh artifacts.
- Test creation only: use `jtest-build` mode `sa` before `jtest-create-ut`.
- SA + UT in one request: use `jtest-build` mode `both`.

## Configuration ownership and fallback policy
- `orchestration.config` is the repo-owned source of non-secret runtime defaults.
- `.env` and `.env.example` are reserved for local/CI secrets and credentials only. Never put runtime defaults there.
- `jtest-skills.config` is for Jtest-specific baseline and policy settings only. Do not add runtime default values here.
- `.agents/skills/workflow-config` owns the load/resolve logic for shared workflow configuration.
- Safe fallback defaults are allowed only for local-safe values such as ports, hostnames, report roots, and repo-standard names. Secrets must remain unset and must be injected from the environment.
- Precedence is: explicit environment values > repo defaults > safe local fallback values.

## Required behavior
- Run MCP tool calls one at a time.
- Wait for each MCP tool call to fully complete before starting the next one.
- Use the result of the previous MCP call to decide the next action.
- Do not batch or parallelize MCP calls, including `multi_tool_use.parallel`.

If multiple MCP actions are needed, execute them in strict sequence: call, wait, evaluate, then call the next.

