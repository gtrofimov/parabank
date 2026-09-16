# Feature Prompt Template

Use this template to define one feature or story. Generate a feature-specific instance during the define stage and keep it branch-scoped.

## Feature Metadata

- Feature name: Add High-Value Transaction Alerts API
- Branch: feature/PGT-23-high-value-transaction-alerts-api
- Owner: Copilot CLI automated delivery run
- Target milestone / release: Not specified in issue — confirm before implementation
- Related issue or ticket: PGT-23

## Business Goal

Support staff need a quick way to review large/suspicious transactions on an account for
fraud and large-payment review, without a new data model.

## Problem Statement

Transaction history exists (TransactionDao#getTransactionsForAccount), but there is no
filtered view for transactions at or above a given amount, and no REST endpoint exposes it.

## Scope

### In Scope
- New `TransactionDao#getHighValueTransactionsForAccount(int accountId, BigDecimal threshold)` query against the existing `Transaction` table (no schema change)
- `BankManager` passthrough method to the new DAO query
- New REST resource `HighValueTransactionResource`: `GET /accounts/{accountId}/transactions/highValue?threshold={amount}`, following the `LoanRequestHistoryResource` pattern
- Unit tests for the new DAO query and resource (new code only)
- One SOAtest scenario covering found / empty / unknown-account cases

### Out of Scope
- No new table or domain class (reuses existing `Transaction`)
- No UI changes
- No pagination

## Non-Goals

- Not specified in issue — confirm before implementation

## Locked Decisions

- Reuse the existing `Transaction` domain object as-is; do not add a new domain class for this feature
- Endpoint path: `/accounts/{accountId}/transactions/highValue`

## Functional Requirements

1. GET .../highValue?threshold=X returns 200 + JSON array of transactions on that account with amount >= X, ordered most recent first
2. Omitting or invalid `threshold` returns 400
3. Unknown accountId returns 404
4. No matching transactions returns 200 + empty array

## API / Data Contract

- Endpoint(s): GET /accounts/{accountId}/transactions/highValue?threshold={amount}
- Request contract: path param `accountId` (int), query param `threshold` (decimal amount)
- Response contract: array of existing `Transaction` JSON representation
- Error handling: 400 for missing/invalid threshold, 404 for unknown account
- Persistence requirements: none (read-only query against existing Transaction table)
- Ordering or sorting rules: transaction date DESC, id DESC

## Implementation Anchors

- Core code: BankManager / BankManagerImpl (new passthrough method)
- Data layer: dao/TransactionDao.java, dao/jdbc/JdbcTransactionDao.java (new query method only)
- REST/UI/API layer: service/HighValueTransactionResource.java
- Tests: new unit tests for DAO query + resource
- Documentation: OpenAPI annotations on the new resource

## Acceptance Criteria

- [ ] Returns matching transactions ordered correctly
- [ ] Returns 400 for missing/invalid threshold
- [ ] Returns 404 for unknown account
- [ ] Returns empty array (200) when no matches
- [ ] No CWE Top 25 + On the Cusp 2025 findings introduced by new code

## Quality Gates

- Static analysis: builtin://CWE Top 25 + On the Cusp 2025, no new CRITICAL/HIGH findings vs baseline
- Unit tests: new tests for the DAO query and resource only
- Functional/API tests: SOAtest scenario covering found/empty/400/404 cases
- Coverage threshold: no regression vs current baseline on touched classes
- Security / compliance thresholds: Not specified in issue — confirm before implementation
- Baseline comparison: against master via .jtest-baseline

## Risk / Dependencies

- External dependency 1: Not specified in issue — confirm before implementation
- Known risk 1: Not specified in issue — confirm before implementation
- Required environment or credentials: DTP_URL, DTP_USER, DTP_PASSWORD (present in environment)

## Validation Evidence Required

- SA report: jtest-run-sa
- UT report: jtest-run-ut
- Functional or API report: SOAtest functional/API report with coverage (soatest-orchestration)
- Coverage report: jtest-cov-analysis
- DTP or CI build reference: JTEST_BUILD_ID resolved for this run

## Definition of Done

Complete only when all acceptance criteria are met, all required validation evidence exists,
and no blocking quality gate remains unresolved. This issue is a local pipeline dry-run to
validate the CICD workflow before PGT-22.
