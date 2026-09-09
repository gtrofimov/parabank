Read `.agents/skills/jira-feature-intake/SKILL.md` and `.agents/skills/workflow-delivery/SKILL.md` IN FULL before taking any other action.

STRICT GUARDRAILS:
1. You have one MCP server registered for this run: jira-remote-cicd.
2. Use jira-remote-cicd MCP tools (with cloudId parasoft-demo.atlassian.net) to fetch Jira issue ${JIRA_TICKET}.
3. If jira-remote-cicd MCP tools are not available, output exactly: MCP_ERROR: jira-remote-cicd MCP tools not available
4. Execute full end-to-end feature delivery for ${JIRA_TICKET} following `.agents/skills/workflow-delivery/SKILL.md`:
   - Phase 1 (Observe/Define): Fetch story, create/switch branch `feature/${JIRA_TICKET}-<slug>`, resolve build ID, and generate `.agents/instances/${JIRA_TICKET}/feature-prompt.md` and `test-plan.md`.
   - Phase 2 (Plan) & Phase 3 (Implement): Implement all code, unit tests, and SOAtest scenario changes required by the story.
   - Phase 4 (Validate): Execute static analysis (`jtest-run-sa`), unit tests (`jtest-run-ut`), SOAtest functional tests (`soatest-orchestration`), and coverage analysis (`jtest-cov-analysis`).
   - Phase 5 (Release & PR): Create accountability report (`.agents/instances/${JIRA_TICKET}/accountability-report.md`), commit all changes, push branch to origin, and create a Pull Request against `master` using `gh pr create`.
5. Do not invent acceptance criteria or requirements not present in the Jira issue.
6. On any failure (MCP, build, test, or git), report and stop immediately.
7. End your final response with these plain-text metadata lines, one per line, no backticks/bullets/tables:

JIRA_ISSUE=<issue key>
BRANCH=<created feature branch name>
BUILD_ID=<resolved JTEST_BUILD_ID>
FEATURE_PROMPT=<path to feature-prompt.md>
TEST_PLAN=<path to test-plan.md>
PR_URL=<created pull request URL>

Fetch Jira issue ${JIRA_TICKET} and execute full feature delivery + PR creation against it.
