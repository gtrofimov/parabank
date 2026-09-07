---
name: soatest-orchestration
description: 'Create or modify SOAtest scenarios, execute SOAtest assets through SOAVirt, collect reports, fail builds on test failures, or publish results to DTP.'
argument-hint: 'Preset: local, ci, or publish; optionally provide SOAtest resource paths'
---

# SOAtest Orchestration Skill

Use this skill to route work between SOAtest MCP tools and local SOAtest execution CLI.

## When To Use

Use this skill when user asks to:
- Create or modify SOAtest scenarios/tests.
- Run SOAtest assets and collect reports.
- Fail build on test failures.
- Publish results to DTP.

## Routing Rules

1. Use SOAtest MCP tools for authoring and inspection.
- Create scenario.
- Add/modify/remove tests.
- Describe scenario/test.

2. Use local CLI runner for execution.
- Start test execution.
- Poll until completion.
- Download reports.
- Return CI-friendly exit code.

3. Mixed workflow order.
- First MCP authoring changes.
- Then CLI execution.
- Then summarize results and artifacts.

## Execution Entry Point

Run [the SOAtest runner](./scripts/run-soatest.sh) with one of these presets:
- `local`: local run, no fail gate, no publish.
- `ci`: fail gate enabled (`-fail`).
- `publish`: publish enabled (`-publish`).

## Application Coverage

For functional/API coverage, keep this strict order. The monitor JVM argument must
be present before Tomcat starts; copying monitor after startup produces no coverage.

```bash
source .agents/skills/workflow-config/scripts/load-orchestration-config.sh
source .agents/skills/workflow-config/scripts/resolve-build-id.sh
eval "$(.agents/skills/soatest-orchestration/scripts/prepare-jtest-monitor.sh)"
mvn cargo:run -DskipTests -Dcargo.servlet.port="$CARGO_SERVLET_PORT" \
	-Dcargo.jvmargs="$JTEST_MONITOR_JVM_ARGS"
```

In a separate CI step after application startup, run health checks first:

```bash
SOATEST_REPORT="$SOATEST_REPORT_ROOT/health" \
	.agents/skills/soatest-orchestration/scripts/run-soatest.sh ci \
	--resource /TestAssets/generated_by_mcp/<health-scenario>.tst
```

Then run feature API scenarios and calculate coverage:

```bash
.agents/skills/soatest-orchestration/scripts/run-soatest-coverage.sh publish \
	--resource /TestAssets/generated_by_mcp/<scenario>.tst
```

Preparation builds `jtest:monitor`, clears old runtime data, and deploys monitor.
Coverage runner executes SOAtest, then runs `Calculate Application Coverage`. It passes shared build ID
and DTP connection values with Jtest `-property` flags; `publish` requires
`DTP_URL`, `DTP_USER`, and `DTP_PASSWORD` from `.env` or CI secrets.

For CI, use one managed entrypoint instead of manually coordinating Cargo:

```bash
.agents/skills/soatest-orchestration/scripts/run-functional-pipeline.sh publish \
	--health /TestAssets/generated_by_mcp/<health-scenario>.tst \
	--resource /TestAssets/generated_by_mcp/<api-scenario>.tst
```

It resolves one build ID, starts monitor-instrumented Cargo, gates API scenarios
behind the health result, calculates application coverage, then stops Cargo.

## Determinism Rules

- Do not edit `.tst` files directly.
- Always pass explicit `-report` target.
- Preserve user-provided resources order.
- Use repeated `-resource` flags for each scope item.
- Keep config and environment explicit when provided.

## Naming Guidance

Use consistent, readable scenario names.

- Preferred style: lowercase with underscores.
- Suggested token order: `team_or_area__type__target__behavior__vNN`.
- Examples:
	- `orch__smoke__soavirt_status__get_200__v01`
	- `pda__api__categories__crud_happy_path__v02`

This is guidance only, not a hard gate.

## Failure Handling

1. Server/status failure:
- Verify SOAVirt server is running.
- Re-run with `-debug` for diagnostics.

2. Auth failure:
- Recheck `-auth USER:PASS` value and server URL.

3. Report extraction failure:
- Verify report path permissions and free disk space.

4. Build gate failure:
- `-fail` returns non-zero when failures > 0.
- Surface failure/total summary in response.
