---
case_id: CASE_runtime_config_semantic_flag_contract_hardening
created: 2026-03-02
---

# CASE: Runtime Config Semantic Flag Contract Hardening

## Goal
Make semantic-provider flag handling deterministic by centralizing boolean parsing and exposing the effective value in `/config`.

## Why this next
- Value: reduces operator drift by making semantic retrieval enablement visible and normalized in one place.
- Dependency/Risk: derisks future retrieval/provider work by removing duplicated env parsing behavior.
- Tech debt note: pays down config-boundary drift (`truthy?` logic duplicated across services).

## Definition of Done
- [ ] One shared boolean parsing contract is used by both `RuntimeConfig` and `RetrievalProviderFactory`.
- [ ] `GET /config` includes `mcp_semantic_provider_enabled` and reflects the effective normalized runtime value.
- [ ] Existing behavior remains compatible for known env inputs (`"true"` enables; all other values disable).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- Introduce a small shared boolean-normalization seam for runtime env flags.
- Rewire `RuntimeConfig` and `RetrievalProviderFactory` to consume that seam.
- Extend `/config` diagnostics and docs/specs for semantic-provider enabled visibility.

**Out**
- Semantic retrieval ranking behavior or provider fallback policy changes.
- New retrieval modes or policy-mode authorization changes.

## Proposed approach
Add a tiny runtime-flag helper (module/class) responsible for strict boolean normalization (`true` only when canonicalized input equals `"true"`). Use it in `RuntimeConfig` and `RetrievalProviderFactory` to remove duplicated `truthy?` methods while preserving current semantics. Extend `/config` response to include `mcp_semantic_provider_enabled` so operators can verify the effective value after normalization. Update request/unit specs and README endpoint contract text to keep diagnostics behavior explicit and deterministic.

## Steps (agent-executable)
1. Add a shared boolean runtime-flag normalization helper in `app/services/mcp/` (or adjacent config service namespace).
2. Update `RuntimeConfig` and `RetrievalProviderFactory` to use the helper and remove local parsing duplication.
3. Extend `GET /config` payload to expose `mcp_semantic_provider_enabled`.
4. Update/extend request and service specs for config payload and parser behavior.
5. Update README `/config` contract example.
6. Run targeted specs, then full RSpec.

## Risks / Tech debt / Refactor signals
- Risk: subtle behavior drift for mixed-case/whitespace env values. -> Mitigation: add explicit parser examples (`" true "`, `"TRUE"`, `"false"`, blank).
- Debt: pays down duplicated env parsing logic and ambiguous diagnostics.
- Refactor suggestion (if any): if more runtime toggles are added, consolidate mode + flag parsing under one typed runtime config boundary.

## Notes / Open questions
- Assumption: the project should keep current strict boolean contract (`"true"` is the only enabling value after normalization).
