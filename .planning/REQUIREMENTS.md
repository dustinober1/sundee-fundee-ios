# Milestone v1.1 Requirements

## Scope
Milestone v1.1 focuses on onboarding persistence, injury-aware planning, and enrollment cancellation safety.

## In-Scope Requirements

### Onboarding Persistence
- [x] **ONB-01**: User can complete onboarding once and skip onboarding on subsequent logins when completion is already recorded.
- [x] **ONB-02**: User can review and edit previously saved onboarding answers from settings/profile without rerunning full onboarding.
- [x] **ONB-03**: User can sign in on a new device and receive the same onboarding-complete behavior based on account data.

### Injury Profile and Adaptation
- [x] **INJ-01**: User can record current injury context (injured area and basic status) that is stored with their profile.
- [x] **INJ-02**: User can update or clear injury context, and subsequent plan generation reflects the latest saved state.
- [x] **INJ-03**: User receives alternate exercises when planned movements conflict with saved injury context.
- [x] **INJ-04**: User receives recovery-support additions in generated plans when injury context is present.
- [x] **INJ-05**: User sees an explicit disclaimer stating generated guidance is not a substitute for medical advice or physical therapy.

### Plan Enrollment Lifecycle
- [ ] **PLN-01**: User can cancel an enrolled plan from the app without deleting completed workout history.
- [ ] **PLN-02**: User sees clear enrollment status after cancellation (for example, canceled/inactive state).
- [ ] **PLN-03**: User can start a new plan after cancellation without data corruption from prior enrollment state.

## Future Requirements (Deferred)
- OAuth/social sign-in expansion.
- Custom user-authored program templates.
- Social sharing and community features.

## Out of Scope (v1.1)
- Medical diagnosis workflows or treatment prescriptions.
- Automatic injury recovery clearance decisions.
- Real-time coaching or clinician integration.

## Traceability (Requirement -> Phase)
| Requirement ID | Planned Phase |
|---|---|
| ONB-01 | 5 |
| ONB-02 | 5 |
| ONB-03 | 5 |
| INJ-01 | 5 |
| INJ-02 | 5 |
| INJ-03 | 6 |
| INJ-04 | 6 |
| INJ-05 | 6 |
| PLN-01 | 7 |
| PLN-02 | 7 |
| PLN-03 | 7 |
