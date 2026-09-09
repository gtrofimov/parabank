Read `.agents/skills/jira-feature-intake/SKILL.md` IN FULL before taking any other action.

STRICT GUARDRAILS:
1. You have one MCP server registered for this run: jira-remote-cicd.
2. Use jira-remote-cicd MCP tools to fetch Jira issue ${JIRA_TICKET}, one call at a time, waiting for each result.
3. If jira-remote-cicd MCP tools are not available, output exactly: MCP_ERROR: jira-remote-cicd MCP tools not available
4. Do not implement the feature. This run owns only the observe/define phase:
   baseline check, feature branch creation, build ID resolution, and
   generating the feature-prompt and test-plan instances.
5. Do not invent acceptance criteria, endpoints, or thresholds not present in
   the Jira issue.
6. Commit the generated `.agents/instances/${JIRA_TICKET}/feature-prompt.md`
   and `.agents/instances/${JIRA_TICKET}/test-plan.md` on the new feature
   branch, then push the branch to origin. Do not push to master and do not
   open a pull request in this run.
7. On any failure (MCP, git, or otherwise), report and stop immediately.
8. End your final response with these plain-text metadata lines, one per
   line, no backticks/bullets/tables:

JIRA_ISSUE=<issue key>
BRANCH=<created feature branch name>
BUILD_ID=<resolved JTEST_BUILD_ID>
FEATURE_PROMPT=<path to feature-prompt.md>
TEST_PLAN=<path to test-plan.md>

Fetch Jira issue ${JIRA_TICKET} and run the jira-feature-intake observe/define
procedure against it, following the skill exactly.
