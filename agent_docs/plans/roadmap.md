# Roadmap (Lightweight)

## Project Summary (North Star + Boundaries)

This project is building a deterministic, safety-first notes MCP service that supports trustworthy local knowledge workflows. The end goal is a stable platform where read, write, index, and retrieval operations are predictable, auditable, and safe by default, so higher-level agent behavior can rely on consistent contracts instead of best-effort behavior.

High-level goal:
- Deliver a production-ready MCP notes backend with strict safety guarantees, deterministic outputs, and explicit API contracts that can support sprinted feature delivery without regressions in trust or reproducibility.

Plan at a glance:
1. Establish safe core note operations (read, mutation, audit trail) with constrained and testable behavior.
2. Build deterministic indexing and retrieval primitives as a reliable baseline before quality tuning.
3. Ship model-backed v1 using OpenAI (LLM API + embedding API + managed vector store) behind provider abstractions to accelerate delivery and evaluation.
4. Add self-hosted model backends (local LLM + local embedding model + self-managed vector index) with parity contract tests and runtime provider switching.
5. Improve maintainability and planning hygiene so ongoing slices stay reviewable and execution context remains unambiguous.
6. Layer retrieval quality and policy controls only after contract and ownership boundaries are stable.

Model and retrieval implementation strategy:
- Phase 1 (OpenAI-first): use OpenAI LLM + embeddings + managed vector store to validate retrieval quality, note-update workflows, and MCP management flows under real usage.
- Phase 2 (abstraction hardening): keep MCP retrieval/update/management contracts provider-agnostic; isolate LLM, embedding, and vector index operations behind service interfaces and shared fixtures.
- Phase 3 (self-hosted transition): integrate a local/self-hosted LLM, embedding model, and vector index; validate quality, latency, and behavior parity against Phase 1 baselines before changing defaults.
- Phase 4 (hybrid/fallback): support controlled fallback between OpenAI and self-hosted providers with explicit policy configuration once ownership and operational constraints are defined.

Long-term product goal (hosted web frontend):
- Deliver a web interface for directing MCP-backed LLM behavior once backend contracts are stable.
- Support guided capture of new knowledge (including dictated input), question answering over existing notes, statistics/metadata views, and explicit edit/apply workflows.
- Treat this as a later-phase product surface that builds on mature retrieval/update/management APIs rather than driving early contract changes.

Project boundaries:
- Prioritize contract clarity, deterministic behavior, and auditability over rapid feature breadth.
- Favor incremental slices, but allow explicit contract refactors when the consumer surface is still small and coordinated updates are cheaper than carrying ambiguity.
- Require retrieval, update, and notes-management flows to preserve MCP contract compatibility across OpenAI and self-hosted backends.
- Prefer removing ambiguous or duplicative public fields now instead of preserving them with compatibility shims by default.
- Defer advanced ranking/policy complexity until fallback/policy ownership is explicit.

Early-stage contract policy:
- During the current pre-broad-adoption phase, breaking API changes are acceptable when they simplify the contract and can be propagated to the known consumers in the same work cycle.
- Compatibility layers are a tool, not a default; use them only when the coordination cost is genuinely higher than the ongoing contract debt they introduce.
- `mirai` remains the contract owner, so `local_llm` and any hosted-provider fixtures should be refactored to match cleaner `mirai` contracts rather than freezing early awkward shapes.

## Near-Term Follow-ons

7. Retrieval query response quality enhancements
- Add bounded match-explanation metadata to query results for better operator trust and downstream UX
- Start with deterministic lexical rationale and preserve stable query defaults before extending semantic-provider parity

8. Planning artifact hygiene
- Reconcile superseded/open planning case artifacts to keep execution context unambiguous
- Preserve lightweight backlog cadence without expanding implementation scope

## Later (After Contracts Stabilize)

10. Retrieval quality and policy extensions
- Add richer ranking/selection controls only after fallback policy ownership is explicit
- Preserve deterministic request contracts while evolving retrieval internals

11. Hosted web frontend for operator workflows
- Build a web UI to direct retrieval, note updates, and management actions through MCP-backed services
- Include flows for dictated knowledge capture, knowledge Q&A, repository statistics/metadata inspection, and explicit edit application
- Roll out after model-provider abstractions and backend contracts are stable enough to avoid frontend churn
