# Accountability Report Template

Generate this report once during Phase 5 (Release / Hand-off), after all
validation evidence exists. It is the single artifact that ties the Jira
requirement, the branch, the build identity, and every quality gate together.

## Identity

- Jira issue: 
- Branch: 
- Build ID (`JTEST_BUILD_ID`): 
- Commit: 
- Author / agent run: 
- Date: 

## Requirement Traceability

- Feature prompt instance: `.agents/instances/<ISSUE-KEY>/feature-prompt.md`
- Test plan instance: `.agents/instances/<ISSUE-KEY>/test-plan.md`
- Acceptance criteria met: yes / no (list any unmet with reason)

## Evidence Chain

| Gate | Tool / skill | Report path or DTP link | Result |
|---|---|---|---|
| Static analysis (CWE) | jtest-run-sa | | |
| Unit tests | jtest-run-ut | | |
| API / functional tests | soatest-orchestration | | |
| Application coverage | jtest-cov-analysis | | |
| Baseline comparison | | | |

## Deviations / Waivers

List any threshold not met and the explicit rationale/approval for waiving it.

- 

## Pull Request

- PR link: 
- Reviewers requested: 

## Jira Hand-off

- Issue transitioned to: 
- Comment/link posted: yes / no
