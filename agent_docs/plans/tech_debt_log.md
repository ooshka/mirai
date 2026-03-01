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

## 2026-02-28 (index artifact persistence planning pass)

### Observed signals
- Retrieval contract is implemented, but `NotesRetriever` currently triggers fresh indexing per query, causing avoidable repeated full-note scans.
- No persisted local index artifact exists yet, so query performance and behavior depend on synchronous filesystem traversal each request.
- Index lifecycle behavior (rebuild vs query reuse) is implicit, increasing risk of ad hoc caching logic in route/action layers.

### Debt posture for next slice
- Debt paid down next: establish a deterministic local index artifact contract and retrieval-path reuse boundary.
- Debt potentially added: artifact invalidation remains manual (rebuild-driven) until explicit lifecycle controls are introduced.
- Refactor signal: if lifecycle actions grow (rebuild/load/invalidate/metrics), extract an index lifecycle orchestrator to prevent service/action sprawl.

## 2026-02-28 (patch policy hardening planning pass)

### Observed signals
- Patch mutation contracts are in place, but validator coverage for unified-diff edge markers remains narrow.
- `PatchValidator` and `PatchApplier` currently rely on tightly coupled line-prefix assumptions that may not hold for all agent-generated diffs.
- Without explicit edge-case policy tests, small parser tweaks risk silent drift in MCP mutation behavior.

### Debt posture for next slice
- Debt paid down next: codify deterministic accept/reject contracts for edge-case diff lines and keep endpoint error mapping stable.
- Debt potentially added: patch grammar remains intentionally partial (single-file modifications only), deferring broader git diff compatibility.
- Refactor signal: if patch syntax support continues to expand, split parsing into a dedicated patch parser object to reduce validator complexity growth.

## 2026-02-28 (retrieval scoring seam planning pass)

### Observed signals
- `NotesRetriever` currently owns tokenization, scoring policy, sorting, and index-source selection in one class.
- Lexical scoring behavior is currently simple and deterministic, but upcoming semantic retrieval work will likely require policy swaps.
- Without a scoring seam, adding alternate ranking logic risks growing conditional complexity and weakly isolated tests.

### Debt posture for next slice
- Debt paid down next: introduce a small scoring strategy boundary to preserve deterministic query behavior while reducing retriever coupling.
- Debt potentially added: initial strategy interface may be minimal and focused on current lexical needs only.
- Refactor signal: if retrieval policy variants multiply (hybrid, boosting, metadata-aware), promote strategy selection into an explicit policy/config object.

## 2026-02-28 (index lifecycle controls planning pass)

### Observed signals
- Index artifact persistence now exists, but lifecycle state is implicit and only indirectly observable via rebuild/query side effects.
- There is no bounded invalidation path, so stale artifact handling depends on manual filesystem intervention outside MCP contracts.
- As retrieval internals evolve, unclear lifecycle semantics increase risk of ad hoc state handling across routes/services.

### Debt posture for next slice
- Debt paid down next: add explicit lifecycle boundaries for index status and manual invalidation with deterministic MCP responses.
- Debt potentially added: lifecycle controls remain manual/synchronous and may not scale operationally without follow-on automation.
- Refactor signal: if lifecycle operations expand (status, invalidate, rebuild, freshness policy), introduce a dedicated lifecycle coordinator instead of distributing logic across actions/routes.

## 2026-03-01 (patch parser boundary extraction planning pass)

### Observed signals
- `PatchValidator` currently mixes unified-diff syntax parsing and mutation safety policy, increasing coupling inside a critical path.
- Patch edge-case hardening has expanded parser-like logic in validator methods, making future grammar changes riskier to reason about.
- `PatchApplier` depends on validator output shape; without an explicit parsing boundary, parser changes can unintentionally affect apply behavior.

### Debt posture for next slice
- Debt paid down next: separate syntax extraction from policy enforcement by introducing a dedicated parser service and keeping validator ownership of safety rules.
- Debt potentially added: parser remains intentionally narrow (single-file unified diff subset) and may need controlled expansion later.
- Refactor signal: if supported diff shapes grow beyond current hunk forms, centralize fixture-based parser contract tests to prevent incremental rule drift.

## 2026-03-01 (semantic retrieval provider seam planning pass)

### Observed signals
- Retrieval query contracts are stable, but ranking internals remain effectively lexical-first and tightly connected to retriever orchestration.
- The project explicitly targets provider portability, yet retrieval currently has no first-class provider abstraction boundary.
- Without a seam now, future embedding/vector integration is likely to introduce endpoint-adjacent branching and broader regression risk.

### Debt posture for next slice
- Debt paid down next: establish a small retrieval-provider boundary so future semantic adapters can be swapped with minimal contract churn.
- Debt potentially added: initial provider interface may be intentionally narrow and lexical-shaped, requiring expansion once semantic signals are introduced.
- Refactor signal: if provider selection paths multiply, centralize strategy/policy selection in service layer instead of route/action classes.

## 2026-03-01 (index auto-invalidation on patch apply planning pass)

### Observed signals
- Index artifact lifecycle controls exist, but patch mutation success currently does not affect artifact freshness automatically.
- This leaves a stale-data window where `/mcp/index/query` can serve outdated chunks until manual invalidation/rebuild occurs.
- Mutation and retrieval lifecycle logic are currently separate, increasing risk of correctness drift as mutation traffic grows.

### Debt posture for next slice
- Debt paid down next: connect successful patch apply to deterministic index invalidation in MCP orchestration.
- Debt potentially added: invalidation remains a delete-only lifecycle reaction (no automatic rebuild) in this slice.
- Refactor signal: if more mutation actions are introduced, centralize post-mutation index lifecycle hooks in a shared coordinator.

## 2026-03-01 (index freshness status signal planning pass)

### Observed signals
- Automatic invalidation on patch apply reduces stale windows, but there is still no explicit freshness signal for operator/tool decision-making.
- `index/status` currently reports presence and counts only, so clients cannot distinguish fresh artifacts from potentially stale ones after out-of-band note changes.
- Lifecycle automation decisions (manual rebuild vs defer) remain implicit without a deterministic stale indicator.

### Debt posture for next slice
- Debt paid down next: add explicit freshness observability to lifecycle status so rebuild decisions are data-driven.
- Debt potentially added: status freshness checks may require filesystem scans that can become costlier with very large note sets.
- Refactor signal: if freshness policy complexity grows (thresholds, ignore rules, partial scans), extract dedicated freshness policy logic from `IndexStore`.

## 2026-03-01 (ops smoke-script planning pass)

### Observed signals
- Core MCP contracts now span read, patch mutation, index lifecycle, and query, but there is no single repeatable end-to-end smoke workflow.
- Current verification is mostly spec-driven and command-level, which leaves a gap for environment-level regressions before EC2 rollout.
- Adding semantic retrieval later will increase external dependencies and operational variables, amplifying the cost of missing baseline smoke checks.

### Debt posture for next slice
- Debt paid down soon: codify a local smoke script and test-flow entrypoint that validates critical contracts in one repeatable run.
- Debt potentially added if deferred: environment drift risk between local dev and future EC2 staging increases as features accumulate.
- Refactor signal: if smoke coverage grows significantly, split smoke helpers/fixtures from single-script orchestration to keep scripts maintainable.

## 2026-03-01 (index lifecycle + scale controls planning pass)

### Observed signals
- Freshness and invalidation signals now exist, but lifecycle status still lacks bounded telemetry for operational scale decisions.
- As note volume and mutation frequency grow, manual rebuild timing decisions need explicit status cues to avoid ad hoc operator behavior.
- Query path is intentionally read-only, so scale-oriented lifecycle observability must come from status/rebuild controls.

### Debt posture for next slice
- Debt paid down next: add deterministic lifecycle telemetry in status for scale-aware operations while preserving contract stability.
- Debt potentially added: status metadata gathering may incur extra filesystem scan cost at larger repository sizes.
- Refactor signal: if lifecycle telemetry and policy branching increase, extract dedicated lifecycle policy/coordinator logic from `IndexStore`.

## 2026-03-01 (local smoke-script + test-flow planning pass)

### Observed signals
- Core MCP contracts now span read, patch, index lifecycle, and query, but no single local smoke flow validates the full runtime path.
- Current confidence is mostly spec-level; environment-level drift (mounts, runtime config, wiring) can still pass unnoticed until later staging.
- EC2 deployment is planned, so local production-like checks should be stabilized before introducing additional retrieval complexity.

### Debt posture for next slice
- Debt paid down next: add a deterministic local smoke script and test-flow guidance to close operational verification gaps.
- Debt potentially added: script assertions may initially be coarse-grained and require future helper extraction as coverage grows.
- Refactor signal: if smoke scenarios expand, split reusable request/assert utilities into `scripts/lib/` to avoid a monolithic script.

## 2026-03-01 (route wiring modularization planning pass)

