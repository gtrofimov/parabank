# Test Plan Template

This template defines the validation contract for a feature. It should be generated alongside the feature prompt during the define stage.

## Objective

Verify that the new High-Value Transaction Alerts API (`GET /accounts/{accountId}/transactions/highValue?threshold={amount}`) correctly returns filtered, ordered transactions and handles missing/invalid threshold and unknown account cases, with no new SA findings and no coverage regression on touched classes.

## Test Scope

### Unit Tests
- target classes or packages: TransactionDao / JdbcTransactionDao (new `getHighValueTransactionsForAccount` query), BankManager / BankManagerImpl (new passthrough method), HighValueTransactionResource
- test style expected: new tests for the DAO query and resource only (new code only, per issue scope)
- new tests required: yes — DAO query and resource
- regression tests required: Not specified in issue — confirm before implementation

### Static Analysis
- rule set or config to use: builtin://CWE Top 25 + On the Cusp 2025
- expected baseline comparison: against master via .jtest-baseline
- allowed severity or violation counts: no new CRITICAL/HIGH findings vs baseline
- required security rule set: builtin://CWE Top 25 + On the Cusp 2025

### API / Functional Tests
- end-to-end flows to test: GET .../highValue?threshold=X with matching transactions
- health checks required: Not specified in issue — confirm before implementation
- feature scenarios required: found, empty, unknown-account (one SOAtest scenario covering found / empty / unknown-account cases)
- negative and failure scenarios required: missing/invalid threshold (400), unknown accountId (404)
- expected status codes and payload behaviors:
  - 200 + JSON array of transactions with amount >= threshold, ordered most recent first (transaction date DESC, id DESC), when matches exist
  - 200 + empty array when no matching transactions
  - 400 when threshold is omitted or invalid
  - 404 when accountId is unknown

### Application Coverage
- component or service scope: touched classes only (TransactionDao/JdbcTransactionDao new method, BankManager/BankManagerImpl new method, HighValueTransactionResource)
- minimum coverage target: no regression vs current baseline on touched classes
- report source: jtest-cov-analysis
- DTP or CI build identity required: JTEST_BUILD_ID=Parabank-Jenkins-local-20260916

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

- Owner, target milestone/release, non-goals, security/compliance thresholds, dependencies, and required environment/credentials are not specified in the Jira issue — confirm before implementation
- No pagination and no schema/domain-class changes are locked out-of-scope decisions

## Sign-off

- Feature owner: Not specified in issue — confirm before implementation
- Reviewer: Not specified in issue — confirm before implementation
- Date: Not specified in issue — confirm before implementation
