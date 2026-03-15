# Agent Docs

Lightweight planning artifacts for incremental, agent-executable work.

Planning posture for this repo:
- Treat contract clarity as more important than temporary backward compatibility while the consumer surface remains small and controlled.
- Prefer coordinated contract refactors over additive compatibility layers when duplication would create ambiguity or sticky debt.
- When a planned slice changes a public contract, update the relevant Case, backlog/roadmap language, request specs, and README notes together.

## Structure
- `cases/`: executable case files
- `plans/backlog.md`: prioritized candidate slices
- `plans/roadmap.md`: short directional roadmap
- `plans/tech_debt_log.md`: structural debt and refactor signals
- `testing/README.md`: testing infrastructure and verification commands for agents
