# Tech Debt Log

## 2026-03-29 (canonical workflow execute endpoint planning pass)

### Observed signals
- `mirai` now has stable but separate `/mcp/workflow/plan`, `/mcp/workflow/draft_patch`, and `/mcp/workflow/apply_patch` endpoints, which still requires thin clients to know endpoint sequencing and payload translation rules for one note-update run.
- The planner handoff and workflow-apply response seams are now explicit enough that a narrow convergence slice can reuse existing action contracts instead of inventing a new generic workflow protocol.
- Route wiring currently duplicates drafter construction across draft/apply paths in `app/routes/mcp_routes.rb`, so adding execution by copy/paste would increase orchestration debt.

### Debt posture for next slice
- Debt paid down next: establish one canonical server-owned execution path for the existing `workflow.draft_patch` action so end-to-end workflow updates stop depending on client-side stitching.
- Debt potentially added: the first execute endpoint may still leave the lower-level draft/apply endpoints in place and may use a narrow single-action validator rather than a reusable workflow executor registry.
- Refactor signal: if more executable workflow actions appear, extract a dedicated workflow executor/registry object instead of growing route-local action dispatch logic.

## 2026-03-29 (workflow apply response contract tightening planning pass)

### Observed signals
- `/mcp/workflow/apply_patch` currently returns the `PatchApplyAction` summary merged with a top-level drafted `patch` string, so the response shape does not clearly separate mutation result fields from workflow-owned audit data.
- The current workflow consumer set is still small, but the README and request specs now document the flat response, which means delay will harden a shortcut contract into downstream assumptions.
- The workflow apply seam is otherwise behaving as intended; the main risk is response ownership ambiguity, not missing execution capability.

### Debt posture for next slice
- Debt paid down next: isolate drafted unified-diff audit data under a workflow-owned response envelope so workflow apply remains explicit and easier to evolve.
- Debt potentially added: the first tightened contract will still be modest and may not yet expose richer execution metadata beyond the drafted diff.
- Refactor signal: if workflow execution returns more audit metadata later, add it inside a nested audit object rather than growing a second flat response contract.

## 2026-03-23 (workflow draft apply operator-loop planning pass)

### Observed signals
- The canonical `workflow.draft_patch` planner action now hands directly into `/mcp/workflow/draft_patch`, but there is still no server-owned operator path from that same action payload into a committed note update.
- Current workflow contracts stop at dry-run draft generation, which pressures consumers to assemble their own draft-to-apply glue if they want an end-to-end operator loop.
- `/mcp/patch/apply` already owns raw unified-diff mutation semantics, so overloading it with workflow-specific request envelopes would blur the boundary between workflow orchestration and patch mutation.

### Debt posture for next slice
- Debt paid down next: add one explicit workflow-owned apply seam so the first operator-run loop remains canonical and server-owned instead of fragmenting across clients.
- Debt potentially added: the first workflow apply response will likely be intentionally narrow and may need a small contract-tightening follow-on once real operator usage clarifies which audit fields matter most.
- Refactor signal: if additional executable workflow actions appear, extract a small workflow dispatcher/executor object rather than duplicating orchestration in route handlers.

## 2026-03-22 (local workflow smoke-loop planning pass)

### Observed signals
- The local workflow planner and local workflow drafter seams have both landed, but the existing smoke script still validates only notes/index/patch flows and never crosses the new planner-to-drafter boundary.
- Current confidence for the self-hosted workflow path is mostly request/spec-level, which leaves runtime wiring and config assumptions under-validated compared with older MCP surfaces.
- `scripts/smoke_local.sh` is growing linearly; another workflow section is still reasonable now, but repeated orchestration additions would make the script harder to maintain.

### Debt posture for next slice
- Debt paid down next: add one bounded end-to-end verification seam for the self-hosted planner-to-drafter loop so runtime/config drift is caught earlier.
- Debt potentially added: workflow smoke assertions will remain contract-shape checks rather than deterministic model-output fixtures, which is acceptable for a small operator-facing smoke slice.
- Refactor signal: if the smoke script takes on more workflow branches or reusable JSON extraction, split helpers into `scripts/lib/` rather than continuing to inline everything in one file.

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

## 2026-03-15 (workflow plan/draft handoff planning pass)

