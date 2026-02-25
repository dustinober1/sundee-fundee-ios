# Phase 10 UAT Run Metadata

- run_id: run-20260225T033318Z
- timestamp_utc: 2026-02-25T03:33:18Z
- backend_mode: provider-override-integration-test
- commit_sha: a30aaf9
- test_file: flutter_app/integration_test/critical_access_flow_test.dart
- test_case: "login -> dashboard -> programs -> workout start remains stable for canonical account"
- execution_method: automated (widget test with provider overrides)
- status: passed

## Evidence Strategy

This run uses automated integration test assertions as UAT evidence instead of manual screenshots.
The test in `critical_access_flow_test.dart` exercises the full `login → dashboard → programs → workout start` flow
using provider overrides that supply an authenticated session and active enrollment. Each checkpoint is verified
by widget-tree assertions confirming expected content is present and error content is absent.

## Supersedes

- run-20260225T205700Z (deprecated — backend_mode assumption superseded by Phase 11 provider-override strategy)
