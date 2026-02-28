# Backlog

## Next 3 Candidate Slices

1. Retrieval Scoring Strategy Seam (selected)
- Value: isolates ranking policy behind a small boundary so retrieval evolution (semantic scoring later) does not bloat `NotesRetriever`.
- Size: ~0.5-1 day.

2. Index Lifecycle Controls (manual invalidate + status)
- Value: reduces stale-artifact ambiguity by making index freshness and operator controls explicit.
- Size: ~0.5-1 day.

3. Patch Parser Extraction (if grammar expansion continues)
- Value: contains diff-format complexity by separating syntax parsing from policy validation before parser growth becomes fragile.
- Size: ~0.5-1 day.
