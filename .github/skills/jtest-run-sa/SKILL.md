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
2. Pre-heat MCP once per session before SA.
   - Jtest MCP warm-up: run one minimal Jtest MCP action.
   - DTP MCP warm-up: run one DTP info call, then one DTP build/metadata call.
   - Keep calls sequential.
3. Ensure `target/jtest/jtest.data.json` is present and current for SA.
   - If missing or stale, run `jtest-build` with mode `sa` or `both` first.
4. Run static analysis. Default config:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules"
```

   Security-focused examples:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://CWE Top 25 + On the Cusp 2025"
jtestcli -data target/jtest/jtest.data.json -config "builtin://OWASP Top 10-2025"
```

   Scope examples:

```bash
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -include "com/parasoft/parabank/dao/**"
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -include "path:**/LoanProcessorService.java"
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -include "com/parasoft/parabank/**" -exclude "**/test/**"
jtestcli -data target/jtest/jtest.data.json -config "builtin://Recommended Rules" -resource "**/src/main/java/com/parasoft/parabank/web/**"
```

5. Retrieve violations using `mcp_jtest_get_violations_from_report_file` (sequential calls only).
6. Retrieve rule details for important findings using `mcp_jtest_get_rule_documentation` (sequential calls only).

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
- violations were obtained via Jtest tooling, not manual XML parsing.

## Decision Rules
- Default config: `builtin://Recommended Rules`.
- For security asks: prefer `builtin://CWE Top 25 + On the Cusp 2025` or `builtin://OWASP Top 10-2025`.
- If scope is ambiguous, ask one clarifier: class, package, or path pattern.
