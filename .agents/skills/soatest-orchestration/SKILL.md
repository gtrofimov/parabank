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

- Author or inspect scenarios: use SOAtest MCP tools.
- Execute scenarios: use `scripts/soatestcli.sh`.
- Run monitored application coverage: use `scripts/run-soatest-coverage.sh`.
- Run managed health/API pipeline: use `scripts/run-functional-pipeline.sh`.
- Do not edit `.tst` assets directly.

## Execution

`soatestcli.sh` supports server, auth, config, resource, environment, report,
fail, and publish options. Always pass an explicit report location and preserve
resource order.

```bash
.agents/skills/soatest-orchestration/scripts/soatestcli.sh \
  -server "$SOATEST_SERVER" \
  -config "$SOATEST_CONFIG" \
  -fail \
  -report "$SOATEST_REPORT_ROOT/<run>" \
  -resource /TestAssets/<scenario>.tst
```

Use `-publish` only when DTP publication is requested. Credentials come from
`config/.env` or CI secrets.

## Managed Coverage

Use `run-functional-pipeline.sh` when health gating, Cargo lifecycle, monitor
deployment, SOAtest execution, and application coverage form one workflow. It
must receive explicit `--health` and one or more `--resource` arguments.

Use `prepare-jtest-monitor.sh` only before starting the monitored application.
Missing or incomplete `target/jtest/monitor/monitor.zip` is a hard failure.
