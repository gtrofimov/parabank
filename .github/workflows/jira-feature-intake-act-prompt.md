Read `.agents/skills/workflow-delivery/SKILL.md` IN FULL before taking any other action, and read `feature.loop`. This is the "Act: Jtest, SOAtest, Virtualize" phase only — Plan/Define already ran; Verify runs after this.

CONTEXT ALREADY ON DISK (from the prior "Plan: Jira" step, same job workspace):
- Branch `${BRANCH}` is checked out.
- `JTEST_BUILD_ID` is resolved in the environment.
- `${FEATURE_PROMPT}` and `${TEST_PLAN}` exist under `.agents/instances/${JIRA_TICKET}/`.

Read `${FEATURE_PROMPT}` and `${TEST_PLAN}` before implementing anything.

STRICT GUARDRAILS:
1. If branch `${BRANCH}` is not already checked out, run `git checkout ${BRANCH}` first.
2. Implement all code and unit tests required by the feature prompt and test plan.
3. When `feature.loop` requires an API prototype, create a **stateless** virtual service through the SOAVirt MCP server. Use this asset only as a prototype backend for verifying generated API tests. Do not use the stateful virtual-service creator unless Jira explicitly requires state.
4. Generate SOAtest scenarios through SOAtest MCP tools.
5. Execute static analysis (`jtest-run-sa`) and unit tests (`jtest-run-ut`) once each. Do not re-run or execute comparative/multi-run passes.
6. For application deployment, Docker is mandatory: run `.agents/skills/soatest-orchestration/scripts/deploy-parabank-docker.sh` and use the Docker-based coverage flow. Do not deploy with Maven Cargo, embedded Tomcat, host-side Tomcat, Jetty, `cargo:start`, or `cargo:run`. If Docker is unavailable, fail with `MCP_ERROR: Docker deployment required but Docker is unavailable`; do not select a fallback.
7. Run the generated SOAtest functional tests (`soatest-orchestration`), one scenario at a time rather than batched.
8. DTP credentials (`DTP_URL`, `DTP_USER`, `DTP_PASSWORD`) are present in environment; publish SA, UT, and SOAtest reports to DTP using `JTEST_BUILD_ID` as the build identity.
9. Do not run coverage analysis, generate the accountability report, commit, push, or create a PR in this phase — those happen in "Verify: Parasoft DTP".
10. MAX OPTIMIZATION, EXECUTION SPEED & TOKEN CONSERVATION:
    - Combine shell commands with `&&` into compound turns to minimize tool round-trips.
    - Truncate long command outputs (`| tail -n 30` or `grep`) to keep context window slim.
11. On any failure (MCP, build, test, or git), report and stop immediately.
12. End your final response with this plain-text metadata line, no backticks/bullets/tables:

ACT_STATUS=done

Implement the feature for `${JIRA_TICKET}` on branch `${BRANCH}` and run the SA/UT/SOAtest validation gates described above.
