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

6. Index auto-invalidation on patch apply
- Invalidate persisted index artifact after successful note mutation
- Preserve existing `/mcp/patch/apply` response contract and error mapping
- Reduce stale-query risk between mutation and explicit rebuild

## Near-Term Follow-ons

7. Index lifecycle + scale controls
- Incremental indexing triggers
- Optional async rebuild path if note volume grows
- Retrieval quality/performance tuning after semantic baseline is live

8. Route composition modularization
- Reduce `app.rb` endpoint concentration as MCP action set grows
- Keep route wiring explicit while limiting controller-style bloat

## Later (After Contracts Stabilize)

9. Semantic retrieval integration (provider-backed)
- Add concrete embedding provider adapter(s)
- Introduce vector store persistence/query layer
- Keep MCP query contract stable while swapping retrieval internals
