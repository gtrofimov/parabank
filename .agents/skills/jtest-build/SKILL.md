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
- for `ut` and `both`, any compiled test class in `target/test-classes/` has no corresponding source file in `src/test/java/` (deleted source, orphaned bytecode)

To detect orphaned test classes before rebuilding:

```bash
comm -23 \
  <(find target/test-classes -name "*.class" | sed 's|target/test-classes/||;s|\.class$||;s|\$.*||' | sort -u) \
  <(find src/test/java -name "*.java"        | sed 's|src/test/java/||;s|\.java$||'               | sort -u)
```

If any orphans are found, run `mvn clean` before the rebuild command to purge stale bytecode. Orphaned classes cause ghost tests to appear in jtest.data.json and coverage artifacts.

## Scoped Rebuild Rule

Before running a full `ut` rebuild, check whether the staleness is caused **only** by new or modified test files (no `src/main/java/**` or `pom.xml` changes):

```bash
# identify stale-triggering files
git diff --name-only HEAD   # or compare timestamps vs jtest.data.json
```

If **only** `src/test/java/**` files are newer (e.g., a newly generated test class), use a scoped rebuild targeting just those test classes instead of running the full test suite:

```bash
# scoped: rebuild data file for a single test class only
mvn test-compile jtest:agent test jtest:jtest -Djtest.skip=true -Dmaven.test.failure.ignore=true -Dtest=BillPayResultTest
```

Use the class name(s) of the changed test file(s) in `-Dtest=`. This updates `jtest.data.json` without executing the entire test suite.

Only fall back to a full rebuild when:
- `src/main/java/**` files changed, or
- `pom.xml` changed, or
- the scope of changed test files is too broad to scope a single `-Dtest=` argument.

## Procedure

1. Ensure current working directory is repository root.
2. Determine mode (`both` by default).
3. If data file is fresh for the selected mode, reuse it.
4. If stale or missing, apply the **Scoped Rebuild Rule** first: if only test files changed, do a scoped rebuild; otherwise regenerate based on mode.
5. If mode is `both` (complete-run build phase), copy the generated data file to a reusable baseline snapshot only from the master branch:

```bash
[[ "$(git branch --show-current)" == "master" ]] || {
  echo "Refusing to refresh the baseline from a non-master branch" >&2
  exit 2
}
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

## DTP Build Identity

Before a report is published, resolve one build identity and reuse it for every
Jtest and SOAtest report in that pipeline:

```bash
eval "$(.agents/skills/workflow-config/scripts/resolve-build-id.sh)"
```

`JTEST_BUILD_ID` overrides all defaults. CI uses `BUILD_NUMBER`; local runs use a
UTC timestamp plus the short Git commit. Report commands pass this value with
`-property build.id="$JTEST_BUILD_ID"` and `-property dtp.project="$DTP_PROJECT"`.

## Completion Checks
- `target/jtest/jtest.data.json` exists.
- command(s) for selected mode completed successfully.
- selected mode and scope were respected.
- for `both` mode on `master`, `target/jtest/baseline/jtest.data.json` exists and matches the latest generated data file.
- feature branches consume the existing master baseline and never replace it.

## Decision Rules
- If mode is omitted, use `both`.
- If request is SA-only, use `sa`.
- If request is UT-only or coverage-focused, use `ut`.
- If request is test-creation-only, use `sa`.
- If request combines test creation and immediate UT execution, use `both`.
