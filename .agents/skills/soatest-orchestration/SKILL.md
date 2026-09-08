---
name: soatest-orchestration
description: 'Create or modify SOAtest scenarios, execute SOAtest assets through SOAVirt, collect reports, fail builds on test failures, or publish results to DTP.'
argument-hint: 'Preset: local, ci, or publish; optionally provide SOAtest resource paths'
---

## Purpose

Route SOAtest authoring to MCP and SOAtest execution to the repository scripts.
Keep this skill orchestration-only. Application monitoring and coverage belong to
their dedicated scripts, not this routing contract.

## Routing

- Author, inspect, or resolve scenarios/resources: use SOAtest MCP tools.
- Execute scenarios: use `scripts/soatestcli.sh`.
- Prepare monitor deployment: use `scripts/prepare-jtest-monitor.sh`.
- Run monitored application coverage after the app is running: use `scripts/run-soatest-coverage.sh`.
- Run monitored Docker application coverage after Docker deployment: use
  `scripts/run-soatest-docker-coverage.sh`.
- Do not edit `.tst` assets directly.

## Execution

`soatestcli.sh` supports server, auth, config, resource, environment, report,
fail, and publish options. Always pass an explicit report location and preserve
resource order.

SOAtest resource paths are server workspace paths, not repository files. Resolve
or verify paths such as `/TestAssets/example.tst` with SOAtest MCP first, then
pass the resolved path directly to SOAtest. Do not search the local filesystem
for these resources unless the task is explicitly about local asset staging or
authoring.

```bash
.agents/skills/soatest-orchestration/scripts/soatestcli.sh \
  -server "$SOATEST_SERVER" \
  -config "$SOATEST_CONFIG" \
  -fail \
  -report "$REPORT_SOATEST_ROOT/<run>" \
  -resource /TestAssets/<scenario>.tst
```

Use `-publish` only when DTP publication is requested. Credentials come from
`config/.env` or CI secrets.

## Monitored API Coverage

Keep monitor deployment, application lifecycle, SOAtest execution, and
application coverage as explicit orchestration steps. Do not hide them behind a
single pipeline wrapper.

When API validation requires application coverage:

1. For Docker-based Parabank validation, run `deploy-parabank-docker.sh`. Do not
   inspect Docker volumes, Cargo plugin configuration, or README deployment
   instructions unless that command fails.
2. Run any health scenario first with `run-soatest.sh` and an explicit report
   location.
3. Run API scenarios with `run-soatest-docker-coverage.sh` so Jtest calculates
   application coverage from monitor runtime data copied out of the container.

For non-Docker application servers, run `prepare-jtest-monitor.sh` before
starting the monitored application, then run `run-soatest-coverage.sh` after the
application is healthy. Missing or incomplete `target/jtest/monitor/monitor.zip`
is a hard failure.

Preserve the order of resources supplied by the caller and reuse the shared
build ID resolved by `workflow-config`.
