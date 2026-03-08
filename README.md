# mirai

Experimental Sinatra backend for safe, git-backed markdown note operations and deterministic retrieval primitives.

## What this service does

- Reads markdown notes from a separate notes repository mounted at `NOTES_ROOT` (app default: `/notes`; Docker Compose sets `/notes_repo/notes`).
- Applies validated unified-diff patches to notes and commits changes in the notes repo.
- Builds and queries a deterministic lexical index, persisted as an artifact under `NOTES_ROOT/.mirai/index.json`.

The runtime model is treated as untrusted and can only mutate notes through constrained endpoints.

## Stack

- Ruby + Sinatra
- RSpec (`rack-test`) for request/service coverage
- Docker Compose for reproducible local runtime

## Service/spec layout

- `app/services/mcp/` keeps MCP action/policy adapters.
- `app/services/notes/`, `app/services/patch/`, `app/services/indexing/`, and `app/services/retrieval/` group core domain services.
- `spec/services/<domain>/` mirrors those domain folders for unit-level service tests.

## Local development

Start the app:

```bash
docker compose up
```

Run tests:

```bash
docker compose run --rm dev bundle exec rspec
```

Run local smoke workflow.

Canonical Docker command (with app running via `docker compose up`):

```bash
docker compose exec -T dev bash -lc 'BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh'
```

Optional host command:

```bash
BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh
```

Upload notes chunks to an OpenAI vector store (for semantic E2E tests):

```bash
OPENAI_API_KEY=sk-... \
MCP_OPENAI_VECTOR_STORE_ID=vs_... \
ruby scripts/upload_openai_vector_store_chunks.rb --dry-run
```

Then run the real upload:

```bash
OPENAI_API_KEY=sk-... \
MCP_OPENAI_VECTOR_STORE_ID=vs_... \
ruby scripts/upload_openai_vector_store_chunks.rb
```

Useful flags:
- `--notes-root <path>` (defaults to `../notes_repo/notes` outside Docker)
- `--path-prefix animals/` (scope upload to a subtree)
- `--max-chunks 20` (limit upload size for quick tests)
- `--manifest <path>` (write upload mapping for cleanup/audit)

Default container config:

- `NOTES_ROOT=/notes_repo/notes`
- `PORT=4567`
- `MCP_POLICY_MODE=allow_all` (`read_only` denies mutation/index-control actions)
  - Mode is validated at startup; invalid values fail boot with `invalid MCP policy mode: <value>`.
- `MCP_RETRIEVAL_MODE=lexical` (`semantic` enables semantic provider path with lexical fallback)
  - Mode is validated at startup; invalid values fail boot with `invalid MCP retrieval mode: <value>`.
- `MCP_SEMANTIC_PROVIDER_ENABLED=false` (semantic mode falls back to lexical when unavailable)
- `MCP_SEMANTIC_PROVIDER=openai` (semantic adapter selection; currently `openai`)
- `MCP_SEMANTIC_INGESTION_ENABLED=false` (when true, successful patch/apply requests enqueue async OpenAI chunk upserts)
- `MCP_OPENAI_EMBEDDING_MODEL=text-embedding-3-small`
- `MCP_OPENAI_VECTOR_STORE_ID=<vector-store-id>` (required for OpenAI semantic retrieval)
- `OPENAI_API_KEY=<secret>` (required for OpenAI semantic retrieval; never exposed by `/config`)

## HTTP endpoints

### Health/config

- `GET /health` -> `{ "ok": true }`
- `GET /config` -> `{ "notes_root": "/notes", "mcp_policy_mode": "allow_all", "mcp_policy_modes_supported": ["allow_all", "read_only"], "mcp_retrieval_mode": "lexical", "mcp_retrieval_modes_supported": ["lexical", "semantic"], "mcp_semantic_provider_enabled": false, "mcp_semantic_provider": "openai", "mcp_semantic_ingestion_enabled": false, "mcp_openai_embedding_model": "text-embedding-3-small", "mcp_openai_vector_store_id": null, "mcp_openai_configured": false }` (values depend on environment)

### Notes read APIs

- `GET /mcp/notes`
  - Lists markdown files under `NOTES_ROOT`.
  - Response: `{ "notes": ["path/to/note.md"] }`

- `GET /mcp/notes/read?path=relative/path.md`
  - Reads one markdown note.
  - Response: `{ "path": "relative/path.md", "content": "..." }`

- `POST /mcp/notes/read_batch`
  - Reads multiple markdown notes in request order (fail-fast on first invalid/missing path).
  - Request: `{ "paths": ["one.md", "nested/two.md"] }`
  - Response: `{ "notes": [{ "path": "one.md", "content": "..." }, { "path": "nested/two.md", "content": "..." }] }`
  - Validation constraints:
    - `paths` must be a non-empty JSON array.
    - Maximum batch size: `20` paths.
    - Each path must be a non-empty string.

### Patch APIs

- `POST /mcp/patch/propose`
  - Validates a single-file unified diff without writing.
  - Request: `{ "patch": "..." }`
  - Response: `{ "path": "notes/today.md", "hunk_count": 1, "net_line_delta": 1 }`

- `POST /mcp/patch/apply`
  - Validates, applies patch, and commits note changes in the notes git repo.
  - When `MCP_SEMANTIC_INGESTION_ENABLED=true`, successful applies enqueue async semantic chunk upserts for the changed note path.
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
    - `artifact_byte_size` (integer artifact file size in bytes)
    - `chunks_content_bytes_total` (integer total bytes across indexed chunk `content` fields)
  - Response when artifact is missing:
    - `present: false`
    - `generated_at: null`
    - `notes_indexed: null`
    - `chunks_indexed: null`
    - `stale: null`
    - `artifact_age_seconds: null`
    - `notes_present` (integer count of current markdown files)
    - `artifact_byte_size: null`
    - `chunks_content_bytes_total: null`

- `GET /mcp/index/query?q=<text>&limit=<n>&path_prefix=<relative/path>`
  - Queries ranked chunks from persisted artifact when present; falls back to on-demand indexing if artifact is missing.
  - Retrieval mode:
    - `lexical` (default): lexical ranking provider.
    - `semantic`: OpenAI semantic adapter (embedding + vector search) path; falls back to lexical ranking if provider/config is unavailable.
  - Optional `path_prefix` scopes candidate chunks to paths that start with the normalized relative prefix (for example, `nested/`).
  - `path_prefix` must be a string relative to `NOTES_ROOT`; absolute or traversal values return `invalid_query`.
  - Response: `{ "query": "alpha", "limit": 5, "chunks": [{"path":"root.md","chunk_index":0,"content":"alpha beta","score":1,"snippet_offset":{"start":0,"end":5}}] }`
  - `snippet_offset` is additive metadata for grounding hints. `start` is a zero-based inclusive character index and `end` is an exclusive character index (Ruby slice style: `content[start...end]`). It is `null` when no lexical token overlap is found in a returned chunk (for example, semantic hit with non-overlapping text).
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
- `policy_denied` (403)
- `invalid_policy_mode` (500)

## Notes artifact format

`NOTES_ROOT/.mirai/index.json`:

- `version` (currently `1`)
- `generated_at` (ISO8601 UTC timestamp)
- `notes_indexed`
- `chunks_indexed`
- `chunks`: array of `{ path, chunk_index, content }`

Malformed or stale artifact versions are rejected with `invalid_index_artifact`.
