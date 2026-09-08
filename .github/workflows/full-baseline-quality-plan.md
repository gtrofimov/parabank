# Full Baseline Quality Workflow Plan

## Goal

Add a GitHub Actions workflow with the same structural pattern as the
Virtualize MCP demo:

```text
workflow YAML -> shell runner -> Copilot prompt -> repository skills
```

The workflow should run a complete Parabank quality baseline:

1. Resolve one shared build identity.
2. Run full Jtest static analysis with the CWE profile.
3. Run all unit tests with Jtest coverage.
4. Analyze unit-test coverage.
5. Deploy or redeploy Parabank with the Jtest monitor enabled.
6. Run SOAtest health and API resources.
7. Calculate and optionally publish application coverage from monitor runtime data.

## Proposed Files

```text
.github/workflows/full-baseline-quality.yml
.github/workflows/full-baseline-quality.sh
.github/workflows/full-baseline-quality-prompt.md
.github/workflows/full-baseline-quality-verify-prompt.md
```

## Ownership Model

Keep GitHub Actions thin. The YAML should define inputs, secrets, variables,
checkout, the shell runner call, and artifact upload only.

Keep the shell runner deterministic. It should validate required environment
variables, expand prompt templates, invoke `copilot --allow-all --no-ask-user`,
and validate final machine-readable status lines.

Keep the prompt skill-driven. It should describe the required phase order and
delegate heavy lifting to existing skills rather than inlining long Jtest or
SOAtest commands.

## Skill Flow

```text
workflow-config
  -> jtest-build both
  -> jtest-run-sa CWE
  -> jtest-run-ut all tests + coverage
  -> jtest-cov-analysis
  -> soatest-orchestration explicit monitored API coverage steps
```

Use the default SA profile owned by `jtest-run-sa`:

```text
builtin://CWE Top 25 + On the Cusp 2025
```

## SOAtest And Monitor Flow

Do not use a single functional pipeline wrapper. Keep the monitored API coverage
phase explicit and owned by `soatest-orchestration`:

SOAtest resource inputs are server workspace resource paths, not repository
files. The workflow must pass them directly to SOAtest scripts and must not scan
the local filesystem for `/TestAssets/...` paths.

1. Ensure `target/jtest/monitor/monitor.zip` exists. If missing, build it with
   the repository-owned monitor build flow.
2. Run `prepare-jtest-monitor.sh` before starting Parabank.
3. Start or redeploy Parabank with the emitted `JTEST_MONITOR_JVM_ARGS`.
4. Wait for the configured Parabank health endpoint.
5. Run the SOAtest health resource first with `run-soatest.sh`.
6. Run requested API resources with `run-soatest-coverage.sh` so Jtest calculates
   application coverage from monitor runtime data.

Preserve SOAtest resource order from the workflow input and reuse the shared
build ID resolved by `workflow-config`.

## Required GitHub Secrets

```text
COPILOT_PAT
DTP_URL
DTP_USER
DTP_PASSWORD
```

## Recommended GitHub Variables

```text
DTP_PROJECT
SOATEST_SERVER
SOATEST_CONFIG
```

Optional variables for overriding repository defaults:

```text
DTP_UT_COVERAGE_IMAGES
DTP_SOATEST_COVERAGE_IMAGES
CARGO_SERVLET_PORT
JTEST_AGENT_REST_PORT
REPORT_ROOT
```

Jtest installation settings and licensing come from
`$JTEST_HOME/jtestcli.properties`. Do not require a repo-local Jtest settings
file; project-specific Jtest values are passed explicitly on the command line.

## Prompt Output Contract

The main prompt should require these plain-text final metadata lines so the
shell runner can fail CI deterministically:

```text
QUALITY_STATUS=passed|failed
BUILD_ID=<resolved build id>
SA_STATUS=passed|failed
SA_REPORT=<path or -->
UT_STATUS=passed|failed
UT_REPORT=<path or -->
COVERAGE_STATUS=passed|failed
COVERAGE_XML=<path or -->
SOATEST_STATUS=passed|failed
SOATEST_REPORT=<path or -->
APP_COVERAGE_STATUS=passed|failed
APP_COVERAGE_REPORT=<path or -->
PARSER_PATH=<shell/custom|MCP|mixed>
```

The verify prompt should inspect evidence without rerunning tests and end with:

```text
EVIDENCE_STATUS=valid|invalid
```

## Branch Policy

Baseline snapshot refreshes should run only from `master`, matching repository
policy. Feature branch validation should consume existing baseline artifacts and
must not overwrite `target/jtest/baseline/*`.