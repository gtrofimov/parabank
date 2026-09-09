# Test Plan Template

This template defines the validation contract for a feature. It should be generated alongside the feature prompt during the define stage.

## Objective

Validate the new High-Value Transaction Alerts read-only API: `GET /accounts/{accountId}/transactions/highValue?threshold={amount}` returns transactions on the given account with `amount >= threshold`, ordered most recent first, with correct 400/404/200-empty semantics — with no schema change and no regression on touched classes.

## Test Scope

### Unit Tests
- target classes or packages: `com.parasoft.parabank.dao.jdbc.JdbcTransactionDao` (new `getHighValueTransactionsForAccount` query), `com.parasoft.parabank.domain.logic.impl.BankManagerImpl` (new passthrough method), `com.parasoft.parabank.service.HighValueTransactionResource`
- test style expected: JUnit + Mockito, matching `LoanRequestHistoryResourceTest` pattern
- new tests required: DAO query test (found/empty), resource test (found/empty/400/404)
- regression tests required: none beyond existing suite (new code only per issue scope)

### Static Analysis
- rule set or config to use: builtin://CWE Top 25 + On the Cusp 2025
- expected baseline comparison: against master via `.jtest-baseline`
- allowed severity or violation counts: no new CRITICAL/HIGH findings vs baseline
- required security rule set: builtin://CWE Top 25 + On the Cusp 2025

### API / Functional Tests
- end-to-end flows to test: GET highValue endpoint for a known account with matching transactions
- health checks required: Not specified in issue — confirm before implementation
- feature scenarios required: found transactions, empty result set, unknown account, missing/invalid threshold
- negative and failure scenarios required: unknown accountId (404), missing/invalid threshold (400)
- expected status codes and payload behaviors: 200 + JSON array (found/empty ordered most-recent-first), 400 (missing/invalid threshold), 404 (unknown account)

### Application Coverage
- component or service scope: touched classes only (TransactionDao/JdbcTransactionDao, BankManager/BankManagerImpl, HighValueTransactionResource)
- minimum coverage target: no regression vs current baseline on touched classes
- report source: reports/jtest/ut-final/coverage.xml (or target/jtest/baseline/coverage.xml)
- DTP or CI build identity required: Parabank-Jenkins-local-20260909-PGT-23

## Execution Order

1. baseline snapshot or comparison run
2. focused static analysis
3. focused unit tests
4. feature/API validation
5. application coverage capture
6. final verification against baseline and thresholds

## Acceptance Evidence

The feature is not complete without the following evidence:

- SA report with no new blocking findings
- UT report with pass/fail totals
- API or functional results with success criteria
- coverage report attached to the same build identifier
- summary of any deferred items or known risks

## Exit Criteria

- all required tests pass
- no unapproved violations remain
- feature acceptance criteria are met
- coverage threshold is reached or explicitly waived with rationale
- reports are published under the same build identity used by the feature pipeline

## Risks / Open Items

- Owner/milestone not specified in Jira issue
- Security/compliance thresholds beyond CWE Top 25 not specified in issue

## Sign-off

- Feature owner: Not specified in issue — confirm before implementation
- Reviewer: Not specified in issue — confirm before implementation
- Date: 2026-09-09
