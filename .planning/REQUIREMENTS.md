# Requirements: v1.2 UAT Access + Onboarding Reliability

**Status:** Drafted 2026-02-24
**Milestone:** v1.2
**Source:** UAT testing report using account `elizabethober@me.com`

## Scope
Milestone v1.2 addresses UAT-blocking access failures in core training surfaces and corrects onboarding resume behavior for returning users with complete profiles.

## In-Scope Requirements

### Firestore Access and Core Training Flows
- [ ] **ACL-01**: User can open Home and load the "Next Workout" card for an active enrollment without `cloud_firestore/permission-denied`.
- [ ] **ACL-02**: User can open Programs and view their enrollment/program data without `cloud_firestore/permission-denied`.
- [ ] **ACL-03**: User can open Workout and load active enrollment/session context without `cloud_firestore/permission-denied`.
- [ ] **ACL-04**: User can start a workout and persist session progress for their active enrollment under authenticated access.
- [ ] **ACL-05**: User receives a recoverable error state (with retry) instead of a broken tab when backend access genuinely fails.

### Onboarding State Consistency
- [ ] **ONB-04**: User with a complete onboarding profile is not prompted with "Resume Onboarding" on login.
- [ ] **ONB-05**: User is prompted to resume onboarding only when required onboarding fields are missing or incomplete.

### Verification and Regression Evidence
- [ ] **QA-01**: User-facing access paths for Home, Programs, and Workout are covered by automated tests validating authenticated read/write behavior.
- [ ] **QA-02**: User acceptance evidence is recorded for login -> dashboard "Next Workout" -> Programs -> Workout start after fixes are deployed.

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
| ACL-01 | 8 | Planned |
| ACL-02 | 8 | Planned |
| ACL-03 | 8 | Planned |
| ACL-04 | 8 | Planned |
| ACL-05 | 8 | Planned |
| ONB-04 | 9 | Planned |
| ONB-05 | 9 | Planned |
| QA-01 | 10 | Planned |
| QA-02 | 10 | Planned |
