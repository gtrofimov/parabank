---
name: jtest-run-ut
description: 'Run Jtest unit tests only. Use when asked to execute tests, rerun a subset, or report UT pass/fail outcomes.'
argument-hint: 'Scope: all tests, a package, a class name, a method name, or include/exclude patterns'
---

# Jtest Run UT

Run unit tests from the repository root.

## When To Use
- Execute unit tests only.
- Re-run a specific class or method quickly.

## Procedure

1. Ensure current working directory is the repository root.
2. Ensure `target/jtest/jtest.data.json` is present and current for UT.
   - If missing or stale, run `jtest-build` with mode `ut` first.
   - If `jtest-build` ran in `ut` or `both` and requested scope is all tests, the Maven UT phase already executed; skip step 4 unless an explicit rerun was requested.
   - If a scoped rerun is requested (class/method/package), always run step 4 with the requested scope.
3. **Pre-run orphan check:** Before running the Maven UT command, detect compiled test classes with no corresponding source file:

```bash
comm -23 \
  <(find target/test-classes -name "*.class" | sed 's|target/test-classes/||;s|\.class$||;s|\$.*||' | sort -u) \
  <(find src/test/java -name "*.java"        | sed 's|src/test/java/||;s|\.java$||'               | sort -u)
```

   If any orphans are found, prefix the Maven command with `clean` (e.g., `mvn clean test-compile jtest:agent ...`) to purge stale bytecode before executing. Log which classes were removed. Failure to clean means ghost tests will run and contaminate coverage artifacts.

4. Run unit tests when needed. All tests:

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```

   Specific class or method:

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest#testGetCustomer
```

   **Important — two independent scope axes:**
   - Maven `-Dtest=ClassName` controls **which tests run**. jtestcli `-include` does NOT affect test execution.
   - jtestcli `-include` controls **which SOURCE files appear in coverage output**. Passing a test file path here produces `Coverage: 0/0` because no source file matches.
   - To get coverage for a specific source file, use its source path in `-include` (e.g., `path:**/BillPayResult.java`).
   - For package scope: use matching `-include`/`-exclude` patterns pointing to source packages.

5. Run UT analysis:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests"
```

For a DTP-published complete run, resolve the shared build ID first, then publish
on this first Jtest execution. Do not run Maven tests or Jtest a second time just
to publish. Command-line properties override static defaults in `jtest.settings`:

```bash
.agents/skills/workflow-config/scripts/publish-jtest.sh \
   ut "builtin://Unit Tests" report/ut-final target/jtest/jtest.data.json
```

   Source file scope examples (coverage output scoped to specific source files):

```bash
# coverage for a specific source class
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "path:**/BillPayResult.java"
# coverage for a source package
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "com/parasoft/parabank/dao/jdbc/**"
# coverage for a source subtree, excluding integration
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "com/parasoft/parabank/**" -exclude "**/integration/**"
```

6. For complete-run UT phase (all tests) on `master`, refresh reusable baseline artifacts:

```bash
[[ "$(git branch --show-current)" == "master" ]] || {
   echo "Refusing to refresh the baseline from a non-master branch" >&2
   exit 2
}
mkdir -p target/jtest/baseline
if [[ -f report/report.xml ]]; then
   cp report/report.xml target/jtest/baseline/report.xml
else
   echo "report/report.xml not produced; skipping baseline copy"
fi

if [[ -f report/coverage.xml ]]; then
   cp report/coverage.xml target/jtest/baseline/coverage.xml
else
   echo "report/coverage.xml not produced; skipping baseline copy"
fi
```

   If either source file is not produced by the run, report it and continue.

7. Coverage handoff:
    - If UT and coverage are both requested, hand off to `jtest-cov-analysis` after UT completes using refreshed artifacts.
    - If only coverage is requested, use `jtest-cov-analysis`.

## Reporting

Provide:
- tests executed
- passed
- failed
- key failing tests with error summary

## Completion Checks
- Maven UT command completed, or was intentionally skipped only because `jtest-build` already executed an all-tests UT phase and no rerun was requested.
- `jtestcli` completed with `builtin://Unit Tests`.
- requested scope is reflected in `-Dtest` and/or `-include`/`-exclude`.
- for complete-run UT phase (all tests), `target/jtest/baseline/report.xml` and `target/jtest/baseline/coverage.xml` were updated when generated, and missing artifacts were reported.

## Decision Rules
- If scope is ambiguous, ask one clarifier: class, method, package, or all tests.
- If only coverage is requested, use `jtest-cov-analysis`.
- If UT and coverage are both requested, run this skill first, then `jtest-cov-analysis`.
- If data is stale and `jtest-build` already executed an all-tests UT phase, avoid rerunning the same all-tests Maven UT command unless the user explicitly asks for a rerun.
- If user requested scoped execution, run the scoped Maven UT command even after stale-data rebuild.