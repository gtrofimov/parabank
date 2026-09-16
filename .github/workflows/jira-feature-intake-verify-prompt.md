Read `.agents/skills/workflow-delivery/SKILL.md` IN FULL before taking any other action (focus on Phase 4's final regression gate and Phase 5). This is the "Verify: Parasoft DTP" phase only — Observe, Plan, and Act already ran.

CONTEXT ALREADY ON DISK (same job workspace):
- Branch `${BRANCH}` is checked out with the implementation from the Act phase.
- `JTEST_BUILD_ID` is resolved in the environment.
- `${FEATURE_PROMPT}` and `${TEST_PLAN}` exist under `.agents/instances/${JIRA_TICKET}/`.

STRICT GUARDRAILS:
1. Run `jtest-cov-analysis` for application coverage. Reuse the Jtest/coverage artifacts already produced in the Act phase; do not rebuild or rerun tests solely to publish.
2. Confirm DTP has SA, UT, SOAtest, and coverage results for `JTEST_BUILD_ID`; publish anything not already published by the Act phase using the credentials in environment (`DTP_URL`, `DTP_USER`, `DTP_PASSWORD`).
3. Run the final branch-level regression check against baseline described in `workflow-delivery` Phase 4. If a gate fails, make the smallest fix (bug or test) and re-run only the affected gate — do not re-run gates that already passed.
4. Generate the accountability report `.agents/instances/${JIRA_TICKET}/accountability-report.md` from `.agents/templates/accountability-report-template.md`, linking the Jira issue, branch, build ID, and every evidence artifact.
5. Commit all changes, push branch `${BRANCH}` to origin, and create a Pull Request against `master` using `gh pr create`.
6. Do not invent acceptance criteria or requirements not present in the Jira issue.
7. On any failure (MCP, build, test, or git), report and stop immediately.
8. End your final response with this plain-text metadata line, no backticks/bullets/tables:

PR_URL=<created pull request URL>

Complete final verification and release for `${JIRA_TICKET}` on branch `${BRANCH}`.
