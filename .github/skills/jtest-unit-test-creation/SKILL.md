---
name: jtest-unit-test-creation
description: 'Generate new unit tests for parabank source classes using Jtest CLI. Use when asked to create, generate, or auto-generate unit tests with Jtest.'
argument-hint: 'Scope: all classes, a package, a single class name, or include/exclude patterns'
---

# Jtest Unit Test Creation

Generate new unit tests for parabank source classes from the repository root using the `builtin://Create Unit Tests` configuration.

## When To Use
- Generate unit tests for source classes that have no or low test coverage.
- Auto-create tests for a specific class, package, or the entire project.

## Requirements
- Jtest 2025.2 or later (the `builtin://Create Unit Tests` config does not exist in earlier versions).
- Project must be under Git source control — Jtest uses SCM to allow reverting generated tests. Override with `jtest.project.allowNoSourceControl=true` only if Git is unavailable.
- Test creation must be a **separate** Jtest run — do not combine with static analysis or metrics configs.

## Procedure

> **Two steps always required.** Maven **compiles and generates** `target/jtest/jtest.data.json`; `jtestcli` **runs test creation** and writes new test files under `src/test/java/`.
>
> **Scoping:** `-include`/`-exclude` on `jtestcli` filter which source files tests are created for. The CLI can scope to modified *files*; scoping to modified *lines* is IDE-only.

1. Ensure current working directory is the repository root.
2. **Generate the data file.** Compile and produce `target/jtest/jtest.data.json`:

```bash
mvn clean test-compile jtest:jtest -Djtest.skip=true
```

3. **Run test creation.** For all source files:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Create Unit Tests"
```

   Scoped to a single file:

```bash
jtestcli -data target/jtest/jtest.data.json \
  -config "builtin://Create Unit Tests" \
  -include "path:**/LoanResponseBuilder.java"
```

   Scoped to a package (excluding existing test classes):

```bash
jtestcli -data target/jtest/jtest.data.json \
  -config "builtin://Create Unit Tests" \
  -include "com/parasoft/parabank/domain/**" \
  -exclude "**/test/**"
```

   Bulk list file (one pattern per line):

```bash
jtestcli -data target/jtest/jtest.data.json \
  -config "builtin://Create Unit Tests" \
  -include include.lst
```

   **Alternative — Maven single-step** (skips explicit data file generation):

```bash
mvn jtest:jtest -Djtest.config="builtin://Create Unit Tests"
```

   With Maven scoping:

```bash
mvn jtest:jtest \
  -Djtest.config="builtin://Create Unit Tests" \
  -Djtest.includes=**/LoanResponseBuilder
```

4. After test creation completes, review generated files in `src/test/java/` before proceeding.
5. **Run the generated tests** to collect coverage (use the `jtest-unit-tests` skill for this step).

## Reporting Results

After `jtestcli` completes, present:

| Metric | Value |
|---|---|
| Files in scope | N |
| Test files generated | N |
| Generation errors | N |

List the paths of any newly generated test files.

If generation errors occur, report the class name and error message for each failure.

## Completion Checks
- Step 1 (Maven) completed with BUILD SUCCESS.
- Step 2 (`jtestcli`) completed without errors.
- Requested scope is reflected in the `-include`/`-exclude` flags.
- New test files are visible under `src/test/java/`.
- Test creation was **not** combined with a static analysis or metrics config in the same run.

## Decision Rules
- If user request is ambiguous about scope, ask one clarifier: class, package, or all?
- If user provides a class name, use `path:**/ClassName.java` as the include pattern.
- If user provides a package, use the slash-notation package path with `/**`.
- Recommend scoping to a single class or package first rather than running on the entire project.

## References
- Jtest docs: Creating Unit Tests from the Command Line
- Jtest docs: `builtin://Create Unit Tests` configuration (Jtest 2025.2+)
