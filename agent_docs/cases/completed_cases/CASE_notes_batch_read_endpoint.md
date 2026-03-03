---
case_id: CASE_notes_batch_read_endpoint
created: 2026-03-03
---

# CASE: Notes Batch Read Endpoint

## Slice metadata
- Type: feature
- User Value: runtime-agent and operator workflows can fetch multiple known notes in one request, reducing round-trips and orchestration overhead.
- Why Now: read-path safety and single-note contracts are stable, making this a low-risk user-visible capability slice.
- Risk if Deferred: callers keep issuing repetitive single-note reads, adding latency and tool-call churn in multi-note flows.

## Goal
Add a bounded batch notes-read MCP endpoint that returns `{path, content}` items for multiple note paths while preserving existing safety and error contracts.

## Why this next
- Value: improves throughput for common multi-note retrieval workflows without changing mutation/index behavior.
- Dependency/Risk: builds directly on existing `NotesReader` safety guarantees and MCP error mapping.
- Tech debt note: introduces a second read endpoint; keep request parsing and failure semantics explicit to avoid contract ambiguity.

## Definition of Done
- [ ] New MCP endpoint accepts multiple note paths and returns an ordered array of `{path, content}` results.
- [ ] Request validation is deterministic and bounded (required paths array, max batch size).
- [ ] Path safety behavior matches single-note read (`invalid_path`, `invalid_extension`, `not_found`).
- [ ] README documents endpoint request/response and validation constraints.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_notes_spec.rb spec/services/mcp/notes_batch_read_action_spec.rb`

## Scope
**In**
- Add `POST /mcp/notes/read_batch` (JSON body) with explicit payload validation.
- Add `Mcp::NotesBatchReadAction` service using existing `NotesReader`.
- Add request-level specs for valid batch reads and invalid payload/path contracts.
- Add service-level specs for ordered results and bounded-size handling.
- Update README MCP endpoint docs.

**Out**
- Streaming reads or pagination.
- Partial-success response format (this slice is fail-fast on first invalid/missing path).
- New authorization model beyond existing MCP action policy modes.

## Proposed approach
Create a small `Mcp::NotesBatchReadAction` that takes `paths:` and returns `notes:` preserving request order. Add route wiring under MCP helpers with JSON parsing similar to patch endpoints, but specialized validation for `paths`. Enforce a max batch size constant in the action (or adjacent validator) to keep runtime load bounded. Reuse `NotesReader#read_note` per path so all existing path traversal, extension, and symlink containment rules remain single-sourced. Keep error mapping unchanged by raising existing exceptions through MCP error handling.

## Steps (agent-executable)
1. Add `Mcp::NotesBatchReadAction` with deterministic input validation (`paths` array, non-empty, max size, string entries).
2. Wire `POST /mcp/notes/read_batch` route and parse JSON body for `paths`.
3. Reuse existing MCP error handling so invalid/missing paths map to existing error codes.
4. Add request specs in `spec/mcp_notes_spec.rb` for happy-path, invalid payload shape, oversized batch, and unsafe path entries.
5. Add service specs for ordered output and validation behavior.
6. Document endpoint contract and limits in README.
7. Run targeted specs and ensure existing notes read/list tests remain green.

## Risks / Tech debt / Refactor signals
- Risk: ambiguous partial-failure expectations for multi-path reads. -> Mitigation: codify fail-fast behavior and test it explicitly.
- Debt: introduces another request-payload parser path in routes. -> Mitigation: keep parser logic minimal; consider shared helper only if more JSON-read endpoints arrive.
- Refactor suggestion (if any): if additional batch read variants are added later, extract a dedicated MCP request-schema validator helper.

## Notes / Open questions
- Assumption: max batch size is small and fixed (for example, 20 paths) to bound request cost.
