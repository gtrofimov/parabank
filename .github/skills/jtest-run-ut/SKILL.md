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
   - If `jtest-build` ran in `ut` or `both` and requested scope is all tests, the Maven UT phase already executed; skip step 3 unless an explicit rerun was requested.
   - If a scoped rerun is requested (class/method/package), always run step 3 with the requested scope.
3. Run unit tests when needed. All tests:

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```

   Specific class or method:

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest#testGetCustomer
```

   Keep scope consistent between Maven and Jtest CLI:
   - class/method scope: use `-Dtest=ClassName` or `-Dtest=ClassName#methodName` and mirror class scope in `jtestcli -include`.
   - package/path scope: use matching `-include`/`-exclude` patterns in `jtestcli`.

4. Run UT analysis:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests"
```

   Scope examples:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "com/parasoft/parabank/dao/jdbc/**"
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "path:**/JdbcCustomerDaoTest.java"
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "com/parasoft/parabank/**" -exclude "**/integration/**"
```

5. For complete-run UT phase (all tests), refresh reusable baseline artifacts:

```bash
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

6. Coverage handoff:
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