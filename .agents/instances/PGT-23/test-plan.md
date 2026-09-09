# Test Plan Template

This template defines the validation contract for a feature. It should be generated alongside the feature prompt during the define stage.

## Objective

Validate the new High-Value Transaction Alerts API: `GET /accounts/{accountId}/transactions/highValue?threshold={amount}`
returns matching transactions (amount >= threshold, ordered most recent first), returns 400 for missing/invalid threshold,
404 for an unknown accountId, and 200 + empty array when there are no matches — all without introducing new schema,
domain classes, or CWE Top 25 + On the Cusp 2025 findings.

## Test Scope

### Unit Tests
- target classes or packages: dao/TransactionDao.java, dao/jdbc/JdbcTransactionDao.java (new `getHighValueTransactionsForAccount` query), BankManager/BankManagerImpl (new passthrough method), service/HighValueTransactionResource.java
- test style expected: Not specified in issue — confirm before implementation
- new tests required: unit tests for the new DAO query and the new resource (new code only)
- regression tests required: no regression vs current baseline on touched classes

### Static Analysis
- rule set or config to use: builtin://CWE Top 25 + On the Cusp 2025
- expected baseline comparison: against master via .jtest-baseline
- allowed severity or violation counts: no new CRITICAL/HIGH findings vs baseline
- required security rule set: builtin://CWE Top 25 + On the Cusp 2025

### API / Functional Tests
- end-to-end flows to test: GET highValue for an account with matching transactions, ordered most recent first
- health checks required: Not specified in issue — confirm before implementation
- feature scenarios required: found / empty / unknown-account cases (one SOAtest scenario covering all three)
- negative and failure scenarios required: missing/invalid threshold (400), unknown accountId (404)
- expected status codes and payload behaviors: 200 + JSON array (found), 200 + empty array (no matches), 400 (missing/invalid threshold), 404 (unknown accountId)

### Application Coverage
- component or service scope: TransactionDao/JdbcTransactionDao new query method, BankManager/BankManagerImpl new passthrough method, HighValueTransactionResource
- minimum coverage target: no regression vs current baseline on touched classes (no explicit numeric threshold specified in issue — confirm before implementation)
- report source: jtest-cov-analysis
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

- `.jtest-baseline/` artifacts referenced by `config/jtest-skills.config` were not found in the working tree at intake time; baseline comparisons may need to be regenerated before validation.
- No explicit numeric coverage threshold specified in issue — confirm before implementation.
- Owner/milestone/security-compliance thresholds not specified in issue — confirm before implementation.

## Sign-off

- Feature owner: Not specified in issue — confirm before implementation
- Reviewer: Not specified in issue — confirm before implementation
- Date: Not specified in issue — confirm before implementation
