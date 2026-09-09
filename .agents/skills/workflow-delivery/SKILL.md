---
name: workflow-delivery
description: 'Commander workflow for feature delivery across define, implement, validate, and release.'
---

# Workflow Delivery

This is the repo-level commander workflow. It defines how feature work is executed across the delivery lifecycle, but it does not contain feature-specific requirements.

## Purpose

Use this skill to orchestrate the full delivery loop for a feature branch. Load
downstream skills only when their phase is reached; do not preload vendor skill
instructions or examples.

1. define the feature contract
2. generate or load the feature prompt
3. generate the matching test plan
4. plan and implement the work
5. verify quality gates
6. publish or hand off the result

## Ownership

- This file owns the generic delivery process.
- Feature-specific decisions live in a generated feature prompt under `.agents/templates/` or the branch-specific feature prompt.
- Testing expectations live in the associated test-plan template.
- Repository policy still lives in `.github/copilot-instructions.md`.

## Required Inputs

Before implementation begins, ensure the following exist:

- a feature prompt describing the user-visible goal, scope, constraints, and acceptance criteria
- a matching test plan covering unit, SA, API/functional, and coverage expectations
- the target branch and baseline state
- repo configuration and CI environment defaults

## Standard Lifecycle

### Phase 1: Define

- when the requirement originates from Jira (e.g. a PGT issue), load
  `jira-feature-intake` first to get the baseline state, feature branch, build
  ID, and generated feature-prompt/test-plan instances
- otherwise capture feature intent directly in a feature prompt
- state scope, non-goals, API/data impact, risks, and success criteria
- generate a test-plan from the feature template
- confirm delivery gates and evidence expectations

Exit when the feature contract and validation plan are explicit.

### Phase 2: Plan

- convert the feature contract into ordered implementation tasks
- assign artifacts to each task
- define the validation command for each task
- stop before implementation for human approval if the scope is unclear

Exit when the task list is approved.

### Phase 3: Implement

- make the smallest change that satisfies the feature contract
- keep work scoped to the requested feature
- do not mix unrelated fixes or cleanup unless required by the feature
- update tests and docs with the feature change
- when adding a method to an interface, check every concrete implementer
  first (including test doubles under `src/test/java`) — an interface change
  that only updates the production implementation will break compilation of
  mock/in-memory implementers used by unrelated tests
- use scoped/targeted test runs only during implementation (compile,
  test-compile, `-Dtest=<ChangedClasses>`); do not run the full unit-test
  suite or the full SOAtest scenario set mid-implementation — defer both to
  the single final regression gate in Phase 4

Exit when the implementation is complete and the task artifacts are ready for validation.

### Phase 4: Validate

Run the required evidence chain in this order, delegating each operation to its
matching skill:

1. `jtest-run-sa` for static analysis
2. `jtest-run-ut` for focused unit tests
3. `soatest-orchestration` for feature/API validation
4. `jtest-cov-analysis` for application coverage analysis
5. final branch-level verification against baseline

Load `jtest-build` first when a Jtest data artifact is missing or stale. Load
`jtest-create-ut` only when test generation is explicitly requested. Load
`virtualize-stateful-virtual-service-creator` only for stateful service work,
and load `soavirt-upload` only for SOAVirt file staging.

Before exiting this phase, run full regression once, even if scoped/targeted
runs already passed during implementation — a scoped run does not prove the
rest of the suite still passes after all commits in the branch:
- `jtest-run-ut` with no scope filter (unit tests)
- all existing SOAtest scenarios for the affected app, run individually per
  scenario rather than batched into one `soatestcli` call — batching
  unrelated scenarios together can surface cross-scenario extraction-variable
  interaction failures that are not real regressions. Verify any failure with
  an isolated single-scenario rerun before treating it as a regression caused
  by this branch.

Exit when all required gates have evidence attached.

### Phase 5: Release / Hand-off

- ensure the feature branch is clean, scoped, and documented
- confirm required reports and thresholds are captured
- generate an accountability report from
  `.agents/templates/accountability-report-template.md`, linking the Jira
  issue, branch, build ID, and every evidence artifact from Phase 4
- prepare the final summary for review or deployment
- on approval, create the PR (vendor PR-creation skill) and post the
  accountability report summary plus PR link back to the Jira issue
- do not push, publish, create a PR, or transition the Jira issue without
  approval

## Hard Rules

- Do not invent feature behavior in the workflow file.
- Do not duplicate feature-specific requirements in the workflow file.
- Keep the workflow generic enough to apply to every feature.
- Use repository-owned templates and config instead of local ad hoc files.
- Require evidence before claiming the feature is complete.
- Publish Jtest reports on first execution; never rerun tests only to publish.
- Never push, create a PR, or transition/comment on a Jira issue without approval.

## Skill Loading

- This file owns lifecycle order, not vendor workflow procedures.
- Vendor skills own their commands, artifacts, MCP calls, and completion checks.
- Read a skill's full `SKILL.md` only after its trigger matches the current
	phase or user request.
- Do not copy vendor skill instructions into prompts, plans, or summaries.

## Repo Conventions

- custom skills: `.agents/skills/<skill-name>/SKILL.md`
- reusable prompt templates: `.agents/templates/`
- repo policy: `.github/copilot-instructions.md`
- local credentials: `config/.env` or CI secrets, never committed
- runtime defaults: `config/orchestration.config`
- Jtest policy: `config/jtest-skills.config`
- Jtest installation settings and licensing: `$JTEST_HOME/jtestcli.properties`
- project-specific Jtest settings: command-line properties
- shared config/build-ID utility: `.agents/skills/workflow-config/`
- Jira requirement intake: `.agents/skills/jira-feature-intake/`
- generated feature/test-plan instances: `.agents/instances/<ISSUE-KEY>/`
- accountability report template: `.agents/templates/accountability-report-template.md`

Skills that need runtime config or a build identity use the shared utility. Do
not invent alternative config paths.

## Output Contract

At the end of a delivery cycle, the feature branch should have:

- a feature prompt or generated feature instance (with Jira issue link, if any)
- an accountability report tying evidence to the build ID and Jira issue
- a test plan
- implementation changes
- validation evidence
- a concise completion summary with any unresolved risks
