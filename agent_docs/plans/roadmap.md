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

6. Local index artifact persistence contract
- Persist deterministic rebuild output to a local artifact under `NOTES_ROOT`
- Reuse persisted chunks in query paths to avoid repeated full-note scans
- Keep retrieval contract stable while persistence/storage internals evolve

## Near-Term Follow-ons

7. Patch policy hardening (edge-case diffs)
- Expand malformed/complex diff coverage
- Tighten deterministic conflict/error contracts

8. Retrieval scoring strategy seam
- Isolate lexical scoring policy behind a small strategy boundary
- Reduce churn risk before introducing semantic retrieval providers

## Later (After Contracts Stabilize)

9. Semantic retrieval integration
- Add provider abstraction for embeddings
- Introduce vector-store adapter boundary (swap-friendly by design)
- Keep MCP retrieval contract stable while changing retrieval internals

10. Index lifecycle + scale controls
- Incremental indexing triggers
- Optional async rebuild path if note volume grows
- Retrieval quality/performance tuning after semantic baseline is live