### Observed signals
- `/mcp/workflow/plan` and `/mcp/workflow/draft_patch` now exist as adjacent workflow endpoints, but the planner action contract is still free-form enough that consumers must guess how to translate draft intent into a drafter request.
- `WorkflowPlanner` currently normalizes generic `{action, reason, params}` objects, while `WorkflowDraftPatchAction` separately validates top-level `instruction`, `path`, and `context`, creating a contract seam with duplicate ownership.
- README examples and request specs cover each endpoint independently, but there is no canonical handoff example showing how a plan response should drive the draft endpoint.

### Debt posture for next slice
- Debt paid down next: define one canonical draft-handoff payload so planning and drafting share an explicit contract instead of ad hoc consumer translation.
- Debt potentially added: the first typed planner-action validation may remain limited to the draft handoff path until more workflow actions justify a broader schema layer.
- Refactor signal: if more planner actions need typed validation, extract a dedicated workflow action-schema validator rather than expanding `WorkflowPlanner#normalize_action` into a large conditional parser.

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

## 2026-03-14 (local retrieval adapter planning pass)

### Observed signals
- `local_llm` now defines a ranked chunk artifact contract for self-hosted retrieval, but `mirai` retrieval wiring still treats semantic mode as effectively OpenAI-specific.
- `RetrievalProviderFactory` and runtime config expose a semantic-provider field, yet the current implementation does not use that setting to choose among semantic adapters.
- Without a bounded local adapter slice now, future self-hosted retrieval work is likely to grow around OpenAI-shaped assumptions in config and provider construction.

### Debt posture for next slice
- Debt paid down next: introduce provider-aware semantic retrieval selection so local/self-hosted retrieval can plug into the existing query contract with lexical fallback.
- Debt potentially added: local provider transport and ingestion semantics will remain intentionally partial until a later slice.
- Refactor signal: if semantic provider variants expand beyond a small set, split provider registration/selection from the current factory initializer.

## 2026-03-08 (workflow-plan context enrichment planning pass)

### Observed signals
- `/mcp/workflow/plan` currently depends mostly on user-supplied `intent`/`context`, so planner output can be generic when repository state is relevant.
- Read-safe signals (note content, index freshness/status, semantic readiness) exist in separate seams but are not assembled for planner use.
- Without a bounded context builder, action/route layers risk accumulating ad hoc context assembly logic and inconsistent prompt payloads.

### Debt posture for next slice
- Debt paid down next: introduce a deterministic planner context snapshot seam so planning quality improves without execute-layer coupling.
- Debt potentially added: first pass context enrichment will likely be single-path and excerpt-limited.
- Refactor signal: if context sources expand, split builder output into typed sections with explicit size/ownership policies.

### Observed signals
- The action policy layer is functionally in place, but policy mode validity still primarily surfaces during request execution.
- Operator visibility is limited because `/config` does not currently expose policy mode diagnostics.
- Environment-driven control surfaces are growing (`MCP_POLICY_MODE`, retrieval mode flags), increasing the cost of late configuration failure.

### Debt posture for next slice
- Debt paid down next: centralize policy mode normalization/metadata and use it for both startup validation and runtime enforcement wiring.
- Debt potentially added: another small config boundary object must remain synchronized with policy constants.
- Refactor signal: if additional runtime mode/env parsing keeps expanding, introduce a single typed app-config parser to avoid scattered environment handling.

## 2026-03-01 (retrieval storage/lifecycle artifact telemetry planning pass)

### Observed signals
- Retrieval status already reports freshness and counts, but lacks direct storage-size visibility for artifact growth decisions.
- As notes/chunks grow, operators currently infer storage pressure indirectly, increasing ad hoc rebuild timing and cleanup decisions.
- Retrieval query contracts are stable, so status-only observability is the lowest-risk place to improve lifecycle operations.

### Debt posture for next slice
- Debt paid down next: add deterministic artifact storage telemetry to the lifecycle status contract for scale-aware operations.
- Debt potentially added: status computation may accumulate metric-specific logic inside `IndexStore` before extraction.
- Refactor signal: if telemetry fields continue to grow, extract a focused status-metrics helper from `IndexStore` to avoid a monolithic lifecycle method.

## 2026-03-01 (runtime config mode contract hardening planning pass)