### Observed signals
- `app.rb` now holds all route declarations across health, config, notes, patch, and index MCP flows, creating a single high-churn wiring file.
- Service/action extraction is already present, but route composition remains centralized enough to increase merge conflict risk as endpoints grow.
- Current tests are contract-strong at the request level, making this a good time for a composition-only refactor with low behavior risk.

### Debt posture for next slice
- Debt paid down next: reduce route concentration by extracting explicit route modules while preserving existing endpoint contracts.
- Debt potentially added: helper methods may remain coupled to `App` context until a later helper-boundary cleanup slice.
- Refactor signal: if helper sharing across route modules becomes noisy, extract one focused shared helper module rather than duplicating route-level logic.

## 2026-03-01 (runtime-agent action policy planning pass)

### Observed signals
- Route wiring is now modular, but there is still no centralized policy guard for runtime-agent action execution.
- Mutation and lifecycle-control endpoints are directly callable whenever transport reaches the service, leaving no explicit deny seam for constrained autonomy modes.
- Error mapping is already centralized, making this a low-risk point to add deterministic denied-action contracts without broad route rewrites.

### Debt posture for next slice
- Debt paid down next: introduce a first-class action policy boundary to prevent route-local permission branching and make autonomy constraints auditable.
- Debt potentially added: initial policy modes will be coarse-grained and environment-driven before identity-aware controls exist.
- Refactor signal: if policy modes or action sets grow, separate mode/config parsing from enforcement to keep policy logic small and testable.

## 2026-03-01 (semantic retrieval runtime integration planning pass)

### Observed signals
- Retrieval endpoint contracts are stable, and `NotesRetriever` already supports provider injection, but runtime wiring is still effectively lexical-first.
- The provider-portability goal is explicit in architecture docs, yet retrieval mode selection is not first-class at runtime.
- Without a bounded integration slice now, semantic retrieval adoption risks route-level branching or endpoint contract drift.

### Debt posture for next slice
- Debt paid down next: establish deterministic runtime provider selection with lexical fallback behind the existing query contract.
- Debt potentially added: initial semantic adapter may expose a minimal rank contract before richer metadata/scoring controls are added.
- Refactor signal: if provider choices or fallback policies multiply, extract a dedicated retrieval provider factory/policy object from `NotesRetriever`.

## 2026-03-01 (retrieval provider factory extraction planning pass)

### Observed signals
- Semantic retrieval mode is now wired, but `NotesRetriever` owns mode parsing, env handling, provider construction, and query orchestration together.
- Provider-selection concerns are starting to mix with retrieval behavior, increasing coupling in a central service.
- The prior refactor signal for a provider factory is now active because additional modes/adapters are expected.

### Debt posture for next slice
- Debt paid down next: isolate provider selection/config parsing in a dedicated factory and keep retriever focused on query orchestration/fallback.
- Debt potentially added: factory will initially encode only lexical/semantic selection and may need extension for richer policy rules.
- Refactor signal: if fallback logic also expands (timeouts, partial results), extract fallback policy from retriever into a dedicated strategy object.

## 2026-03-01 (shared route helper boundary cleanup planning pass)

### Observed signals
- Route declarations are modularized, but shared helper behavior (`render_error`, payload parsing, MCP error handling/policy enforcement) still lives in `App`.
- This keeps non-boot helper logic coupled to the app shell and increases future risk of `app.rb` growth.
- MCP endpoint count is now large enough that helper ownership clarity improves reviewability and reduces churn hotspots.

### Debt posture for next slice
- Debt paid down next: separate helper ownership from app composition by introducing an explicit shared MCP helper module.
- Debt potentially added: helper module may remain multi-responsibility initially to keep this slice bounded and contract-safe.
- Refactor signal: if helper complexity continues to grow, split helper module by concern (error rendering, payload parsing, policy enforcement).

## 2026-03-01 (runtime-agent policy mode hardening follow-up planning pass)

### Observed signals
- The action policy layer is functionally in place, but policy mode validity still primarily surfaces during request execution.
- Operator visibility is limited because `/config` does not currently expose policy mode diagnostics.
- Environment-driven control surfaces are growing (`MCP_POLICY_MODE`, retrieval mode flags), increasing the cost of late configuration failure.

### Debt posture for next slice
- Debt paid down next: centralize policy mode normalization/metadata and use it for both startup validation and runtime enforcement wiring.
- Debt potentially added: another small config boundary object must remain synchronized with policy constants.
- Refactor signal: if additional runtime mode/env parsing keeps expanding, introduce a single typed app-config parser to avoid scattered environment handling.
