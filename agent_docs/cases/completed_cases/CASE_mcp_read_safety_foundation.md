---
case_id: CASE_mcp_read_safety_foundation
created: 2026-02-19
---

# CASE: MCP Read Safety Foundation

## Goal
Implement a safe, test-backed read-only MCP slice so the runtime agent can list/read markdown notes without escaping `NOTES_ROOT`.

## Why this next
- Value: turns the current scaffold into a usable and safe vertical slice.
- Dependency/Risk: all later patch/apply and git-commit flows depend on trustworthy path handling.
- Tech debt note: pays down core safety debt early and reduces risky rewrites later.

## Definition of Done
- [ ] Add a path safety utility that normalizes untrusted paths, enforces containment under `NOTES_ROOT`, and allows only `.md` files.
- [ ] Add read-only MCP endpoints (e.g., list notes + read note) that route all file access through the safety utility.
- [ ] Return explicit 4xx errors for invalid paths/extensions and 404 for missing files.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec` passes with new endpoint and safety specs.

## Scope
**In**
- Path normalization and validation logic.
- Read-only note operations for markdown files.
- Endpoint request/response contract and error handling.
- RSpec coverage for edge cases (`../`, absolute paths, non-md files, missing file).

**Out**
- Any write/mutation endpoint.
- Git commit integration.
- Indexing/RAG pipeline.

## Proposed approach
Introduce a small service object (for example `app/services/safe_notes_path.rb`) that accepts untrusted relative input and returns a validated absolute path or typed error. Add read-only MCP routes in Sinatra that call a thin notes read service and map errors to stable JSON responses. Keep the API intentionally small (list/read only) to constrain complexity. Back the slice with focused specs that create temp fixtures under a test notes root and assert traversal rejection and extension enforcement.

## Steps (agent-executable)
1. Add specs defining desired safety behavior for path validation and `.md` enforcement.
2. Implement a path safety service that resolves paths under `settings.notes_root` and rejects traversal/invalid extension.
3. Add note read/list helpers that only consume validated paths.
4. Add MCP read-only endpoints and JSON error mapping.
5. Add request specs for happy path and rejection paths.
6. Run full RSpec suite in container and adjust for deterministic behavior.
7. Update docs (`README.md`) with endpoint contract and safety constraints.

## Risks / Tech debt / Refactor signals
- Risk: subtle path normalization edge cases across platforms. → Mitigation: enforce absolute-path containment checks and explicit spec matrix.
- Debt: may keep endpoint schema lightweight before formal MCP schema contracts. 
- Refactor suggestion (if any): if more than 3-4 endpoints are added, extract route handlers from `app.rb` into modular service wiring.

## Notes / Open questions
- Assumption: endpoint naming can remain provisional as long as behavior is stable and tested.
- Open question: adopt strict MCP method envelope now, or keep plain HTTP routes and adapt later?