## 2026-03-21 (local planner provider handoff planning pass)

### Observed signals
- `local_llm` now has planner smoke, parity fixtures, and a stable OpenAI-compatible local runtime baseline, but `mirai`'s workflow planner still hard-codes provider support to `openai`.
- Retrieval-side local provider wiring already exists, so workflow planning is now the most concrete remaining self-hosted seam inside `mirai`.
- Route wiring currently constructs an OpenAI workflow planner client inline, increasing the risk of route-level branching if local planner support is added without a bounded seam.

### Debt posture for next slice
- Debt paid down next: introduce a provider-aware workflow planner boundary so self-hosted planner wiring can land without changing `/mcp/workflow/plan` contracts.
- Debt potentially added: local planner support will initially stop at planning-only mode and defer local patch-drafter wiring.
- Refactor signal: if planner provider variants or fallback rules expand beyond a small set, extract a dedicated planner client factory instead of widening route construction and service initializer branching.

## 2026-03-22 (local workflow patch drafter provider handoff planning pass)

### Observed signals
- `local_llm` now has a draft-patch smoke path for the OpenAI-compatible local runtime, but `mirai`'s `WorkflowPatchDrafter` still treats any non-OpenAI provider as unavailable.
- `mirai` already exposes a local workflow base URL and local planner client seam, so the remaining self-hosted workflow gap is concentrated in draft generation rather than config discovery.
- Planner and drafter provider ownership is still coarse-grained, increasing the risk of route-level branching or duplicate provider parsing if local draft support is added ad hoc.

### Debt posture for next slice
- Debt paid down next: introduce a provider-aware workflow patch-drafter boundary so self-hosted draft generation can land without changing `/mcp/workflow/draft_patch` contracts.
- Debt potentially added: planner and drafter may continue sharing coarse workflow runtime settings until a later config-ownership cleanup slice justifies separation.
- Refactor signal: if planner and drafter client selection logic continue to grow in parallel, extract a shared workflow client factory or typed runtime-config object instead of duplicating provider selection rules.

### Observed signals
- Runtime mode parsing is currently split across app boot (`MCP_POLICY_MODE`) and retrieval provider selection (`MCP_RETRIEVAL_MODE`), which creates inconsistent failure behavior.
- Policy mode already fails fast on invalid values, while retrieval mode silently falls back to lexical, increasing risk of unnoticed environment drift.
- `/config` exposes policy diagnostics but not retrieval mode diagnostics, limiting operator visibility when runtime behavior diverges from expectation.

### Debt posture for next slice
- Debt paid down next: centralize runtime mode parsing/validation in one config boundary and expose deterministic diagnostics for both policy and retrieval modes.
- Debt potentially added: introducing a config object adds one more indirection layer that must remain synchronized with mode constants.
- Refactor signal: if additional runtime toggles continue to grow, consolidate environment parsing into a typed app-config module rather than service-local env reads.

## 2026-03-02 (patch/index concurrency guardrails planning pass)

### Observed signals
- `PatchApplyAction` commits note mutations and then invalidates index artifacts, while rebuild/invalidate actions can run independently with no shared synchronization boundary.
- Index lifecycle correctness is currently contract-tested for single-request flows, but concurrent mutation/rebuild ordering is not explicitly constrained.
- As runtime-agent mutation traffic grows, lifecycle races become harder to reason about and can produce stale-read windows that are not visible in normal happy-path tests.

### Debt posture for next slice
- Debt paid down next: introduce a small lock seam around lifecycle mutation paths so artifact state transitions are deterministic.
- Debt potentially added: serialized mutation operations may reduce parallel throughput until higher-scale coordination strategy is introduced.
- Refactor signal: if additional mutation endpoints are added, centralize lock + post-mutation lifecycle orchestration in one coordinator to avoid duplicated action-level synchronization logic.

## 2026-03-02 (symlink listing policy contract alignment planning pass)

### Observed signals
- `SafeNotesPath#list_markdown_files` enumerates markdown paths by glob/file checks, while `resolve` applies stricter containment checks (including realpath-based symlink escape protection).
- This can surface paths from `/mcp/notes` that fail `/mcp/notes/read`, creating a contract mismatch for runtime-agent/tool flows that treat list output as read candidates.
- Existing safety posture is strong on read-path enforcement, so the primary gap is policy consistency at discovery time.

