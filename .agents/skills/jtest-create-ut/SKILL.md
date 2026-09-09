---
name: jtest-create-ut
description: 'Generate new unit tests only. Use when asked to create tests for classes with low or missing coverage.'
argument-hint: 'Scope: all classes, package path, single class, or include/exclude patterns'
---

# Jtest Create UT

Generate unit tests for source classes from the repository root.

## When To Use
- Create tests for classes with no or low test coverage.
- Auto-generate tests for one class, one package, or a larger scope.

## Requirements
- Jtest 2025.2 or later.
- Project should be under Git source control.
- Test creation must run separately from SA and metrics configurations.

## Procedure

1. Ensure current working directory is the repository root.
2. Ensure `target/jtest/jtest.data.json` is present and current.
   - If missing or stale, run `jtest-build` with mode `sa`.
   - Use mode `both` only when the same request explicitly includes immediate UT execution after generation.
3. Run test creation:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Create Unit Tests"
```

   Scope examples:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Create Unit Tests" -include "path:**/LoanResponseBuilder.java"
jtestcli -data target/jtest/jtest.data.json -config "builtin://Create Unit Tests" -include "com/parasoft/parabank/domain/**" -exclude "**/test/**"
jtestcli -data target/jtest/jtest.data.json -config "builtin://Create Unit Tests" -include include.lst
```

4. Identify generated test files under `src/test/java/` (use `git status` or `find` filtered by modification time).

5. **Scoped rebuild** — update `jtest.data.json` to include the new test classes without running the full suite (see jtest-build Scoped Rebuild Rule):

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=<GeneratedTestClass>
```

   Use a comma-separated list for multiple generated classes: `-Dtest=FooTest,BarTest`.

6. **Run the generated tests** scoped to the generated class(es):

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Unit Tests" -include "path:**/GeneratedTestClass.java"
```

7. **Fix failing or incomplete tests using Copilot**:
   - Read the generated test file(s) and the surefire report for the failing class (under `target/surefire-reports/<ClassName>.txt`).
   - For each failing or errored test method, read the failure message and stack trace.
   - Diagnose the root cause: wrong assertion value, missing setup, incorrect mock, or invalid input.
   - Apply targeted fixes directly to the generated test file — do not regenerate.
   - Common fixes:
     - Adjust hardcoded assertion values to match actual return values.
     - Add `@Before` setup or field initialization that the generated stub omitted.
     - Replace invalid default inputs (e.g., `null`, `0`) with values that satisfy preconditions.
     - Add `@Test(expected = SomeException.class)` for tests that are expected to throw.
   - After each round of fixes, re-run step 6 to confirm tests pass.
   - Repeat until all generated tests pass or are explicitly marked `@Ignore` with a comment explaining why.

8. **Check coverage delta** for the targeted source class(es) using the coverage XML produced by the scoped Jtest run in step 6 (`target/jtest/coverage.xml`). Do **not** re-run all tests or refresh the baseline just to report coverage — the scoped run already contains the relevant data.

```bash
bash .agents/skills/jtest-cov-analysis/coverage-gap-analysis.sh --coverage-xml "reports/jtest/ut-final/coverage.xml" --include "<path/to/SourceClass.java>" --top 0 --method-top 0 --output csv
```

9. Report final pass/fail counts and coverage delta.

## Reporting

Provide:
- files in scope
- test files generated
- list of generated test file paths
- test results after fix cycle: passed / failed / ignored
- coverage for the targeted class(es) before and after (use `reports/jtest/ut-final/coverage.xml` from the scoped run)

## Completion Checks
- `jtestcli` completed with `builtin://Create Unit Tests`.
- requested scope is reflected in `-include`/`-exclude`.
- generated tests are present in `src/test/java/`.
- generated tests were executed and all pass (or failures are `@Ignore`d with explanation).
- no fix loop ran more than 3 iterations; escalate to user if still failing after 3 attempts.

## Decision Rules
- If scope is ambiguous, ask one clarifier: class, package, or all.
- If user gives a class name, prefer `path:**/ClassName.java`.
- For stale data refresh in generation-only workflows, default to `jtest-build` mode `sa`.
- Always use the Scoped Rebuild Rule (step 5) after generation — never run the full test suite just to update `jtest.data.json`.
