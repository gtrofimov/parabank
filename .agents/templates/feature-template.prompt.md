# Feature Prompt Template

Use this template to define one feature or story. Generate a feature-specific instance during the define stage and keep it branch-scoped.

## Feature Metadata

- Feature name:
- Branch:
- Owner:
- Target milestone / release:
- Related issue or ticket:

## Business Goal

Describe the user or business value in one or two concise paragraphs.

## Problem Statement

What problem are we solving, and why is the current state insufficient?

## Scope

### In Scope
- 
- 
- 

### Out of Scope
- 
- 
- 

## Non-Goals

- 
- 
- 

## Locked Decisions

List any decisions that are already considered final and must not be changed casually.

- Decision 1:
- Decision 2:
- Decision 3:

## Functional Requirements

1. Requirement 1
2. Requirement 2
3. Requirement 3

## API / Data Contract

Describe the required external behavior, endpoints, payload shape, validation rules, and response semantics.

- Endpoint(s):
- Request contract:
- Response contract:
- Error handling:
- Persistence requirements:
- Ordering or sorting rules:

## Implementation Anchors

List the files, classes, modules, or areas the feature is expected to touch.

- Core code:
- Data layer:
- REST/UI/API layer:
- Tests:
- Documentation:

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Quality Gates

Define the thresholds and validations that must pass before completion.

- Static analysis:
- Unit tests:
- Functional/API tests:
- Coverage threshold:
- Security / compliance thresholds:
- Baseline comparison:

## Risk / Dependencies

- External dependency 1:
- Known risk 1:
- Required environment or credentials:

## Validation Evidence Required

List the artifacts that must exist before the feature is considered complete.

- SA report:
- UT report:
- Functional or API report:
- Coverage report:
- DTP or CI build reference:

## Definition of Done

The feature is complete only when all acceptance criteria are met, all required validation evidence exists, and no blocking quality gate remains unresolved.
