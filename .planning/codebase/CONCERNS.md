# Known Concerns & Open Questions

- **Firebase dependency gating**: some logic requires `ENABLE_FIREBASE`; ensure guest mode remains stable.
- **Migration path**: legacy data migration service indicates prior schema; keep migration code up to date.
- **Platform quirks**: iOS/Android setup with Firebase may require occasional manual updates (Google services files not committed).
- **Scalability**: Firestore rules and indexes (`firestore.rules`, `firestore.indexes.json`) need review when schema changes.
- **Testing gaps**: no integration tests; adding e2e on web/mobile could improve confidence.
- **CI details**: not visible; confirm build/release pipelines exist and update docs as needed.

These are a starting point; revisit after further development.
