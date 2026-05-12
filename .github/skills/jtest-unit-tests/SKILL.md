---
name: jtest-unit-tests
description: 'Run Jtest unit tests in parabank with jtestcli. Use when asked to execute unit tests, rerun only specific tests, or narrow scope with include/exclude/resource patterns.'
argument-hint: 'Scope: all tests, a package, a class name, or include/exclude patterns'
---

# Jtest Unit Test Runner

Run and scope Jtest unit tests from the repository root.

## When To Use
- Run unit tests with Jtest (all or a specific subset).
- Analyze coverage for specific classes or packages.

## Procedure

> **Two steps.** Maven **executes** the tests and generates `target/jtest/jtest.data.json`; `jtestcli` **analyzes and reports** results. Step 1 can be skipped if `target/jtest/jtest.data.json` already exists and you only want to re-slice a previous run with a different scope or config.
>
> **Scoping:** `-include`/`-exclude` on `jtestcli` filter the *report* only. To limit which tests Maven actually runs, use `-Dtest=ClassName` or `-Dtest=ClassName#methodName`.

1. Ensure current working directory is the repository root.
2. **Run unit tests.** For all tests:

```bash
mvn clean test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```

   For a specific class or method, append `-Dtest=`:

```bash
# Single class
mvn clean test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest

# Single method
mvn clean test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=JdbcCustomerDaoTest#testGetCustomer
```

3. **Analyze results.** For all tests:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests"
```

   For a specific scope, add `-include` (and optionally `-exclude`) to match the Maven `-Dtest=` pattern:

```bash
# Package
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "com/parasoft/parabank/dao/jdbc/**"

# Single file
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "path:**/JdbcCustomerDaoTest.java"

# Include with exclusion
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "com/parasoft/parabank/**" -exclude "**/integration/**"

# Bulk list file (one pattern per line)
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include include.lst
```

4. **Analyze coverage** using `mcp_jtest_query_line_coverage` — never Python, shell, or manual XML parsing. Set `path_to_coverage_xml` to the absolute path of `target/jtest/coverage.xml`. Call **sequentially** (never in parallel). For each source file in scope make two calls:
   - `query_type: "coverable"` — total lines
   - `query_type: "notcovered"` — missed lines (covered = coverable − notcovered)

   Read source files to map uncovered line numbers to method names.
5. Present results as described in [Reporting Results](#reporting-results).

## Reporting Results

### Test Execution Summary

Present a summary table immediately after `jtestcli` completes:

| Metric | Value |
|---|---|
| Tests executed | N |
| Passed | N |
| Failed | N |
| Coverage | X/Y lines (Z%) |

### Per-File Coverage Table

For each source file analyzed, present:

| File | Covered | Total | % |
|---|---|---|---|
| `Account.java` | 97 | 98 | 99% |
| `JdbcAccountDao.java` | 42 | 50 | 84% |

### Uncovered Lines & Methods

For each file with uncovered lines, list:

**`FileName.java`**
- Line 84: `getIntType()` — null-type branch not exercised
- Line 102: `someMethod()` — not reached

Group uncovered lines by method when possible. If a whole method is uncovered, state that explicitly rather than listing every line.

## Completion Checks
- Step 1 (Maven) completed with BUILD SUCCESS or was skipped because `target/jtest/jtest.data.json` already exists and only a re-slice was needed.
- Step 2 (`jtestcli`) completed without errors.
- Requested scope (all vs targeted) is reflected in the `jtestcli` command.
- The command keeps using `-data target/jtest/jtest.data.json` and `-config "builtin://Unit Tests"` unless user asks otherwise.
- Coverage was analyzed using `mcp_jtest_query_line_coverage` only — no Python or shell XML parsing.
- Results include a summary table, per-file coverage table, and uncovered lines section.

## Decision Rules
- If user request is ambiguous, ask one clarifier: class/package/path pattern?
- If user gives multiple scopes, combine with repeated `-include` and optional `-exclude`.
- If scope is broad and slow, recommend include list file for repeatability.
- If `target/jtest/jtest.data.json` exists and the user only wants to re-slice a previous run with a different scope, skip Step 1 — but do not use `clean` or Step 1 will wipe the data file.

## References
- Jtest docs: Command Line Options (scope options `-resource`, `-include`, `-exclude`)
- Jtest docs: Configuring the Test Scope (pattern syntax and list-file usage)