# Roadmap (Lightweight)

## Project Summary (North Star + Boundaries)

This project is building a deterministic, safety-first agent harness for git-backed markdown knowledge state. The notes repository remains the first product domain and source of truth, but the deeper goal is a stable runtime where model-driven read, plan, draft, validate, mutate, commit, and re-index operations are predictable, auditable, and safe by default.

High-level goal:
- Deliver a production-ready MCP notes backend and workflow harness with strict safety guarantees, deterministic outputs, explicit API contracts, and provider/model selection policy that can support sprinted feature delivery without regressions in trust or reproducibility.

Plan at a glance:
1. Establish safe core note operations (read, mutation, audit trail) with constrained and testable behavior.
2. Build deterministic indexing and retrieval primitives as a reliable baseline before quality tuning.
3. Ship model-backed v1 using OpenAI (LLM API + embedding API + managed vector store) behind provider abstractions to accelerate delivery and evaluation.
4. Add self-hosted model backends (local LLM + local embedding model + self-managed vector index) with parity contract tests, request/session-level model selection, and controlled runtime switching.
5. Improve maintainability and planning hygiene so ongoing slices stay reviewable and execution context remains unambiguous.
6. Layer retrieval quality, model-capability policy, and workflow approval controls only after contract and ownership boundaries are stable.

Model and retrieval implementation strategy:
- Phase 1 (OpenAI-first): use OpenAI LLM + embeddings + managed vector store to validate retrieval quality, note-update workflows, and MCP management flows under real usage.
- Phase 2 (abstraction hardening): keep MCP retrieval/update/management contracts provider-agnostic; isolate LLM, embedding, and vector index operations behind service interfaces and shared fixtures.
- Phase 3 (self-hosted transition): integrate a local/self-hosted LLM, embedding model, and vector index; validate quality, latency, and behavior parity against Phase 1 baselines before changing defaults.
- Phase 4 (hybrid/fallback): support controlled fallback between OpenAI and self-hosted providers with explicit policy configuration once ownership and operational constraints are defined.

Workflow model strategy:
- Treat smaller local models as useful participants for bounded, typed workflow stages rather than as a ceiling for the overall harness. They should be able to handle strict JSON intents, single-note edits, and short planner/drafter loops when context is already scoped.
- Treat larger hosted models as escalation paths for broader planning, multi-note synthesis, larger-context reasoning, and recovery from failed local attempts, while preserving the same server-owned validation, patch construction, git commit, audit, and approval boundaries.
- Prefer capability/profile policy over raw model-size checks. Useful gates include `strict_json_edit_intent`, `single_note_edit`, `multi_step_planning`, `multi_note_plan`, `large_context_synthesis`, and `autonomous_apply_allowed`.
- Keep provider-specific prompt quirks and decoding settings in provider adapters; keep durable workflow semantics in `mirai` contracts and MCP actions.

Long-term product goal (hosted web frontend):
- Deliver a web interface for directing MCP-backed LLM behavior once backend contracts are stable.
- Support guided capture of new knowledge (including dictated input), question answering over existing notes, statistics/metadata views, and explicit edit/apply workflows.
- Treat this as a later-phase product surface that builds on mature retrieval/update/management APIs rather than driving early contract changes.

Project boundaries:
- Prioritize contract clarity, deterministic behavior, and auditability over rapid feature breadth.
- Favor incremental slices, but allow explicit contract refactors when the consumer surface is still small and coordinated updates are cheaper than carrying ambiguity.
- Require retrieval, update, and notes-management flows to preserve MCP contract compatibility across OpenAI and self-hosted backends.
- Allow request/session-level model selection and later server-chosen routing, but never let a selected model bypass the common mutation safety path.
- Prefer removing ambiguous or duplicative public fields now instead of preserving them with compatibility shims by default.
- Defer advanced ranking/policy complexity until fallback/policy ownership is explicit.

Early-stage contract policy:
- During the current pre-broad-adoption phase, breaking API changes are acceptable when they simplify the contract and can be propagated to the known consumers in the same work cycle.
- Compatibility layers are a tool, not a default; use them only when the coordination cost is genuinely higher than the ongoing contract debt they introduce.
- `mirai` remains the contract owner, so `local_llm` and any hosted-provider fixtures should be refactored to match cleaner `mirai` contracts rather than freezing early awkward shapes.
- With no active external consumers yet, prefer collapsing multi-step workflow experiments into a clearer server-owned flow when that removes client stitching or audit ambiguity.

## Near-Term Follow-ons

Near-term direction: prioritize a minimal real-notes MVP over additional internal contract polish once the edit-intent execution bridge is in place. The MVP should let an operator run a scoped note-update workflow against a real notes mount, inspect the dry-run trace, choose a local/hosted/auto model profile, and explicitly apply approved changes through the existing patch/commit/index safety path.

7. Canonical workflow execution path
- Reduce client-side orchestration across `/mcp/workflow/plan`, `/mcp/workflow/draft_patch`, and `/mcp/workflow/apply_patch` by converging toward one clearer server-owned workflow run/apply flow.
- Use the current low-consumer phase to rework endpoint boundaries if that produces a simpler operator path with better audit semantics.
- Immediate next slice: introduce a first execute endpoint for canonical `workflow.draft_patch` actions before considering any broader workflow action dispatcher.

8. Workflow edit-intent contract pivot
- Replace the fragile model-authored unified-diff boundary with a typed `edit_intent` JSON contract that `mirai` owns and can validate deterministically across hosted and self-hosted workflow providers.
- Keep the workflow surface server-owned: providers should propose bounded file edit operations, while `mirai` remains responsible for converting or applying those operations through existing patch-policy and audit seams.
- Sequence the pivot as small slices: contract definition first, execute/drafter translation second, local-provider/OpenAI fixture updates third.

9. Workflow model selection and capability policy
- Add a server-owned model/profile selection seam so callers or later automatic routing can choose different planner/drafter models per workflow run without changing process-wide environment defaults.
- Gate broader workflow actions by named capabilities rather than raw provider or model size, so smaller local models can use the safe subset while stronger hosted models can orchestrate larger multi-step runs.
- Preserve the invariant that model selection changes planning/drafting capability only; mutation safety, patch policy, commits, audit, and approval behavior remain common.

10. MVP operator dry-run/apply loop
- Add an inspectable workflow dry-run trace that shows selected/read context, provider/model identity, normalized `edit_intent`, generated patch, validation status, and apply readiness before any note mutation.
- Add a minimal CLI operator loop before a web frontend so real-note testing can start quickly without committing to UI shape.
- Cover at least one local-model path and one hosted/hosted-profile path in a small real-notes smoke scenario pack.

11. Retrieval query response quality enhancements
- Add bounded match-explanation metadata to query results for better operator trust and downstream UX
- Preserve the bounded explainability contract while deferring any richer provider-specific rationale until retrieval policy ownership is clearer

12. Planning artifact hygiene
- Reconcile superseded/open planning case artifacts to keep execution context unambiguous
- Preserve lightweight backlog cadence without expanding implementation scope

## Later (After Contracts Stabilize)

13. Retrieval quality and policy extensions
- Add richer ranking/selection controls only after fallback policy ownership is explicit
- Preserve deterministic request contracts while evolving retrieval internals

14. Hosted web frontend for operator workflows
- Build a web UI to direct retrieval, note updates, and management actions through MCP-backed services
- Include flows for dictated knowledge capture, knowledge Q&A, repository statistics/metadata inspection, and explicit edit application
- Roll out after model-provider abstractions and backend contracts are stable enough to avoid frontend churn
