# Test Plan Template

This template defines the validation contract for a feature. It should be generated alongside the feature prompt during the define stage.

## Objective

Validate that the new `GET /accounts/{accountId}/transactions/highValue?threshold={amount}`
endpoint (PGT-23) correctly returns high-value transactions for an account, handles
missing/invalid threshold, unknown account, and empty-result cases, backed by new DAO
and BankManager passthrough logic, with no new static-analysis findings and no coverage
regression on touched classes.

## Test Scope

### Unit Tests
- target classes or packages: `TransactionDao`/`JdbcTransactionDao#getHighValueTransactionsForAccount`, `BankManager`/`BankManagerImpl#getHighValueTransactionsForAccount`, `HighValueTransactionResource`
- test style expected: JUnit + Mockito for the REST resource; JDBC integration test (AbstractParaBankDataSourceTest) for the DAO; in-memory fake (`InMemoryTransactionDao`) passthrough test for BankManagerImpl
- new tests required: yes — `HighValueTransactionResourceTest`, DAO tests in `JdbcTransactionDaoTest`, passthrough test in `BankManagerImplTest`
- regression tests required: none beyond existing suite (no existing behavior changed)

### Static Analysis
- rule set or config to use: builtin://CWE Top 25 + On the Cusp 2025
- expected baseline comparison: against master via `.jtest-baseline`
- allowed severity or violation counts: no new CRITICAL/HIGH findings vs baseline
- required security rule set: builtin://CWE Top 25 + On the Cusp 2025

### API / Functional Tests
- end-to-end flows to test: GET highValue for an account with matching transactions
- health checks required: application reachable via Docker-deployed ParaBank before running SOAtest
- feature scenarios required: found (200 + array), empty (200 + empty array), missing/invalid threshold (400), unknown account (404)
- negative and failure scenarios required: missing threshold (400), invalid threshold (400), unknown accountId (404)
- expected status codes and payload behaviors: 200 + JSON array of Transaction (ordered date DESC, id DESC) on success; 400 on missing/invalid threshold; 404 on unknown account; 200 + empty array on no matches

### Application Coverage
- component or service scope: touched classes only — `TransactionDao`, `JdbcTransactionDao`, `BankManager`, `BankManagerImpl`, `HighValueTransactionResource`
- minimum coverage target: no regression vs current baseline on touched classes
- report source: reports/jtest/ut-final/coverage.xml (fallback to target/jtest/baseline/coverage.xml)
- DTP or CI build identity required: JTEST_BUILD_ID resolved for this run

## Execution Order

1. baseline snapshot or comparison run
2. focused static analysis (jtest-run-sa)
3. focused unit tests (jtest-run-ut)
4. feature/API validation (soatest-orchestration, Docker-deployed ParaBank)
5. application coverage capture (jtest-cov-analysis)
6. final verification against baseline and thresholds

## Acceptance Evidence

The feature is not complete without the following evidence:

- SA report with no new blocking findings
- UT report with pass/fail totals
- API or functional results with success criteria (found/empty/400/404)
- coverage report attached to the same build identifier
- summary of any deferred items or known risks

## Exit Criteria

- all required tests pass
- no unapproved violations remain
- feature acceptance criteria are met
- coverage threshold is reached or explicitly waived with rationale
- reports are published under the same build identity used by the feature pipeline

## Risks / Open Items

- Docker availability for deployment is mandatory per delivery guardrails; if unavailable the run must fail rather than fall back to another deployment method
- No pagination in scope per Jira; large result sets are not addressed by this feature

## Sign-off

- Feature owner: Not specified in issue — confirm before implementation
- Reviewer: Not specified in issue — confirm before implementation
- Date: 2026-09-15
