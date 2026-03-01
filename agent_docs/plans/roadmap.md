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

6. Route wiring module extraction
- Move Sinatra route definitions out of `app.rb` into explicit route modules
- Preserve current MCP/health/config contracts while reducing composition complexity
- Keep service boundaries stable for upcoming runtime-agent and retrieval work

## Near-Term Follow-ons

7. Runtime-agent action policy layer
- Add explicit allow/deny policy seams for runtime tool actions before autonomy expansion
- Keep policy enforcement centralized and testable rather than route-local

8. Semantic retrieval runtime integration
- Wire provider-backed retrieval behind existing query contract
- Keep lexical fallback path available while semantic path stabilizes

## Later (After Contracts Stabilize)

9. Retrieval storage and lifecycle hardening
- Add durable vector/chunk storage lifecycle controls and migration posture
- Preserve MCP query contract while scaling retrieval internals
