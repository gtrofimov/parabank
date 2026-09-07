---
name: workflow-delivery
description: 'Commander workflow for feature delivery across define, implement, validate, and release.'
---

# Workflow Delivery

This is the repo-level commander workflow. It defines how feature work is executed across the delivery lifecycle, but it does not contain feature-specific requirements.

## Purpose

Use this skill to orchestrate the full delivery loop for a feature branch:

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

- capture feature intent in a feature prompt
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

Exit when the implementation is complete and the task artifacts are ready for validation.

### Phase 4: Validate

Run the required evidence chain in this order:

1. static analysis
2. focused unit tests
3. feature/API validation
4. application coverage capture
5. final branch-level verification against baseline

Exit when all required gates have evidence attached.

### Phase 5: Release / Hand-off

- ensure the feature branch is clean, scoped, and documented
- confirm required reports and thresholds are captured
- prepare the final summary for review or deployment
- do not push or publish without approval

## Hard Rules

- Do not invent feature behavior in the workflow file.
- Do not duplicate feature-specific requirements in the workflow file.
- Keep the workflow generic enough to apply to every feature.
- Use repository-owned templates and config instead of local ad hoc files.
- Require evidence before claiming the feature is complete.
- Never push or create a PR without approval.

## Repo Conventions

- custom skills: `.agents/skills/<skill-name>/SKILL.md`
- reusable prompt templates: `.agents/templates/`
- repo policy: `.github/copilot-instructions.md`
- local credentials: `.env` or CI secrets, never committed
- runtime defaults: `orchestration.config`
- shared config loader: `.agents/skills/workflow-config/scripts/load-orchestration-config.sh`
- shared build-ID resolver: `.agents/skills/workflow-config/scripts/resolve-build-id.sh`

Any workflow or test skill that needs config or a build identity must source these shared scripts. Do not invent alternative config paths.

## Output Contract

At the end of a delivery cycle, the feature branch should have:

- a feature prompt or generated feature instance
- a test plan
- implementation changes
- validation evidence
- a concise completion summary with any unresolved risks
