# Test Plan Template

This template defines the validation contract for a feature. It should be generated alongside the feature prompt during the define stage.

## Objective

Describe the feature outcome under test and the expected evidence that proves it works.

## Test Scope

### Unit Tests
- target classes or packages:
- test style expected:
- new tests required:
- regression tests required:

### Static Analysis
- rule set or config to use:
- expected baseline comparison:
- allowed severity or violation counts:
- required security rule set:

### API / Functional Tests
- end-to-end flows to test:
- health checks required:
- feature scenarios required:
- negative and failure scenarios required:
- expected status codes and payload behaviors:

### Application Coverage
- component or service scope:
- minimum coverage target:
- report source:
- DTP or CI build identity required:

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

- 
- 
- 

## Sign-off

- Feature owner:
- Reviewer:
- Date:
