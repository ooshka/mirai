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

## In Progress (Next Slice)

5. Retrieval query contract (non-embedding baseline)
- Add deterministic MCP query endpoint over local chunk data
- Include explicit query/limit validation and bounded results
- Use simple lexical scoring + stable tie-break ordering

## Near-Term Follow-ons

6. Local index artifact persistence contract
- Define how rebuilt index/chunks are stored locally (no external vector DB yet)
- Reduce repeated full-note scans for query paths

7. Patch policy hardening (edge-case diffs)
- Expand malformed/complex diff coverage
- Tighten deterministic conflict/error contracts

## Later (After Contracts Stabilize)

8. Semantic retrieval integration
- Add provider abstraction for embeddings
- Introduce vector-store adapter boundary (swap-friendly by design)
- Keep MCP retrieval contract stable while changing retrieval internals

9. Index lifecycle + scale controls
- Incremental indexing triggers
- Optional async rebuild path if note volume grows
- Retrieval quality/performance tuning after semantic baseline is live
