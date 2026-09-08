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
7. Do not calculate application coverage from monitor runtime data. Use the
   coverage XML produced by the full Jtest unit-test run as the single coverage
   source.

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
files. The workflow must resolve them through SOAtest MCP first, then pass the
resolved paths directly to SOAtest scripts. It must not scan the local
filesystem for `/TestAssets/...` paths.

1. Deploy or redeploy the monitored Docker application with
   `deploy-parabank-docker.sh`.
2. Run the SOAtest health resource first with `run-soatest.sh`.
3. Run requested API resources with `run-soatest.sh`. Do not invoke
   `run-soatest-coverage.sh` or calculate application coverage.

Preserve SOAtest resource order from the workflow input and reuse the shared
build ID resolved by `workflow-config`.

## Required GitHub Secrets

```text
COPILOT_PAT
DTP_URL
DTP_USER
DTP_PASSWORD
SOATEST_MCP_AUTH_TOKEN
```

`SOATEST_MCP_URL` is derived by the shell runner as
`${SOATEST_URL:-$SOATEST_SERVER}/soavirt/mcp`; it is not a separate secret.
`SOATEST_URL` is the SOAtest/SOAVirt MCP base URL and defaults to
`http://localhost:9080`.

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
APP_COVERAGE_REPORT=<same path as COVERAGE_XML>
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