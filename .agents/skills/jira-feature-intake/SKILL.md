---
name: jira-feature-intake
description: 'Read a requirement from the PGT Jira project and turn it into a branch-scoped feature prompt and test plan. Use for the observe/define phase of the delivery workflow before any implementation starts.'
argument-hint: 'Jira issue key (e.g. PGT-123), or search terms to find it'
---

# Jira Feature Intake

Bridges a PGT Jira issue to the repo's delivery workflow. Owns the "observe" and
"define" phases only; it does not implement the feature.

## When To Use

- A user asks to pull a requirement/story/task from Jira and start delivery on it.
- `workflow-delivery` Phase 1 (Define) needs a feature contract sourced from Jira
  instead of a manually written prompt.

## Ownership

- This skill owns: reading the Jira issue, baseline checks, feature branch
  creation, build ID linkage, and generating the feature prompt + test plan
  instances.
- It does not own implementation, validation, or release. Hand off to
  `workflow-delivery` Phase 2 once the instances exist.

## Procedure

### 1. Observe — baseline state

```bash
source .agents/skills/workflow-config/scripts/load-orchestration-config.sh
git fetch origin
git status --porcelain
```

- Working tree must be clean before branching. Stop and ask the user if it is not.
- Confirm `master` is up to date with `origin/master` (or note the divergence).
- Confirm `.jtest-baseline/` artifacts referenced by `config/jtest-skills.config`
  exist; if missing, note that baseline comparisons will be skipped.

### 2. Observe — review templates

Read the two canonical templates before drafting anything:

- `.agents/templates/feature-template.prompt.md`
- `.agents/templates/test-plan-template.md`

### 3. Observe — read the Jira requirement

Use the Atlassian MCP tools sequentially (per repo MCP policy: one call at a
time, wait for each result):

1. `getVisibleJiraProjects` (only if the project key/cloudId is not already
   known) to confirm the PGT project.
2. `getJiraIssue` with the issue key to fetch `summary`, `description`,
   `issuetype`, `priority`, `labels`, `components`.

Do not paraphrase away required detail — carry acceptance criteria and any
explicit constraints verbatim into the generated feature prompt.

### 4. Observe — set up the feature branch

```bash
.agents/skills/jira-feature-intake/scripts/create-feature-branch.sh <ISSUE-KEY> "<short-slug>"
```

This creates/switches to `feature/<ISSUE-KEY>-<short-slug>` off an up-to-date
`master`. Refuses to run on a dirty tree or if the branch already exists with
different history.

### 5. Observe — set up the build ID

```bash
JIRA_ISSUE_KEY=<ISSUE-KEY> eval "$(.agents/skills/workflow-config/scripts/resolve-build-id.sh)"
```

`resolve-build-id.sh` appends `JIRA_ISSUE_KEY` to the derived build ID
(CI or local-date cases only; an explicit `JTEST_BUILD_ID` always wins
untouched). This ties every published Jtest/SOAtest report for the feature
back to the Jira issue.

### 6. Plan/Define — generate the feature prompt instance

Copy `.agents/templates/feature-template.prompt.md` to
`.agents/instances/<ISSUE-KEY>/feature-prompt.md` and fill every section using
the Jira issue fields plus the branch and build ID resolved above. Leave no
section blank — if Jira did not specify a value (e.g. coverage threshold),
mark it `Not specified in issue — confirm before implementation` rather than
inventing one.

### 7. Plan/Define — generate the test plan instance

Copy `.agents/templates/test-plan-template.md` to
`.agents/instances/<ISSUE-KEY>/test-plan.md` and fill it from the feature
prompt's Quality Gates and Acceptance Criteria sections.

### 8. Hand off

Report back:

- Jira issue key and summary.
- Branch name and build ID in use.
- Paths to the generated feature prompt and test plan instances.
- Any `Not specified in issue` gaps that need human confirmation before
  `workflow-delivery` Phase 2 (Plan) begins.

## Hard Rules

- Never invent acceptance criteria, endpoints, or thresholds not present in
  the Jira issue or explicitly confirmed by the user.
- Never push the feature branch or modify the Jira issue status in this
  skill. Status transitions happen in `workflow-delivery` Phase 5 hand-off.
- Do not duplicate config-path or build-ID logic here; use the shared
  `workflow-config` scripts.

## Completion Checks

- Feature branch exists, is based on current `master`, and the tree is clean.
- `JTEST_BUILD_ID` is resolved and includes the Jira issue key.
- Both instance files exist under `.agents/instances/<ISSUE-KEY>/` with no
  unresolved template placeholders left as literal `- ` bullets.
