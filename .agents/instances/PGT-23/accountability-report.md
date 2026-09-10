# Accountability Report — PGT-23

Generated during Phase 5 (Release / Hand-off), after all validation evidence
exists. Ties the Jira requirement, the branch, the build identity, and every
quality gate together.

## Identity

- Jira issue: PGT-23 — "Add High-Value Transaction Alerts API (pipeline dry-run, no schema change)"
- Branch: `feature/PGT-23-high-value-transaction-alerts`
- Build ID (`JTEST_BUILD_ID`): `Parabank-Jenkins-local-20260910-PGT-23`
- Commit: HEAD of `feature/PGT-23-high-value-transaction-alerts` (this report is committed together with the implementation in the same commit)
- Author / agent run: GitHub Copilot CLI (autonomous feature-delivery run), committer gtrofimov
- Date: 2026-09-10

## Requirement Traceability

- Feature prompt instance: `.agents/instances/PGT-23/feature-prompt.md`
- Test plan instance: `.agents/instances/PGT-23/test-plan.md`
- Acceptance criteria met: yes
  - `GET /accounts/{accountId}/transactions/highValue?threshold={amount}` returns 200 + JSON array of transactions with amount >= threshold, ordered most-recent-first, for a known account with matches.
  - Missing or invalid `threshold` returns 400.
  - Unknown `accountId` returns 404.
  - No matching transactions returns 200 + empty JSON array.
  - No new domain class/table introduced; reused existing `Transaction` domain object; no UI change; no pagination — all matching the story's locked/out-of-scope decisions.

## Evidence Chain

| Gate | Tool / skill | Report path or DTP link | Result |
|---|---|---|---|
| Static analysis (CWE Top 25 + On the Cusp 2025) | jtest-run-sa | `reports/jtest/sa-final/report.xml` (published to DTP project `Parabank-Jenkins`, build `Parabank-Jenkins-local-20260910-PGT-23`) | 1090 total project violations (full-project scope); 3 new violations attributable to this feature's new code, all severity LOW (sev=4): `HighValueTransactionResource.java:29` and `:60` (`CWE.284.DPPM`, "declare method package-private" — required `public` for JAX-RS, matches existing precedent in `LoanRequestHistoryResource.java`, which has the identical 2 findings), and `JdbcTransactionDao.java:139` (`CWE.400.ABUB`, int autoboxing — matches 3 pre-existing identical findings at lines 75/91/109 in the same file). No new CRITICAL/HIGH findings. Gate passed. |
| Unit tests | jtest-run-ut | `reports/jtest/ut-final/report.xml` (published to DTP) | 273 executed, 273 passed, 0 failed, 0 errors. New/updated tests: `HighValueTransactionResourceTest` (5 methods: found, empty, 404 unknown account, 400 missing threshold, 400 invalid threshold), `JdbcTransactionDaoTest` (+3 methods: found/no-matches/unknown-account), `BankManagerImplTest` (+1 method: passthrough coverage). |
| API / functional tests | soatest-orchestration | `reports/soatest/soatest-Parabank-Jenkins-local-20260910-PGT-23/report.xml` (published to DTP) | Scenario `HighValueTransactionAlerts` (5 tests): `GetHighValueTransactions_Found`, `GetHighValueTransactions_Empty`, `GetHighValueTransactions_MissingThreshold` (400), `GetHighValueTransactions_UnknownAccount` (404), `GetHighValueTransactions_InvalidThreshold` (400). Result: 5/5 passed, 0 failures. |
| Application coverage | jtest-cov-analysis | `reports/jtest/ut-final/coverage.xml` (published to DTP) | Overall project coverage 2688/4236 lines (63%). Touched classes: `HighValueTransactionResource.java` 89.47% overall (new method `getHighValueTransactions` 81.82%, 2 defensive/unreachable branch lines uncovered — same guard-clause pattern as `LoanRequestHistoryResource`); `JdbcTransactionDao.java` 100% overall (new method `getHighValueTransactionsForAccount` 100%); `BankManagerImpl.java` 95.86% overall (new passthrough method `getHighValueTransactionsForAccount` 100%, up from 95.17%/0% before the added `BankManagerImplTest` coverage test). No coverage regression on touched classes. |
| Baseline comparison | jtest-build / jtest-run-sa | N/A — no `target/jtest/baseline/` existed prior to this run (first "both"-mode Jtest run for this repository); see Deviations below. | New-code violations isolated by line-range/precedent comparison instead of an automated baseline diff. |

## Deviations / Waivers

- No pre-existing `target/jtest/baseline/` snapshot existed on `master` before this run (this appears to be the first full `jtest-build both` execution for the repository). The SA "no new CRITICAL/HIGH vs baseline" gate was therefore evaluated by isolating violations introduced by this feature's new/changed code (via line-number cross-reference) and comparing them against equivalent pre-existing patterns elsewhere in the same files, rather than against an automated baseline snapshot. All 3 new findings are LOW severity and match established codebase precedent (see Evidence Chain). No waiver was required since no CRITICAL/HIGH findings were introduced.
- Two SOAtest assertions (`GetHighValueTransactions_Found`, `GetHighValueTransactions_Empty`) initially used an unsupported `$.length()` JSONPath expression for array-count assertions and failed on first execution with a Saxon XPath error. Both were corrected to `count(/root/item)` against the JSON-as-XML representation and re-verified (5/5 passing) before publishing final results — noted here for transparency, not a scope/requirement deviation.

## Pull Request

- PR link: (added after `gh pr create` — see final response metadata block)
- Reviewers requested: none specified in the issue; default repository reviewers apply.

## Jira Hand-off

- Issue transitioned to: not transitioned (workflow-delivery hard rule: do not transition Jira status without explicit approval beyond this delivery run; PR link will be the primary hand-off artifact)
- Comment/link posted: no (not requested in task instructions)
