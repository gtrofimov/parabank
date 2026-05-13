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
   - If missing or stale, run `jtest-build` with mode `ut` or `both` first.
3. Run unit tests. All tests:

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```

   Specific class or method:

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest#testGetCustomer
```

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
cp report/report.xml target/jtest/baseline/report.xml
cp report/coverage.xml target/jtest/baseline/coverage.xml
```

   If either source file is not produced by the run, report it and continue.

6. If coverage analysis is requested, hand off to `jtest-cov-analysis`.

## Reporting

Provide:
- tests executed
- passed
- failed
- key failing tests with error summary

## Completion Checks
- Maven UT command completed.
- `jtestcli` completed with `builtin://Unit Tests`.
- requested scope is reflected in `-Dtest` and/or `-include`/`-exclude`.
- for complete-run UT phase (all tests), `target/jtest/baseline/report.xml` and `target/jtest/baseline/coverage.xml` were updated when generated.

## Decision Rules
- If scope is ambiguous, ask one clarifier: class, method, package, or all tests.
- If only coverage is requested, use `jtest-cov-analysis`.