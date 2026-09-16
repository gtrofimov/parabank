Read `.agents/skills/workflow-delivery/SKILL.md` IN FULL before taking any other action (focus on Phase 4 evidence review and Phase 5). This is the "Verify: Parasoft DTP" phase only - Observe, Plan, and Act already ran.

CONTEXT ALREADY ON DISK (same job workspace):
- Branch `${BRANCH}` is checked out with the implementation from the Act phase.
- `JTEST_BUILD_ID` is resolved in the environment.
- `${FEATURE_PROMPT}` and `${TEST_PLAN}` exist under `.agents/instances/${JIRA_TICKET}/`.

STRICT GUARDRAILS:
1. Run `jtest-cov-analysis` against coverage artifacts already produced in Act. Reuse those artifacts; do not rebuild or rerun tests solely for coverage or publication. If a scoped coverage artifact is absent, report the gap instead of launching a project-wide test run.
2. Use the registered `dtp-cicd` MCP server to confirm SA, UT, SOAtest, and coverage results for `JTEST_BUILD_ID`. Use the mandatory `jtest-cicd` MCP for Jtest report and rule details. If it is unavailable, stop with `MCP_ERROR: Jtest MCP unavailable`; do not use a shell-parser fallback. Publish only missing artifacts using (`DTP_URL`, `DTP_USER`, `DTP_PASSWORD`).
3. Do not launch a full-project regression in Verify. Review the clean scoped gates and newly created SOAtest resources from Act; if evidence is missing or a scoped gate failed, rerun only that affected scope and leave passed gates untouched.
4. Generate the accountability report `.agents/instances/${JIRA_TICKET}/accountability-report.md` from `.agents/templates/accountability-report-template.md`, linking the Jira issue, branch, build ID, scoped changed-file/test inputs, SOAtest resources, DTP result links, and every evidence artifact.
5. Commit all changes, push branch `${BRANCH}` to origin, and create a Pull Request against `master` using `gh pr create`.
6. Do not invent acceptance criteria or requirements not present in the Jira issue.
7. On any failure (MCP, build, test, or git), report and stop immediately.
8. End your final response with this plain-text metadata line, no backticks/bullets/tables:

PR_URL=<created pull request URL>

Complete final verification and release for `${JIRA_TICKET}` on branch `${BRANCH}`.
