# Roadmap (Lightweight)

## Current State (Completed)

1. Read safety + read-only MCP tooling
- Safe markdown path resolution under `NOTES_ROOT`
- `GET /mcp/notes` and `GET /mcp/notes/read` contracts with error mapping

2. Patch mutation safety flow
- Patch propose/validate/apply endpoints with constrained unified-diff support
- Conflict handling and rollback on commit failure

3. Git-backed mutation auditability
- Required git commit on accepted patch apply
- Deterministic patch-apply commit metadata

4. Deterministic indexing foundation
- `POST /mcp/index/rebuild` summary contract (`notes_indexed`, `chunks_indexed`)
- Local deterministic note chunking service layer

5. Retrieval query contract (non-embedding baseline)
- Deterministic `GET /mcp/index/query` endpoint over local chunk data
- Explicit query/limit validation with bounded result contract
- Simple lexical scoring + stable tie-break ordering

## Current Focus (Next Slice)

6. Retrieval provider factory extraction
- Move retrieval mode/config selection out of `NotesRetriever` into a dedicated factory
- Preserve lexical-default + semantic fallback behavior while reducing retriever complexity
- Keep `/mcp/index/query` contracts stable during internal wiring cleanup

## Near-Term Follow-ons

7. Shared route helper boundary cleanup
- If helper coupling grows, extract one explicit helper module consumed by route registration
- Keep route module composition deterministic and easy to review

8. Runtime-agent policy mode hardening follow-up
- Add clearer operator-facing policy mode docs/diagnostics and optional startup-time validation surface
- Keep deny/invalid-mode behavior deterministic across environments

## Later (After Contracts Stabilize)

9. Retrieval storage and lifecycle hardening
- Add durable vector/chunk storage lifecycle controls and migration posture
- Preserve MCP query contract while scaling retrieval internals
