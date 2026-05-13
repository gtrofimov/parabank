---
name: jtest-build
description: 'Generate and keep target/jtest/jtest.data.json up to date for SA, UT, or both workflows.'
argument-hint: 'Mode: sa, ut, or both; optional task scope (class/package/path)'
---

# Jtest Build

Prepare Jtest build artifacts, especially `target/jtest/jtest.data.json`, and keep them current against project changes.

## When To Use
- Before `jtest-run-sa`, `jtest-run-ut`, or `jtest-create-ut`.
- When source/test files changed and the existing data file may be stale.

## Modes
- `sa`: prepare data for static analysis flow.
- `ut`: prepare data for unit-test flow; this mode runs the Maven UT lifecycle.
- `both`: prepare for both SA and UT (default); includes the Maven UT lifecycle.

## Freshness Rules

Treat `target/jtest/jtest.data.json` as stale when any of these is true:
- file does not exist
- `pom.xml` changed
- any `src/main/java/**` file is newer than the data file
- for `ut` and `both`, any `src/test/java/**` file is newer than the data file

## Procedure

1. Ensure current working directory is repository root.
2. Determine mode (`both` by default).
3. If data file is fresh for the selected mode, reuse it.
4. If stale or missing, regenerate based on mode.
5. If mode is `both` (complete-run build phase), copy the generated data file to a reusable baseline snapshot:

```bash
mkdir -p target/jtest/baseline
cp target/jtest/jtest.data.json target/jtest/baseline/jtest.data.json
```

`sa` mode:

```bash
mvn compile jtest:jtest -Djtest.skip=true
```

`ut` mode:

```bash
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```

`both` mode:

```bash
mvn compile jtest:jtest -Djtest.skip=true
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true
```

## Handoff

- After `sa` or `both`, continue with `jtest-run-sa`.
- After `ut` or `both`, continue with `jtest-run-ut`.
- For test generation, continue with `jtest-create-ut`.

## Completion Checks
- `target/jtest/jtest.data.json` exists.
- command(s) for selected mode completed successfully.
- selected mode and scope were respected.
- for `both` mode, `target/jtest/baseline/jtest.data.json` exists and matches the latest generated data file.

## Decision Rules
- If mode is omitted, use `both`.
- If request is SA-only, use `sa`.
- If request is UT-only or coverage-focused, use `ut`.
- If request is test-creation-only, use `sa`.
- If request combines test creation and immediate UT execution, use `both`.
