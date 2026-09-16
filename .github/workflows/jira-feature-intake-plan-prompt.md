Read `.agents/skills/jira-feature-intake/SKILL.md` IN FULL before taking any other action. This is the "Plan: Jira" phase only — it does not implement, validate, or release anything.

STRICT GUARDRAILS:
1. You have one MCP server registered for this run: jira-remote-cicd.
2. Use jira-remote-cicd MCP tools (with cloudId parasoft-demo.atlassian.net) to fetch Jira issue ${JIRA_TICKET}.
3. If jira-remote-cicd MCP tools are not available, output exactly: MCP_ERROR: jira-remote-cicd MCP tools not available
4. `JTEST_BUILD_ID` is already resolved in the environment (set by the prior "Observe: Parasoft DTP" step). Use it as-is; do not recompute it.
5. Confirm the working tree is clean, then create/switch to branch `feature/${JIRA_TICKET}-<slug>` using `.agents/skills/jira-feature-intake/scripts/create-feature-branch.sh`.
6. Generate `.agents/instances/${JIRA_TICKET}/feature-prompt.md` and `test-plan.md` from the canonical templates. Carry acceptance criteria verbatim; mark any value Jira did not specify as `Not specified in issue — confirm before implementation` rather than inventing one.
7. Do not implement code, run tests, deploy, publish to DTP, commit, push, or create a PR in this phase — those happen in later pipeline steps.
8. Do not invent acceptance criteria or requirements not present in the Jira issue.
9. On any failure (MCP, git, or template), report and stop immediately.
10. End your final response with these plain-text metadata lines, one per line, no backticks/bullets/tables:

JIRA_ISSUE=<issue key>
BRANCH=<created feature branch name>
FEATURE_PROMPT=<path to feature-prompt.md>
TEST_PLAN=<path to test-plan.md>

Fetch Jira issue ${JIRA_TICKET} and complete only the Observe (branch/build-id linkage) and Plan/Define (feature prompt + test plan) steps.