### Debt posture for next slice
- Debt paid down next: align listing semantics with read containment so notes discovery is read-safe by construction.
- Debt potentially added: tighter listing filters may hide some edge-case symlink setups until explicit allowlist policy exists.
- Refactor signal: if discovery rules continue to expand (symlink handling, hidden files, ignores), split file-discovery policy from path-resolution responsibilities in `SafeNotesPath`.

## 2026-03-02 (runtime config semantic-flag contract planning pass)

### Observed signals
- `RuntimeConfig` and `RetrievalProviderFactory` both implement local `truthy?` parsing for `MCP_SEMANTIC_PROVIDER_ENABLED`, creating duplicated behavior ownership.
- `/config` currently exposes policy/retrieval mode diagnostics but not the effective semantic-provider enabled value, limiting operator visibility.
- Retrieval/provider behavior is now configuration-rich enough that parsing drift can silently change runtime behavior between boot and query flows.

### Debt posture for next slice
- Debt paid down next: centralize semantic-flag boolean normalization and expose deterministic diagnostics in `/config`.
- Debt potentially added: introducing a helper seam adds one more config abstraction to keep aligned with runtime defaults.
- Refactor signal: if additional runtime flags are introduced, consolidate mode + boolean parsing under one typed runtime-config contract.

## 2026-03-02 (runtime-agent policy identity extension seam planning pass)

### Observed signals
- Action policy mode handling is centralized, but policy inputs are still implicit and request-context-free, which limits safe extension toward identity-aware controls.
- Current route/helper wiring can enforce mode gates, but there is no explicit actor-context contract for future rules to consume.
- As autonomy constraints evolve, adding identity checks directly in routes/actions would increase coupling and duplication risk.

### Debt posture for next slice
- Debt paid down next: introduce a narrow identity-context seam so policy extension remains service-first and testable.
- Debt potentially added: context attributes will start minimal and may need a later adapter when transport/auth layers exist.
- Refactor signal: if context construction logic begins branching by endpoint/source, extract a dedicated context builder separate from route helpers.

## 2026-03-02 (retrieval fallback policy extraction planning pass)

### Observed signals
- `NotesRetriever` currently owns chunk sourcing, provider invocation, and fallback error handling in one method.
- Semantic-mode fallback currently works, but behavior ownership is implicit (`rescue` inside retriever) and will become harder to extend safely.
- Retrieval provider selection has already been extracted to `RetrievalProviderFactory`, so fallback policy is now the remaining mixed concern in retriever orchestration.

### Debt posture for next slice
- Debt paid down next: isolate fallback decision logic into a dedicated seam so retriever remains orchestration-focused.
- Debt potentially added: one additional retrieval abstraction layer that must stay intentionally narrow.
- Refactor signal: if fallback conditions expand beyond `UnavailableError`, introduce an explicit retrieval error taxonomy/policy contract to avoid ad hoc rescues.

## 2026-03-02 (action policy identity-context contract planning pass)

### Observed signals
- `Mcp::ActionPolicy` currently retains default identity context and also accepts call-time identity input, but enforcement decisions are still mode-only.
- The policy implementation contains identity-context plumbing that can read as placeholder behavior, increasing ambiguity in a safety-sensitive seam.
- Existing request-level plumbing specs already assert identity context reaches policy enforcement, so this is a low-risk clarity refactor with strong regression coverage.

### Debt posture for next slice
- Debt paid down next: make identity-context ownership explicit in `ActionPolicy` and remove ambiguous unused state patterns.
- Debt potentially added: temporary backward-compatibility handling may retain a small dual-input path until all callers are explicit.
- Refactor signal: if identity-aware authorization rules are added, split decision predicates by action family to prevent policy branching sprawl.

## 2026-03-03 (feature-balance planning pass: retrieval path-scope filtering)

### Observed signals
- Recent planning/completion cadence is heavily concentrated on hardening and must-fix follow-ups, with minimal net-new user-visible capability progression.
- Retrieval contracts are stable and deterministic, making query-shape extensions lower risk than additional policy/internal hardening.
- Current query API has no first-class path/folder scoping, forcing clients to over-fetch and post-filter in multi-domain note repositories.

