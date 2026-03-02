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

6. Runtime-agent policy identity extension seam
- Add a narrow identity-context contract for policy evaluation without introducing auth yet
- Preserve existing mode-based enforcement while preparing future identity-aware controls

## Near-Term Follow-ons

7. Runtime config surface parity + boolean parsing contract follow-up
- Keep semantic-provider diagnostics/parsing contracts aligned if parity regressions appear
- Preserve current retrieval behavior while maintaining single-owner config parsing

8. Retrieval storage lifecycle controls (phase 2)
- Add bounded retention/cleanup controls for retrieval artifacts after telemetry baseline lands
- Preserve current artifact schema while introducing explicit lifecycle operations

## Later (After Contracts Stabilize)

10. Retrieval fallback policy extraction
- If semantic/lexical fallback rules expand, extract fallback policy from retriever orchestration
- Preserve query endpoint contract while reducing service branching complexity
