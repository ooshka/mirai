# Current Sprint

## Active Case
No active case.

## Sprint Goal
Introduce a centralized runtime-agent action policy seam:
- allow safe read/status MCP operations while keeping mutation/index-control actions policy-gated
- keep policy enforcement explicit and service-level testable, not route-scattered
- preserve existing endpoint contracts for allowed actions and deterministic error contracts for denied actions
