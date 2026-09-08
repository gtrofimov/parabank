Run the Parabank full baseline quality workflow.

Inputs:

- Run kind: ${QUALITY_RUN_KIND}
- Preset: ${QUALITY_PRESET}
- SOAtest health resource: ${SOATEST_HEALTH_RESOURCE}
- SOAtest API resources:
${SOATEST_API_RESOURCES}

Read and follow repository policy in `.github/copilot-instructions.md` before
running tools. Use existing repository skills for all heavy lifting. Do not
reimplement their command logic in this prompt.

Required skill flow:

1. Use `workflow-config` to resolve one shared build ID and start the run
   manifest.
2. Use `jtest-build` in `both` mode to prepare complete Jtest artifacts.
3. Use `jtest-run-sa` for full static analysis with the default CWE config:
   `builtin://CWE Top 25 + On the Cusp 2025`.
4. Use `jtest-run-ut` for all unit tests with Jtest coverage.
5. Use `jtest-cov-analysis` to summarize unit-test coverage from the generated
   coverage XML.
6. Use `soatest-orchestration` for monitored API validation. Keep monitor
   preparation, Parabank deployment, health validation, SOAtest execution, and
   application coverage as explicit steps owned by that skill.
7. If preset is `publish`, publish Jtest, SOAtest, and application coverage with
   the same build ID.

SOAtest and monitor requirements:

Use the `soatest-cicd` SOAtest MCP server to resolve and verify
`SOATEST_HEALTH_RESOURCE` and `SOATEST_API_RESOURCES` before running shell
scripts. Treat these values as SOAtest server workspace resource paths, not
repository files. Do not use `find`, `ls`, or a local filesystem search to
locate them.

If SOAtest MCP tools are unavailable, stop and output:

MCP_ERROR: SOAtest MCP tools unavailable

After MCP verification succeeds, pass the resolved server resource paths
directly to the SOAtest execution scripts in the order provided.

1. Deploy or redeploy the monitored Docker application with
   `deploy-parabank-docker.sh`. Do not inspect Docker volumes, Maven plugin
   configuration, or README deployment instructions unless that command fails.
2. Run the SOAtest health resource first with `run-soatest.sh` and an explicit
   report location.
3. Run the requested API resources, preserving input order, with
   `run-soatest-coverage.sh` so Jtest calculates application coverage. For the
   Docker deployment, that script copies monitor runtime data out of the running
   Parabank container.

Hard rules:

- Do not use `run-functional-pipeline.sh`.
- Docker is the only supported monitored application deployment path. Do not use
   alternate host-side application server preparation.
- Do not edit `.tst` files directly.
- Do not use shell commands to discover SOAtest `.tst` resources. Use SOAtest
   MCP for resource lookup, then shell scripts for execution.
- Do not create new feature behavior.
- Do not rerun Jtest only for publishing; publish on first execution when
  publishing is requested.
- Use the same resolved build ID for SA, UT, SOAtest, and application coverage.
- Use repository config from `config/orchestration.config` and
   `config/jtest-skills.config`.
- Use `$JTEST_HOME/jtestcli.properties` only for Jtest installation settings such
   as licensing. Pass project-specific Jtest values explicitly on the command
   line.
- If run kind is `baseline`, refresh baseline snapshots only when the checked-out
  branch is `master`.
- If run kind is `feature`, consume existing baseline artifacts and do not
  overwrite `target/jtest/baseline/*`.
- If a required secret or tool is missing, stop and report the missing
  prerequisite.

Final response must end with these plain-text metadata lines, with no bullets or
code fence:

QUALITY_STATUS=passed|failed
BUILD_ID=<resolved build id>
SA_STATUS=passed|failed
SA_REPORT=<path or -->
UT_STATUS=passed|failed
UT_REPORT=<path or -->
COVERAGE_STATUS=passed|failed
COVERAGE_XML=<path or -->
SOATEST_STATUS=passed|failed
SOATEST_REPORT=<path or -->
APP_COVERAGE_STATUS=passed|failed
APP_COVERAGE_REPORT=<path or -->
PARSER_PATH=<shell/custom|MCP|mixed>
