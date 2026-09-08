Run the Parabank full baseline quality workflow.

Inputs:

- Run kind: ${QUALITY_RUN_KIND}
- Preset: ${QUALITY_PRESET}
- SOAtest health resource: ${SOATEST_HEALTH_RESOURCE}
- SOAtest API resources:
${SOATEST_API_RESOURCES}

Use existing repository skills for all heavy lifting. Execute required commands
directly in listed order. Do not read unrelated files, inspect generated output
repeatedly, or run diagnostic probes after a successful command.

Required skill flow:

1. Use `workflow-config` to resolve one shared build ID and start the run
   manifest.
2. Use `jtest-build` in `both` mode once to prepare complete Jtest artifacts.
   Reuse its generated `target/jtest/jtest.data.json` for both SA and UT.
3. Use `jtest-run-sa` for full static analysis with the default CWE config:
   `builtin://CWE Top 25 + On the Cusp 2025`.
4. Use `jtest-run-ut` for all unit tests with Jtest coverage. Do not rerun
   `jtest-build`, Maven preparation, or `jtest:agent` before this step.
5. Use `jtest-cov-analysis` to summarize unit-test coverage from the generated
   coverage XML.
6. Use `soatest-orchestration` for monitored API validation. Keep monitor
   preparation, Parabank deployment, health validation, and SOAtest execution
   as explicit steps owned by that skill.
7. Do not run Jtest's `Calculate Application Coverage` configuration. It is not
   part of this workflow. Use the coverage XML already produced by the full
   Jtest unit-test run as the single coverage source. If preset is `publish`,
   publish Jtest and SOAtest with the same build ID.

SOAtest and monitor requirements:

Use the `soatest-cicd` SOAtest MCP server to verify the supplied
`SOATEST_HEALTH_RESOURCE` and `SOATEST_API_RESOURCES` before running shell
scripts. Treat these values as SOAtest server workspace resource paths, not
repository files. Perform one list/describe lookup per resource, then execute.

If SOAtest MCP tools are unavailable, stop and output:

MCP_ERROR: SOAtest MCP tools unavailable

After MCP verification succeeds, pass the resolved server resource paths
directly to the SOAtest execution scripts in the order provided.

1. Deploy the monitored Docker application exactly once with
   `deploy-parabank-docker.sh`. Run it directly, without `| tail`, `|| true`,
   retry, or wrapper that hides its exit code. If it fails, stop the workflow;
   do not inspect, wait, or redeploy. Workflow cleanup destroys deployment.
2. Run the SOAtest health resource first with `run-soatest.sh` and an explicit
   report location.
3. Run the requested API resources, preserving input order, with
   `run-soatest.sh`. Do not invoke `run-soatest-coverage.sh` or calculate
   application coverage from monitor files. Do not inspect SOAtest or coverage
   reports beyond confirming the expected files exist.

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
- Do not rerun Jtest data preparation. One `jtest-build both` output must feed
   both SA and UT.
- Use the same resolved build ID for SA, UT, and SOAtest.
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
APP_COVERAGE_REPORT=<same path as COVERAGE_XML>
PARSER_PATH=<shell/custom|MCP|mixed>
