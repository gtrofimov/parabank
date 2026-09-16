Read `.agents/skills/workflow-delivery/SKILL.md` IN FULL before taking any other action, and read `feature.loop`. This is the "Act: Jtest, SOAtest, Virtualize" phase only - Plan/Define already ran; Verify runs after this.

CONTEXT ALREADY ON DISK (from the prior "Plan: Jira" step, same job workspace):
- Branch `${BRANCH}` is checked out.
- `JTEST_BUILD_ID` is resolved in the environment.
- `${FEATURE_PROMPT}` and `${TEST_PLAN}` exist under `.agents/instances/${JIRA_TICKET}/`.

Read `${FEATURE_PROMPT}` and `${TEST_PLAN}` before implementing anything.

STRICT GUARDRAILS:
1. If branch `${BRANCH}` is not already checked out, run `git checkout ${BRANCH}` first.
2. Read the feature prompt and test plan, then identify the reference branch from `JTEST_REFERENCE_BRANCH` (default `master`). Run `git fetch --no-tags origin "${JTEST_REFERENCE_BRANCH}"` before Jtest. After implementation and test generation, use `git diff --name-only "origin/${JTEST_REFERENCE_BRANCH}...HEAD"` only to identify newly generated UT classes; Jtest SA must use its native source-control scope against `origin/${JTEST_REFERENCE_BRANCH}`.
3. Implement all code and unit tests required by the feature prompt and test plan.
4. When `feature.loop` requires an API prototype, create a **stateless** virtual service through the SOAVirt MCP server. Use this asset only as a prototype backend for verifying generated API tests. Do not use the stateful virtual-service creator unless Jira explicitly requires state.
5. Generate SOAtest scenarios through SOAtest MCP tools, and retain the exact resource paths created for this Jira feature. Execute only those new feature scenarios, one resource at a time; do not run the existing SOAtest regression set here.
6. Generate UTA tests only for changed production classes or the explicitly named feature scope. Do not generate a project-wide test set.
7. Run Jtest SA with its native reference scope and the repository's configured SA profile: pass `-property scope.scontrol=true -property scope.files.time.filter.mode=4 -property scope.lines.time.filter.mode=4 -property scope.default.branch=false -property scope.branch="origin/${JTEST_REFERENCE_BRANCH}"`. Do not replace this with an agent-side violation comparison; add `-include` only for an explicitly narrower path. Use the mandatory `jtest-cicd` MCP for report and rule retrieval. If it is unavailable, stop with `MCP_ERROR: Jtest MCP unavailable`; do not use a shell-parser fallback.
8. Fix new SA violations, then rerun only the affected scoped SA command until the changed scope is clean. Do not run a full-project SA pass.
9. Run only the newly generated unit tests. Maven test execution scope is controlled by `-Dtest=<new test class names>`; Jtest `-include` controls source coverage scope and must not be used as a substitute for `-Dtest`. Fix failures and rerun only the affected new test classes until clean.
10. For application deployment, Docker is mandatory: run `.agents/skills/soatest-orchestration/scripts/deploy-parabank-docker.sh` and use the Docker-based coverage flow. Do not deploy with Maven Cargo, embedded Tomcat, host-side Tomcat, Jetty, `cargo:start`, or `cargo:run`. If Docker is unavailable, fail with `MCP_ERROR: Docker deployment required but Docker is unavailable`; do not select a fallback.
11. DTP credentials (`DTP_URL`, `DTP_USER`, `DTP_PASSWORD`) are present in environment; publish the clean scoped SA, new-test UT, and new-feature SOAtest reports to DTP using `JTEST_BUILD_ID` as the build identity. Do not rerun a gate solely to publish it.
12. Do not run full-project coverage analysis, generate the accountability report, commit, push, or create a PR in this phase - those happen in "Verify: Parasoft DTP".
13. MAX OPTIMIZATION, EXECUTION SPEED & TOKEN CONSERVATION:
    - Combine shell commands with `&&` into compound turns to minimize tool round-trips.
    - Truncate long command outputs (`| tail -n 30` or `grep`) to keep context window slim.
14. On any failure (MCP, build, test, or git), report and stop immediately.
15. End your final response with this plain-text metadata line, no backticks/bullets/tables:

ACT_STATUS=done

Implement the feature for `${JIRA_TICKET}` on branch `${BRANCH}` and run the SA/UT/SOAtest validation gates described above.
