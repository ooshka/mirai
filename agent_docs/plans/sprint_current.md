# Current Sprint

## Active Case
No active case.

## Sprint Goal
Stabilize retrieval provider wiring after semantic-mode integration:
- extract mode/config selection from `NotesRetriever` into a dedicated provider factory
- preserve lexical-default and semantic-fallback behavior with no query contract drift
- keep retrieval internals ready for additional provider modes without route/action branching