### Debt posture for next slice
- Debt paid down next: reduce feature-delivery drift by shipping a bounded user-visible query capability while preserving existing defaults.
- Debt potentially added: query parameter surface will grow (`path_prefix`), which may require later normalization/validation centralization if more filters are added.
- Refactor signal: if query filters expand beyond one or two options, extract a dedicated query-options parser/validator object to avoid retriever/service argument sprawl.

## 2026-03-03 (feature-balance planning pass: notes batch read endpoint)

### Observed signals
- Retrieval query feature delivery resumed with `path_prefix`, but read workflows still require one HTTP call per known note.
- Existing read safety/error contracts are strong and reusable, making batch read a low-risk capability expansion.
- Route-layer JSON payload parsing currently exists for patch endpoints only; adding more payload endpoints can increase parser duplication if not contained.

### Debt posture for next slice
- Debt paid down next: deliver a user-visible throughput improvement without changing core mutation/indexing internals.
- Debt potentially added: another endpoint-specific payload-validation path in routes/actions.
- Refactor signal: if more JSON read/query endpoints are introduced, extract a small MCP request-schema helper to avoid repeated payload-shape checks.

## 2026-03-03 (user-directed planning pass: service/spec intermediate structure readability)

### Observed signals
- `app/services/` and top-level `spec/` now contain enough files that related concerns are harder to locate quickly during review and implementation.
- Earlier slices optimized for velocity with a flat layout, but current breadth (retrieval, indexing, patch, notes, policy) makes domain boundaries less legible at a glance.
- Ongoing feature delivery will keep adding files; leaving structure flat increases navigation overhead and merge-churn concentration.

### Debt posture for next slice
- Debt paid down next: introduce bounded intermediate directory structure to restore clear domain grouping and reduce scanning friction.
- Debt potentially added: file-move churn and require-path updates can create short-term load-path regressions if not validated with full suite execution.
- Refactor signal: if structural conventions are not documented and enforced, future additions may drift back to flat placement.

## 2026-03-07 (user-directed planning pass: OpenAI semantic retrieval adapter v1)

### Observed signals
- Roadmap now commits to an OpenAI-first model phase, but semantic mode remains a placeholder lexical adapter with no true semantic lift.
- Retrieval contracts and fallback seams are already stable (`RetrievalProviderFactory` + `RetrievalFallbackPolicy`), making this a low-risk integration point.
- Planning artifacts were recently decoupled (roadmap direction vs backlog execution), so next slice should be concrete, feature-forward, and directly roadmap-aligned.

### Debt posture for next slice
- Debt paid down next: replace placeholder semantic behavior with a real provider-backed retrieval path while preserving deterministic contract behavior.
- Debt potentially added: provider-specific OpenAI wiring may temporarily concentrate config/error handling before broader model-provider abstractions are shared with update/management flows.
- Refactor signal: if OpenAI integration introduces duplicated embed/search wiring or error mapping, extract a unified model-provider client boundary before adding additional model operations.

## 2026-03-08 (exploratory planning pass: async note re-embedding pipeline)

### Observed signals
- OpenAI semantic retrieval is now validated end to end, but vector-store freshness still depends on manual chunk upload workflows.
- Current mutation path (`patch/apply`) invalidates local lexical artifact state, yet there is no parallel mechanism to keep remote semantic index state aligned.
- Retrieval/provider seams are stable enough that ingestion orchestration can be introduced without route contract churn.

### Debt posture for next slice
- Debt paid down next: remove recurring operational debt from manual re-embedding and establish deterministic post-mutation semantic ingestion ownership.
- Debt potentially added: first iteration will likely use an in-process async queue with limited crash durability and retry semantics.
- Refactor signal: if ingestion logic starts mixing queue lifecycle, provider calls, and mutation orchestration, extract a dedicated ingestion coordinator + queue adapter boundary.

## 2026-03-08 (exploratory planning pass: retrieval query snippet offsets)

### Observed signals
- `/mcp/index/query` currently returns ranked chunks but no match-location metadata, forcing each client to rescan chunk text for grounding highlights.
- Retrieval seams are now stable (`RetrievalProviderFactory`, semantic fallback policy, async ingestion), creating a low-risk point for additive response enrichment.
- Ranking and tokenization concerns are already separated enough that snippet extraction can be introduced as a post-ranking annotation boundary.

