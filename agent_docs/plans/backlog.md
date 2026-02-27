# Backlog

## Next 3 Candidate Slices

1. MCP Route Orchestration Hardening (selected)
- Value: reduces growing endpoint complexity in `app.rb` and keeps read/mutation contracts stable as new tooling is added.
- Size: ~0.5-1 day.

2. Git Commit Metadata Enrichment
- Value: improves auditability by attaching explicit operation metadata (tool/action context) to patch commits.
- Size: ~0.5-1 day.

3. Patch Policy Hardening (edge cases + deterministic conflict contract)
- Value: hardens parser/apply behavior for malformed hunks and less common diff shapes before expanding mutation scope.
- Size: ~1 day.
