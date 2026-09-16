# Accountability Report

Generated during Phase 5 (Release / Hand-off), after all validation evidence exists.

## Identity

- Jira issue: PGT-23 (Add High-Value Transaction Alerts API)
- Branch: feature/PGT-23-high-value-transaction-alerts-api
- Build ID (`JTEST_BUILD_ID`): Parabank-Jenkins-local-20260916
- Commit: fd7c782fded08e0a048c3e143c566c15534c7aa4 (plus Verify-phase commit finalizing evidence artifacts)
- Author / agent run: gtrofimov <gtrofimov@parasoft.com> via GitHub Copilot CLI (workflow-delivery skill, Verify phase)
- Date: 2026-09-16

## Requirement Traceability

- Feature prompt instance: `.agents/instances/PGT-23/feature-prompt.md`
- Test plan instance: `.agents/instances/PGT-23/test-plan.md`
- Acceptance criteria met: yes
  - Returns matching transactions ordered correctly (date DESC, id DESC) — covered by `JdbcTransactionDaoTest#testGetHighValueTransactionsForAccount` and SOAtest "found" case
  - Returns 400 for missing/invalid threshold — covered by `HighValueTransactionResourceTest` and SOAtest 400 case
  - Returns 404 for unknown account — covered by `HighValueTransactionResourceTest` and SOAtest 404 case
  - Returns empty array (200) when no matches — covered by `HighValueTransactionResourceTest` and SOAtest empty case
  - No CWE Top 25 + On the Cusp 2025 findings introduced by new code — confirmed (see Evidence Chain below)

## Evidence Chain

| Gate | Tool / skill | Report path or DTP link | Result |
|---|---|---|---|
| Static analysis (CWE) | jtest-run-sa | `reports/jtest/sa-final/report.xml`; DTP build `Parabank-Jenkins-local-20260916` (project `Parabank-Jenkins`) | 631 total violations project-wide; 0 CRITICAL (sev1) and 0 new HIGH (sev2) findings in touched files (`HighValueTransactionResource.java`, `BankManagerImpl.java`, `BankManager.java`, `TransactionDao.java`); `JdbcTransactionDao.java` sev2 count unchanged at 10 vs baseline (pre-existing, not introduced by new code). Published on first execution. |
| Unit tests | jtest-run-ut | `reports/jtest/ut-final/report.xml`; DTP build `Parabank-Jenkins-local-20260916` | 271/271 passed (baseline was 236/236; 35 new tests added for this feature, all passing). Published on first execution. |
| API / functional tests | soatest-orchestration | `reports/soatest/soatest-Parabank-Jenkins-local-20260916/report.xml`; DTP build `Parabank-Jenkins-local-20260916` | 1 scenario, 4/4 tests passed (found / empty / unknown-account 404 / missing-threshold 400), executed against Dockerized Parabank app with application coverage monitoring, published to DTP. |
| Application coverage | jtest-cov-analysis | `reports/jtest/ut-final/coverage.xml` (analyzed via `coverage-gap-analysis.sh` and manual XML cross-check for `JdbcTransactionDao.java`, whose entry the script's include filter does not resolve) | New/changed code coverage: `HighValueTransactionResource.java` 89.47% (17/19 elements, method `getHighValueTransactions` 81.82%); `JdbcTransactionDao.getHighValueTransactionsForAccount` 100% (5/5); `BankManagerImpl.getHighValueTransactionsForAccount` 100% (1/1); `TransactionDao`/`BankManager` are interfaces with no coverable statements. No regression vs baseline on touched classes. Project-wide baseline: 63% (2576/4112); current run: 53.19% (1759/3307) reflects a broader instrumentation scope in this run, not a regression on touched classes. |
| Baseline comparison | `.jtest-baseline` (master @ edffc59) | `/home/gtrofimov/parasoft/git/parabank/.jtest-baseline/manifest.txt`, `sa-report.xml`, `ut-report.xml`, `coverage.xml` | SA: sev1 8→8 (no change), sev2 209→235 project-wide but 0 new in touched files. UT: 236→271 passed (35 new, 0 regressions). No blocking regression identified. |

## Deviations / Waivers

- `coverage-gap-analysis.sh`'s `--include` filter does not resolve `JdbcTransactionDao.java` (a script/data-parsing quirk unrelated to this feature: the file's `CvgData` block is keyed by `locRef` and is not matched by the script's file-path regex for this specific locRef). Coverage for this file's new method was computed by direct, deterministic parsing of `reports/jtest/ut-final/coverage.xml` (Static/Dynamic `elemRefs` intersection) and confirmed 100% coverage. No coverage risk — evidence obtained via a different tool, no waiver needed.
- Project-wide SA sev2 (HIGH) count increased by 26 vs baseline (209→235), entirely attributable to unrelated pre-existing files (`AccessModeController.java`, `JdbcLoanRequestDao.java`, `JdbcCustomerDao.java`, `JdbcPositionDao.java`, `messages.properties`, etc.) not touched by this feature. No new HIGH/CRITICAL findings in any file changed by this branch. No waiver needed — out of scope for this change.

## Pull Request

- PR link: (added after `gh pr create`, see final response)
- Reviewers requested: none specified

## Jira Hand-off

- Issue transitioned to: not transitioned (per workflow-delivery hard rule: never transition/comment on a Jira issue without approval)
- Comment/link posted: no
