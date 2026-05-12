---
name: jtest-static-analysis
description: 'Run Jtest static analysis in parabank with jtestcli. Use when asked to run SA, find violations, check coding standards, or analyze code quality with include/exclude/resource patterns.'
argument-hint: 'Scope: all files, a package, a class name, include/exclude patterns, or a built-in config name'
---

# Jtest Static Analysis Runner

Run and scope Jtest static analysis from the repository root.

## When To Use
- Run static analysis with Jtest (all files or a specific subset).
- Find rule violations in specific classes, packages, or the entire codebase.
- Use a specific built-in or custom test configuration (e.g., security, OWASP, CWE, Recommended Rules).

## Procedure

> **Two steps.** Step 1 compiles and generates `target/jtest/jtest.data.json` — skip it if sources haven't changed. Step 2 runs analysis against the data file and is fast to re-run with different configs or scopes.

1. Ensure current working directory is the repository root.
2. **Generate the data file** (skip if `target/jtest/jtest.data.json` already exists and sources are unchanged):

```bash
mvn compile jtest:jtest -Djtest.skip=true
```

3. **Run static analysis.** Default config (Recommended Rules), all files:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules"
```

   With a different built-in config:

```bash
# CWE Top 25 + On the Cusp 2025 (security-focused)
jtestcli -data target/jtest/jtest.data.json -config "builtin://CWE Top 25 + On the Cusp 2025"

# OWASP Top 10-2025
jtestcli -data target/jtest/jtest.data.json -config "builtin://OWASP Top 10-2025"

# Critical Rules only
jtestcli -data target/jtest/jtest.data.json -config "builtin://Critical Rules"
```

   Scoped to a package or file via `-include`:

```bash
# Package
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -include "com/parasoft/parabank/dao/**"

# Single file
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -include "path:**/LoanProcessorService.java"

# Include with exclusion
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -include "com/parasoft/parabank/**" -exclude "**/test/**"

# Bulk list file (one pattern per line)
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -include include.lst
```

   Scoped using project-relative paths via `-resource`:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -resource "**/src/main/java/com/parasoft/parabank/web/**"
```

4. **Review violations** using `mcp_jtest_get_violations_from_report_file` — never manual XML parsing. Set `path_to_report_xml` to the absolute path of the generated report XML (default: `target/jtest/report.xml`). Call **sequentially** (never in parallel). You can filter by:
   - `severity` — `1` (highest) to `5` (lowest)
   - `rule_id` — specific rule identifier (e.g., `BD.EXCEPT.NP`)
   - `file` — source file name or path fragment

5. **Look up rule details** using `mcp_jtest_get_rule_documentation` for any rule ID surfaced in violations to explain what it detects and how to fix it. Call **sequentially**.

6. Present results as described in [Reporting Results](#reporting-results).

## Available Built-In Configurations

| Config | Use Case |
|---|---|
| `builtin://Recommended Rules` | General best practices (default) |
| `builtin://Critical Rules` | High-severity bugs only |
| `builtin://CWE Top 25 + On the Cusp 2025` | CWE security coverage |
| `builtin://CWE Top 25 2025` | CWE Top 25 only |
| `builtin://OWASP Top 10-2025` | OWASP web security |
| `builtin://OWASP API Security Top 10-2023` | OWASP API security |
| `builtin://Flow Analysis Standard` | Null pointer, resource leaks, etc. |
| `builtin://Flow Analysis Aggressive` | Deeper flow analysis |
| `builtin://Find Memory Problems` | Memory management issues |
| `builtin://Thread Safe Programming` | Concurrency issues |
| `builtin://Code Smells` | Maintainability issues |
| `builtin://CERT for Java` | CERT secure coding |
| `builtin://PCI DSS 4.0` | Payment card compliance |

To list all available configs: `jtestcli -listconfigs builtin`

## Reporting Results

### Summary Table

Present a summary table immediately after `jtestcli` completes:

| Metric | Value |
|---|---|
| Config used | builtin://Recommended Rules |
| Files analyzed | N |
| Total violations | N |
| Severity 1 (Critical) | N |
| Severity 2 (High) | N |
| Severity 3 (Medium) | N |
| Severity 4–5 (Low) | N |

### Violations Table

For each violation, present:

| Severity | Rule ID | File | Line | Message |
|---|---|---|---|---|
| 1 | `BD.EXCEPT.NP` | `AccountService.java` | 84 | Null dereference: `account` may be null |
| 2 | `CODSTA.87` | `LoanDAO.java` | 112 | Method is too long |

Group violations by file when there are many results.

### Rule Explanations

For any Severity 1 or 2 violations (or when explicitly requested), provide a brief explanation:

**`BD.EXCEPT.NP`** — Null Dereference
- Detects: dereferencing a potentially null pointer.
- Fix: add a null check before use.

## Completion Checks
- Step 1 (`mvn compile jtest:jtest -Djtest.skip=true`) completed with BUILD SUCCESS or was skipped because `target/jtest/jtest.data.json` already exists.
- Step 2 (`jtestcli`) completed without errors.
- Requested scope is reflected in the `jtestcli` `-include`/`-exclude`/`-resource` flags.
- Violations were retrieved using `mcp_jtest_get_violations_from_report_file` pointing to `target/jtest/report.xml` — no manual XML parsing.
- Results include a summary table and violations table; rule docs provided for Severity 1–2.

## Decision Rules
- If no config is specified, default to `builtin://Recommended Rules`.
- If the user asks about security, suggest `builtin://CWE Top 25 + On the Cusp 2025` or `builtin://OWASP Top 10-2025`.
- If `target/jtest/jtest.data.json` exists and the user hasn't changed sources, skip Step 1 and go straight to `jtestcli`.
- If user request is ambiguous about scope, ask one clarifier: class/package/path pattern?
- If user gives multiple scopes, combine with repeated `-include` and optional `-exclude`.
- If scope is broad, recommend an include list file for repeatability.

## References
- Jtest docs: Running Static Analysis with Maven (`mvn compile jtest:jtest`)
- Jtest docs: Jtest Goals Reference for Maven (`jtest:jtest` parameters: `jtest.config`, `jtest.include`, `jtest.exclude`, `jtest.resource`, `jtest.skip`)
- Jtest docs: Configuring the Test Scope (pattern syntax)
- Jtest docs: Command Line Exit Codes (`0x21` = SA violations when `-Djtest.fail=true` is used)
