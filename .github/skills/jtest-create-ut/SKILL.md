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
   - If missing or stale, run `jtest-build` with mode `sa` or `both`.
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

4. Review generated files under `src/test/java/`.
5. Run generated tests using `jtest-run-ut`.

## Reporting

Provide:
- files in scope
- test files generated
- generation errors
- list of generated test file paths

## Completion Checks
- `jtestcli` completed with `builtin://Create Unit Tests`.
- requested scope is reflected in `-include`/`-exclude`.
- generated tests are present in `src/test/java/`.

## Decision Rules
- If scope is ambiguous, ask one clarifier: class, package, or all.
- If user gives a class name, prefer `path:**/ClassName.java`.
