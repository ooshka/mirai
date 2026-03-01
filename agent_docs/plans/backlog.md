# Backlog

## Next 3 Candidate Slices

1. Index Freshness Status Signal (selected)
- Value: makes stale vs fresh artifact state explicit without adding query write side effects.
- Size: ~0.5-1 day.

2. Index Lifecycle + Scale Controls
- Value: reduces operational risk by making rebuild/invalidation behavior easier to automate as notes volume grows.
- Size: ~0.5-1 day.

3. Route Composition Modularization
- Value: prevents `app.rb` from becoming a route orchestration bottleneck as MCP endpoints continue to grow.
- Size: ~0.5-1 day.