### Debt posture for next slice
- Debt paid down next: remove repeated client-side snippet parsing and centralize deterministic offset semantics in one retrieval-owned contract.
- Debt potentially added: first iteration will likely expose a single span per chunk, with richer multi-span behavior deferred.
- Refactor signal: if snippet policy complexity grows (multi-span, excerpt generation, provider-specific hints), extract an explicit snippet policy object instead of expanding retriever orchestration.

## 2026-03-08 (exploratory planning pass: OpenAI LLM workflow seam for update/management actions)

### Observed signals
- OpenAI integration is currently retrieval-only; there is no model-assisted planning path for note-update or repository-management workflows.
- MCP mutation and lifecycle actions are already explicit and test-backed, making them suitable targets for a planning-only orchestration layer.
- Current backlog still includes a completed snippet slice and one stale retrieval item, indicating planning artifacts need to shift to the next roadmap phase.

### Debt posture for next slice
- Debt paid down next: establish a provider-safe LLM planning seam so non-retrieval model workflows can evolve without route-level coupling.
- Debt potentially added: first pass remains OpenAI-specific and may encode prompt/response assumptions that require abstraction hardening later.
- Refactor signal: if planner input/output schema grows (context blocks, tool constraints, policy modes), extract dedicated workflow schema validation/policy objects instead of expanding action classes.

## 2026-03-08 (exploratory planning pass: instruction-to-patch draft endpoint, openai dry-run)

### Observed signals
- Planning-only workflow endpoint now returns structured action plans, but there is no model-generated draft artifact that can flow into existing patch safety paths.
- Patch proposal/validation contracts are already stable and provide a natural guardrail for model-generated diffs.
- Current workflow value remains limited without a bridge from intent planning to concrete patch draft output.

### Debt posture for next slice
- Debt paid down next: connect workflow intent to actionable, validation-ready patch drafts while preserving non-mutating safety boundaries.
- Debt potentially added: first pass will likely encode OpenAI prompt assumptions and single-file drafting limits.
- Refactor signal: if draft generation needs richer constraints (multi-file, template policies, diff styles), extract dedicated draft-schema/prompt policy objects from endpoint orchestration.
## 2026-03-10 (user-directed planning pass: GitHub Actions branch CI foundation)

### Observed signals
- Local verification discipline is documented and reasonably strong, but merge confidence still depends on implementor/reviewer agents running the right commands on the current machine.
- The spec suite already isolates note roots with temporary directories, so core verification does not require the external notes bind mount used by local Docker Compose.
- Deployment interest is increasing, but the project still lacks a minimal independent CI gate that can catch environment drift before deploy automation is introduced.

### Debt posture for next slice
- Debt paid down next: add an external, repeatable branch verification gate for full-suite and lint checks before manual merge.
- Debt potentially added: CI may initially run in native GitHub Ruby instead of the local Docker runtime, leaving a small environment-parity gap by design.
- Refactor signal: if CI responsibilities expand beyond test/lint (smoke, image packaging, deploy), split workflow concerns early to avoid one oversized pipeline file.

## 2026-03-16 (exploratory planning pass: retrieval query result match explainability)

### Observed signals
- `/mcp/index/query` now exposes canonical grounding metadata (`metadata.path`, `metadata.chunk_index`, `metadata.snippet_offset`), but operators still only get a raw score with no bounded rationale for why a chunk matched.
- `NotesRetriever` is already the single response-shaping boundary across lexical and semantic retrieval paths, making it the safest place to add one small explanation contract without route churn.
- Retrieval contracts recently stabilized after metadata cleanup, so this is a good moment to add trust-improving fields before more consumers build their own explanation heuristics around opaque scores.

### Debt posture for next slice
- Debt paid down next: reduce client-side guesswork and future ad hoc explanation logic by establishing one deterministic retrieval-owned explanation contract.
- Debt potentially added: first-pass explanation fields will likely be lexical-first and intentionally bounded, leaving richer semantic rationale for a follow-on slice.
- Refactor signal: if explanation payloads expand beyond a couple of deterministic fields, extract a dedicated retrieval explanation builder instead of growing `NotesRetriever` response shaping inline.
