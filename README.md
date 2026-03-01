# mirai

Experimental Sinatra backend for safe, git-backed markdown note operations and deterministic retrieval primitives.

## What this service does

- Reads markdown notes from a separate notes repository mounted at `NOTES_ROOT` (default: `/notes`).
- Applies validated unified-diff patches to notes and commits changes in the notes repo.
- Builds and queries a deterministic lexical index, persisted as an artifact under `NOTES_ROOT/.mirai/index.json`.

The runtime model is treated as untrusted and can only mutate notes through constrained endpoints.

## Stack

- Ruby + Sinatra
- RSpec (`rack-test`) for request/service coverage
- Docker Compose for reproducible local runtime

## Local development

Start the app:

```bash
docker compose up
```

Run tests:

```bash
docker compose run --rm dev bundle exec rspec
```

Default container config:

- `NOTES_ROOT=/notes`
- `PORT=4567`

## HTTP endpoints

### Health/config

- `GET /health` -> `{ "ok": true }`
- `GET /config` -> `{ "notes_root": "/notes" }` (value depends on environment)

### Notes read APIs

- `GET /mcp/notes`
  - Lists markdown files under `NOTES_ROOT`.
  - Response: `{ "notes": ["path/to/note.md"] }`

- `GET /mcp/notes/read?path=relative/path.md`
  - Reads one markdown note.
  - Response: `{ "path": "relative/path.md", "content": "..." }`

### Patch APIs

- `POST /mcp/patch/propose`
  - Validates a single-file unified diff without writing.
  - Request: `{ "patch": "..." }`
  - Response: `{ "path": "notes/today.md", "hunk_count": 1, "net_line_delta": 1 }`

- `POST /mcp/patch/apply`
  - Validates, applies patch, and commits note changes in the notes git repo.
  - Request: `{ "patch": "..." }`
  - Response: `{ "path": "notes/today.md", "hunk_count": 1, "net_line_delta": 1 }`
  - Commit message format: `mcp.patch_apply: <relative-path>`

### Index APIs

- `POST /mcp/index/rebuild`
  - Rebuilds lexical index from notes and writes artifact to `NOTES_ROOT/.mirai/index.json`.
  - Response: `{ "notes_indexed": 2, "chunks_indexed": 3 }`

- `GET /mcp/index/status`
  - Returns index artifact lifecycle status without rebuilding or writing.
  - Response when artifact is present:
    - `present` (boolean)
    - `generated_at` (ISO8601 UTC timestamp)
    - `notes_indexed` (integer)
    - `chunks_indexed` (integer)
    - `stale` (boolean; true when any note mtime is newer than `generated_at`)
    - `artifact_age_seconds` (integer; bounded at zero)
    - `notes_present` (integer count of current markdown files)
  - Response when artifact is missing:
    - `present: false`
    - `generated_at: null`
    - `notes_indexed: null`
    - `chunks_indexed: null`
    - `stale: null`
    - `artifact_age_seconds: null`
    - `notes_present` (integer count of current markdown files)

- `GET /mcp/index/query?q=<text>&limit=<n>`
  - Queries ranked chunks from persisted artifact when present; falls back to on-demand indexing if artifact is missing.
  - Response: `{ "query": "alpha", "limit": 5, "chunks": [...] }`
  - Default limit: `5`, max limit: `50`.

## Safety and error contracts

Filesystem/path safety:

- Treat all paths as untrusted.
- Reject absolute paths and traversal outside `NOTES_ROOT`.
- Only allow `.md` targets.

Patch safety:

- Only single-file unified diffs are supported.
- Patch apply requires clean hunk context and uses git commit as the durability boundary.

Common error payload shape:

```json
{
  "error": {
    "code": "invalid_path",
    "message": "path escapes notes root"
  }
}
```

Important error codes:

- `invalid_path` (400)
- `invalid_extension` (400)
- `invalid_patch` (400)
- `invalid_query` (400)
- `invalid_limit` (400)
- `not_found` (404)
- `conflict` (409)
- `git_error` (500)
- `invalid_index_artifact` (500)

## Notes artifact format

`NOTES_ROOT/.mirai/index.json`:

- `version` (currently `1`)
- `generated_at` (ISO8601 UTC timestamp)
- `notes_indexed`
- `chunks_indexed`
- `chunks`: array of `{ path, chunk_index, content }`

Malformed or stale artifact versions are rejected with `invalid_index_artifact`.
