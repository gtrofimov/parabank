---
name: workflow-config
description: 'Load shared orchestration defaults and resolve one DTP build ID for any project workflow skill.'
---

# Workflow Configuration

Use this shared utility before any Jtest, SOAtest, Docker, DTP, or other project
workflow that needs environment configuration or a build identity.

## Configuration Ownership

- `config/orchestration.config`: tracked non-secret runtime defaults.
- `config/.env`: ignored local credentials and CI secrets.
- CI secret store: credentials and `BUILD_NUMBER`.
- `JTEST_BUILD_ID`: derived by `resolve-build-id.sh`, unless explicitly set.
- `config/jtest-skills.config`: Jtest policy and baseline artifact paths only; not a source of runtime defaults.
- `$JTEST_HOME/jtestcli.properties`: Jtest installation settings such as licensing.
    Project-specific report, DTP, and coverage settings must be passed on the
    command line.
- `.agents/templates`: canonical repo-owned prompt and test-plan templates.
- `.agents/skills`: canonical repo-owned workflow skills.

## Mandatory Usage Rule

Any workflow skill that needs runtime config or a build ID must load the shared utility instead of re-implementing path resolution:

```bash
source .agents/skills/workflow-config/scripts/load-orchestration-config.sh
source .agents/skills/workflow-config/scripts/resolve-build-id.sh
```

Do not duplicate config-path logic in skill docs or scripts.

Published Jtest runs must use `scripts/publish-jtest.sh`. Do not call
`jtestcli -publish` directly from another skill or legacy script.

## Safe Fallback Policy

Use safe fallback defaults only for local-safe values with a standard repo default:

- ports (`PARABANK_SERVLET_PORT`, `JTEST_AGENT_REST_PORT`)
- local service URLs (`SOATEST_SERVER`)
- canonical report roots (`REPORT_ROOT`, `REPORT_JTEST_ROOT`,
  `REPORT_SOATEST_ROOT`, `REPORT_APP_COVERAGE_ROOT`)
- legacy report aliases remain supported
- repo-standard names (`DTP_PROJECT`)

Do not add fallback defaults for secrets or credentials. Leave those empty in `.env` and require environment injection in CI.

## Load Configuration

```bash
eval "$(.agents/skills/workflow-config/scripts/load-orchestration-config.sh)"
```

## Resolve Build ID

```bash
eval "$(.agents/skills/workflow-config/scripts/resolve-build-id.sh)"
```

Precedence: explicit `JTEST_BUILD_ID`, CI `BUILD_NUMBER`, or local UTC date.