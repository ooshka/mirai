# Tech Debt Log

## 2026-02-19

### Observed signals
- App currently concentrates all behavior in `app.rb`; boundaries for controllers/services are not yet established.
- No filesystem safety primitives exist yet despite architecture requiring path hardening.
- Test coverage is minimal (health endpoint only), making regression risk high as MCP surface grows.

### Debt posture for next slice
- Debt paid down: establish reusable path validation service and focused endpoint specs.
- Debt potentially added: MCP schema may remain minimal/hand-rolled initially.
- Follow-up refactor signal: if endpoint count grows, split route handlers into modular service objects early.

## 2026-02-27

### Observed signals
- Read-path safety is in place, but mutation flow is still missing, leaving architecture incomplete for runtime knowledge evolution.
- `app.rb` now carries multiple endpoint responsibilities and will become harder to reason about once mutation paths are added.
- No diff parsing/patch validation abstraction exists yet; implementing directly in routes would create fragile, hard-to-test logic.

### Debt posture for next slice
- Debt paid down: introduces explicit patch validation/apply services and test-backed mutation error contracts.
- Debt potentially added: initial patch grammar will likely be intentionally narrow (single-file markdown diffs).
- Refactor signal: if endpoint count or service wiring keeps growing, extract route orchestration from `app.rb` into focused endpoint modules.

### Planner follow-up (next slice)
- Debt paid down next: reduce route-layer duplication by extracting MCP endpoint orchestration and shared error mapping from `app.rb`.
- Debt potentially added: temporary adapter/wrapper objects may introduce a thin indirection layer before broader modular route structure is established.
- Refactor signal: if additional MCP tools are introduced after this slice, move Sinatra route wiring into separate route files/modules to avoid a second controller-style bottleneck.

## 2026-02-27 (post-orchestration planning pass)

### Observed signals
- Patch apply currently commits with a generic subject line that omits explicit MCP operation context.
- As mutation capabilities expand, commit history readability and incident debugging will depend on stable, descriptive metadata.
- Commit message formatting appears flow-local; without a small policy seam, future tool-specific subjects are likely to drift.

### Debt posture for next slice
- Debt paid down next: establish deterministic commit metadata for patch apply so mutation history remains auditable.
- Debt potentially added: metadata remains encoded in plain commit subjects (not structured trailers/events) for now.
- Refactor signal: if multiple mutation tools need distinct commit semantics, introduce a shared commit-message policy object instead of endpoint-local string construction.

## 2026-02-27 (indexing foundation planning pass)

### Observed signals
- Mutation safety and commit auditing are now in place, but there is no indexing/retrieval path yet despite roadmap intent.
- Current code has no shared chunking/indexing policy, so retrieval work would otherwise start with ad hoc behavior.
- `app.rb` is still manageable after orchestration hardening, but adding retrieval endpoints without service-first indexing would reintroduce route-level complexity risk.

### Debt posture for next slice
- Debt paid down next: establish deterministic indexing/chunking contracts in services and request specs before retrieval/provider integration.
- Debt potentially added: initial indexing may remain synchronous and summary-only (no persistence/query), which is acceptable for this bounded slice.
- Refactor signal: if indexing capabilities expand (rebuild, incremental update, query, metadata filters), introduce a dedicated indexing policy/builder object to keep endpoint actions thin.

## 2026-02-27 (retrieval contract planning pass)

### Observed signals
- Deterministic indexing exists, but there is still no retrieval query endpoint for runtime-agent consumption.
- `NotesIndexer` currently materializes full chunk content for counting; this is acceptable now but may become costly once query traffic increases.
- API surface is growing (`notes`, `patch`, `index rebuild`), so retrieval should continue the service-first endpoint pattern to avoid route-level complexity drift.

### Debt posture for next slice
- Debt paid down next: establish deterministic retrieval API and ranking contract before embedding/vector provider decisions.
- Debt potentially added: lexical scoring quality will be limited compared with semantic retrieval, but this isolates contract risk while keeping implementation local.
- Refactor signal: if retrieval ranking heuristics expand, introduce a scoring strategy seam to avoid a monolithic retriever implementation.
