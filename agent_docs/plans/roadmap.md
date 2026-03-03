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

6. Retrieval query path prefix filter
- Add optional folder/path scoping to `GET /mcp/index/query` while preserving current default query behavior
- Improve retrieval relevance for multi-domain note trees without requiring client-side post-filtering

## Near-Term Follow-ons

7. Notes batch-read capability
- Add a bounded batch note read endpoint for known paths to reduce per-note request overhead in tool/runtime flows
- Keep existing single-note read contract unchanged

8. Retrieval query response quality enhancements
- Add optional snippet-location metadata to query results for better grounding and downstream UX
- Preserve deterministic sorting and existing query contract defaults

## Later (After Contracts Stabilize)

10. Retrieval quality and policy extensions
- Add richer ranking/selection controls only after fallback policy ownership is explicit
- Preserve deterministic request contracts while evolving retrieval internals
