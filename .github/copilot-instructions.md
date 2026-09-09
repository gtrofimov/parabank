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
- Repo-owned runtime defaults live in `config/orchestration.config`.
- Repo-owned Jtest baseline/policy config lives in `config/jtest-skills.config`.
- Jtest installation settings and licensing live in `$JTEST_HOME/jtestcli.properties`.
- Project-specific Jtest report, DTP, and coverage settings are passed on the command line.
- Repo-owned prompt templates live in `.agents/templates/`.
- Local secrets stay in `config/.env` or CI secret storage, not in tracked repo files.
- Legacy root-level config files remain readable only as compatibility fallback during transition.

## Jtest Parsing Rule
- Prefer shell tools and custom scripts to parse Jtest report files and coverage XML when they are faster or better suited for the workflow.
- Use Jtest MCP tooling when shell parsing fails, output is malformed, or MCP-only data is required (for example, rule documentation or line-level coverage).
- Report which parser path was used (shell/custom or MCP).

## Baseline Artifact Snapshot Rule
- Complete run definition: `jtest-build` in `both` mode plus `jtest-run-ut` for all tests.
- For complete runs, maintain a `target/jtest/baseline` snapshot for reuse by later workflows.
- In `jtest-build` complete runs (`both`) on the configured baseline branch only, copy `target/jtest/jtest.data.json` to `target/jtest/baseline/jtest.data.json`.
- In `jtest-run-ut` complete runs (all tests) on the configured baseline branch only, copy `reports/jtest/ut-final/report.xml` to `target/jtest/baseline/report.xml` and `reports/jtest/ut-final/coverage.xml` to `target/jtest/baseline/coverage.xml` when those files are produced.
- Create `target/jtest/baseline` if missing.

## Coverage Artifact Resolution
- Resolve coverage XML in this order:
	1) `target/jtest/baseline/coverage.xml`
	2) `reports/jtest/ut-final/coverage.xml`

## Mode Selection Matrix
- Jtest mode selection belongs to the matching vendor-provided Jtest skill.
- `workflow-delivery` owns cross-phase order; it does not duplicate Jtest
	procedures.

## Configuration ownership and fallback policy
- `orchestration.config` is the repo-owned source of non-secret runtime defaults.
- `.env` and `.env.example` are reserved for local/CI secrets and credentials only. Never put runtime defaults there.
- `jtest-skills.config` is for Jtest-specific baseline and policy settings only. Do not add runtime default values here.
- Do not require a repo-local Jtest settings file. Use `$JTEST_HOME/jtestcli.properties` for installation/licensing and pass project-specific Jtest values explicitly on the command line.
- `.agents/skills/workflow-config` owns the load/resolve logic for shared workflow configuration.
- Safe fallback defaults are allowed only for local-safe values such as ports, hostnames, report roots, and repo-standard names. Secrets must remain unset and must be injected from the environment.
- Precedence is: explicit environment values > repo defaults > safe local fallback values.

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

