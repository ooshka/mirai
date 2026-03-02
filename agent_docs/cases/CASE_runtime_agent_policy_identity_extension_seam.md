---
case_id: CASE_runtime_agent_policy_identity_extension_seam
created: 2026-03-02
---

# CASE: Runtime-Agent Policy Identity Extension Seam

## Goal
Introduce a small identity-context seam in action policy evaluation so future identity-aware controls can be added without rewriting route/action orchestration.

## Why this next
- Value: reduces future policy churn by adding one clear extension boundary before identity rules are needed.
- Dependency/Risk: derisks upcoming policy work by preventing endpoint-local condition growth.
- Tech debt note: pays down policy/config coupling drift while intentionally keeping enforcement behavior unchanged.

## Definition of Done
- [ ] A small identity-context contract exists for policy checks (for example actor type/source metadata), with deterministic defaults for current unauthenticated runtime.
- [ ] `MCP::ActionPolicy` accepts the identity context through a narrow interface without changing current allow/deny outcomes.
- [ ] Routes/actions pass context via one shared helper path instead of per-endpoint branching.
- [ ] `/config` diagnostics remain stable for current modes; no auth system is introduced.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- Add a dedicated identity-context value object/module with default runtime-agent semantics.
- Thread context into policy enforcement boundaries.
- Add/adjust specs proving behavior parity and seam readiness.

**Out**
- Authentication, user/session management, or multi-user policy rules.
- New policy modes or changed mode semantics.
- Any retrieval/index mutation behavior changes unrelated to policy wiring.

## Proposed approach
Add a minimal identity-context contract in the MCP service layer, with one constructor for current anonymous runtime-agent calls. Update policy evaluation to accept this object and keep existing mode behavior unchanged. Route helpers should create and pass the context once so route modules do not gain policy branching. Cover with focused policy and request specs that assert parity under existing policy modes while validating context plumbing.

## Steps (agent-executable)
1. Add an `MCP` identity-context object with deterministic defaults for current requests.
2. Update `MCP::ActionPolicy` interface to receive identity context and retain current mode decisions.
3. Update shared MCP helper/policy wiring to build and pass identity context once per request flow.
4. Add unit specs for context defaults and policy parity across modes.
5. Add request-level regression specs for at least one allowed and one denied action path.
6. Run targeted specs, then full RSpec.

## Risks / Tech debt / Refactor signals
- Risk: interface changes to policy wiring can introduce endpoint regressions. -> Mitigation: enforce request-spec parity on representative MCP actions.
- Debt: pays down future branching risk by introducing a dedicated policy input seam.
- Refactor suggestion (if any): if identity attributes expand, keep context immutable and move mapping logic to a dedicated adapter.

## Notes / Open questions
- Assumption: current runtime remains effectively single-actor and unauthenticated; this slice prepares the boundary only.
