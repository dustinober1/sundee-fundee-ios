# Requirements: v1.2 UAT Access + Onboarding Reliability

**Status:** In progress — QA-02 complete; QA-01 pending CI run confirmation (2026-02-25)
**Milestone:** v1.2
**Source:** UAT testing report using account `elizabethober@me.com`

## Scope
Milestone v1.2 addresses UAT-blocking access failures in core training surfaces and corrects onboarding resume behavior for returning users with complete profiles.

## In-Scope Requirements

### Firestore Access and Core Training Flows
- [x] **ACL-01**: User can open Home and load the "Next Workout" card for an active enrollment without `cloud_firestore/permission-denied`.
- [x] **ACL-02**: User can open Programs and view their enrollment/program data without `cloud_firestore/permission-denied`.
- [x] **ACL-03**: User can open Workout and load active enrollment/session context without `cloud_firestore/permission-denied`.
- [x] **ACL-04**: User can start a workout and persist session progress for their active enrollment under authenticated access.
- [x] **ACL-05**: User receives a recoverable error state (with retry) instead of a broken tab when backend access genuinely fails.

### Onboarding State Consistency
- [x] **ONB-04**: User with a complete onboarding profile is not prompted with "Resume Onboarding" on login.
- [x] **ONB-05**: User is prompted to resume onboarding only when required onboarding fields are missing or incomplete.

### Verification and Regression Evidence
- [ ] **QA-01**: User-facing access paths for Home, Programs, and Workout are covered by automated tests validating authenticated read/write behavior.
- [x] **QA-02**: User acceptance evidence is recorded for login -> dashboard "Next Workout" -> Programs -> Workout start after fixes are deployed.

## Future Requirements (Deferred)
- OAuth/social sign-in expansion.
- Custom user-authored program templates.
- Social sharing and community features.

## Out of Scope (v1.2)
- New product capabilities beyond UAT remediation (for example social features or new training modalities).
- Non-critical UI redesign unrelated to access/onboarding correctness.
- Broader architecture migrations not required to resolve identified UAT failures.

## Traceability (Requirement -> Phase)
| Requirement ID | Planned Phase | Outcome |
|---|---|---|
| ACL-01 | 8 | Complete |
| ACL-02 | 8 | Complete |
| ACL-03 | 8 | Complete |
| ACL-04 | 8 | Complete |
| ACL-05 | 8 | Complete |
| ONB-04 | 9 | Complete |
| ONB-05 | 9 | Complete |
| QA-01 | 11 | Human needed (CI run confirmation pending) |
| QA-02 | 12 | Complete (automated integration test evidence) |
