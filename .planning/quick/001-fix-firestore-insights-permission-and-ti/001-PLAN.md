# Quick Task Plan 001

## Description
Fix Firestore insights permission-denied and timeout noise on dashboard insights loading.

## Tasks
1. Confirm failing provider/widget path and identify recoverable vs non-recoverable stream errors.
2. Update cycle and insight stream handling to avoid 10s forced timeout failures and gracefully degrade on recoverable Firestore read errors.
3. Run targeted verification (`flutter analyze`, targeted tests if available), then capture results.

## Deliverables
- Code changes in cycle/dashboard providers/widgets
- Verification evidence
