# Test Plan Template

This template defines the validation contract for a feature. It should be generated alongside the feature prompt during the define stage.

## Objective

Validate the new read-only `GET /accounts/{accountId}/transactions/highValue?threshold={amount}`
endpoint (PGT-23): it must return matching transactions ordered correctly,
handle missing/invalid threshold and unknown account errors, and return an
empty array when there are no matches — all without a schema change and
without regressing existing coverage or introducing new CWE Top 25 + On the
Cusp 2025 static analysis findings.

## Test Scope

### Unit Tests
- target classes or packages: BankManager / BankManagerImpl (new passthrough method), dao/TransactionDao.java, dao/jdbc/JdbcTransactionDao.java (new `getHighValueTransactionsForAccount` query), service/HighValueTransactionResource.java
- test style expected: new unit tests for the DAO query and resource (new code only)
- new tests required: yes — DAO query method and REST resource
- regression tests required: Not specified in issue — confirm before implementation

### Static Analysis
- rule set or config to use: builtin://CWE Top 25 + On the Cusp 2025
- expected baseline comparison: against master via .jtest-baseline
- allowed severity or violation counts: no new CRITICAL/HIGH findings vs baseline
- required security rule set: builtin://CWE Top 25 + On the Cusp 2025

### API / Functional Tests
- end-to-end flows to test: GET /accounts/{accountId}/transactions/highValue?threshold={amount} following the LoanRequestHistoryResource pattern
- health checks required: Not specified in issue — confirm before implementation
- feature scenarios required: found (matching transactions, ordered most recent first), empty (no matching transactions), unknown account
- negative and failure scenarios required: missing/invalid threshold (400), unknown accountId (404)
- expected status codes and payload behaviors: 200 + JSON array of Transaction objects (found/empty), 400 for missing/invalid threshold, 404 for unknown accountId

### Application Coverage
- component or service scope: touched classes only (BankManager/BankManagerImpl, TransactionDao/JdbcTransactionDao, HighValueTransactionResource)
- minimum coverage target: no regression vs current baseline on touched classes
- report source: jtest-cov-analysis
- DTP or CI build identity required: Parabank-Jenkins-local-20260909-PGT-23 (JTEST_BUILD_ID)

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

- No .jtest-baseline/ artifacts were found in the repo at define time — baseline comparisons will need to be produced/refreshed before validation.
- Owner, target milestone, non-goals, security/compliance thresholds, external dependencies, and required environment/credentials were not specified in the Jira issue — confirm before implementation.

## Sign-off

- Feature owner: Not specified in issue — confirm before implementation
- Reviewer: Not specified in issue — confirm before implementation
- Date: Not specified in issue — confirm before implementation
