# Changelog

All notable changes documented here.

## [1.0.0] - Initial Release

### Added
- Full project structure with clear module boundaries
- Certificate-based app-only authentication
- 6 collectors: CA policies, directory roles, role assignments, applications, service principals, OAuth2 grants
- Normalized snapshot format with volatile property exclusion
- Baseline creation and validation
- Deterministic drift comparison (added / removed / modified)
- Structured findings with severity, evidence, and remediation
- Policy-as-code engine with 6 rule types and exceptions
- HTML, CSV, and JSON reports
- History tracking with first/last detection and resolution detection
- Safe remediation plans with `-Apply` gate and `-WhatIf` support
- 66 Pester tests, all mocked
- GitHub Actions for tests and scheduled drift checks
- 10 documentation pages

## [0.7.0] - Phase 7: Safe Remediation
### Added
- `New-DriftRemediationPlan` — plan generation
- `Invoke-DriftRemediation` — execution with `-Apply` gate
- `-Mode Plan` in entry point
- 4 new tests

## [0.6.0] - Phase 6: Reports and History
### Added
- `Export-DriftCSV`, `Export-DriftJSON`, `Export-DriftHTML`
- `Add-DriftHistory` — cross-run tracking
- `-Mode Report` in entry point
- 8 new tests

## [0.5.0] - Phase 5: Additional Collectors
### Added
- 6 collectors for roles, apps, service principals, OAuth grants
- `ConvertFrom-DriftRawResource` normalizer
- 10 new tests

## [0.4.0] - Phase 4: Policy-as-Code
### Added
- Policy schema, evaluator, exceptions
- 6 rule types
- 3 sample policy files
- 19 new tests

## [0.3.0] - Phase 3: Drift Engine
### Added
- Comparison engine
- Structured findings
- 9 new tests

## [0.2.0] - Phase 2: Snapshot Engine
### Added
- Graph authentication
- CA policy collector
- Snapshot normalization and export
- Baseline creation
- 8 new tests

## [0.1.0] - Phase 1: Foundation
### Added
- Project structure
- Config schema, logging, validation
- Entry point with mode stubs
- 9 tests
