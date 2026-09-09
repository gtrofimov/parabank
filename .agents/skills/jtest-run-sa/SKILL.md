---
name: jtest-run-sa
description: 'Run Jtest static analysis only. Use when asked to execute SA, find rule violations, or check coding/security standards.'
argument-hint: 'Scope: all files, a package, a class name, include/exclude patterns, and optional SA config name'
---

# Jtest Run SA

Run static analysis from the repository root.

## When To Use
- Execute static analysis only.
- Re-run analysis quickly against an existing data file with a different scope or config.

## Procedure

1. Ensure current working directory is the repository root.
2. Ensure `target/jtest/jtest.data.json` is present and current for SA.
   - If missing or stale, run `jtest-build` with mode `sa` first.
   - Use mode `both` only when the same request also includes UT preparation.
3. Run static analysis. Default config:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://CWE Top 25 + On the Cusp 2025"
```

   Scope examples:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://CWE Top 25 + On the Cusp 2025" -include "com/parasoft/parabank/dao/**"
jtestcli -data target/jtest/jtest.data.json -config "builtin://CWE Top 25 + On the Cusp 2025" -include "path:**/LoanProcessorService.java"
jtestcli -data target/jtest/jtest.data.json -config "builtin://CWE Top 25 + On the Cusp 2025" -include "com/parasoft/parabank/**" -exclude "**/test/**"
jtestcli -data target/jtest/jtest.data.json -config "builtin://CWE Top 25 + On the Cusp 2025" -resource "**/src/main/java/com/parasoft/parabank/web/**"
```

4. Retrieve violations using `mcp_jtest_get_violations_from_report_file` (sequential calls only).
5. Retrieve rule details for prioritized findings using `mcp_jtest_get_rule_documentation` (sequential calls only):
   - include all CRITICAL and HIGH severity findings
   - if no CRITICAL/HIGH findings exist, include the top 5 findings by rule frequency

For a DTP-published final report, publish on the first Jtest execution. Do not
rerun analysis only to publish. Use the same build ID as UT and application
coverage:

```bash
.agents/skills/workflow-config/scripts/publish-jtest.sh \
   sa "builtin://CWE Top 25 + On the Cusp 2025" reports/jtest/sa-final target/jtest/jtest.data.json
```

## Reporting

Provide:
- config used
- files analyzed
- total violations
- severity breakdown
- top violations table (severity, rule, file, line, message)

## Completion Checks
- `jtestcli` completed without errors.
- requested scope/config is reflected in the final command.
- violations were obtained via approved Jtest tooling (MCP or allowed shell/custom parser path), and parser path was reported.

## Decision Rules
- Default config: `builtin://CWE Top 25 + On the Cusp 2025`.
- Use the repository-configured CWE profile for all SA runs unless the user explicitly requests another configuration.
- If scope is ambiguous, ask one clarifier: class, package, or path pattern.
- Important findings threshold: all CRITICAL/HIGH findings, otherwise top 5 by rule frequency.
