# mirai

Experimental Sinatra backend for safe, git-backed markdown note operations and deterministic retrieval primitives.

## Contract posture

This project is still in an early contract-shaping phase.

- Prefer clean, explicit API contracts over compatibility layers that preserve ambiguous or duplicative response shapes.
- Breaking contract changes are acceptable when they reduce design debt and the affected consumers can be updated in a coordinated way.
- The expected external consumer set is intentionally small: hosted-provider integration owned here plus the self-hosted path being developed in `../local_llm`.
- When a contract changes, update repo docs, request specs, and any known consumer notes or fixtures in the same planning/implementation cycle rather than carrying long-lived compatibility shims by default.

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
- `app/services/notes/`, `app/services/patch/`, `app/services/indexing/`, `app/services/retrieval/`, and `app/services/llm/` group core domain services.
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

Run lint:

```bash
docker compose run --rm dev bundle exec standardrb
```

## Branch CI

GitHub Actions runs the full `bundle exec rspec` suite and `bundle exec standardrb` on every branch push and via manual dispatch. This is the independent clean-environment verification signal for the current branch/reviewer workflow; local Docker-based commands remain the canonical development path.

Run local workflow smoke.

Prerequisites:
- App running via `docker compose up` (or equivalent).
- Notes mount contains at least one markdown file.
- Workflow planning is enabled and both workflow providers are set to `local`.
- `MCP_LOCAL_WORKFLOW_BASE_URL` points at a reachable OpenAI-compatible workflow runtime.
- `MCP_OPENAI_WORKFLOW_MODEL` is set to a local workflow model name available on that runtime (for example `qwen2.5:7b-instruct`).

Example app startup for the self-hosted workflow smoke path:

```bash
MCP_WORKFLOW_PLANNER_ENABLED=true \
MCP_WORKFLOW_PLANNER_PROVIDER=local \
MCP_WORKFLOW_DRAFTER_PROVIDER=local \
MCP_OPENAI_WORKFLOW_MODEL=qwen2.5:7b-instruct \
MCP_LOCAL_WORKFLOW_BASE_URL=http://<workflow-host>:<port> \
docker compose up
```

Canonical Docker command (with app running via `docker compose up`):

```bash
docker compose exec -T dev bash -lc 'BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh'
```

Optional host command:

```bash
BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh
```

The smoke script now validates the local workflow planner-to-drafter handoff before the existing patch apply path. It fails fast when workflow planning is disabled or the planner/drafter providers are not configured for the self-hosted path.

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
- `MCP_SEMANTIC_PROVIDER=openai` (semantic adapter selection; supported: `openai`, `local`)
- `MCP_LOCAL_SEMANTIC_BASE_URL=<base-url>` (required for `MCP_SEMANTIC_PROVIDER=local`; expected to expose a retrieval query endpoint returning ranked chunk records aligned with the `local_llm` retrieval artifact contract)
- `MCP_SEMANTIC_INGESTION_ENABLED=false` (when true, successful patch/apply requests enqueue async OpenAI chunk upserts)
- `MCP_OPENAI_EMBEDDING_MODEL=text-embedding-3-small`
- `MCP_OPENAI_VECTOR_STORE_ID=<vector-store-id>` (required for OpenAI semantic retrieval)
- `MCP_WORKFLOW_PLANNER_ENABLED=false` (when true, enables planning-only LLM workflow endpoint)
- `MCP_WORKFLOW_PLANNER_PROVIDER=openai` (planner adapter selection; supported: `openai`, `local`)
- `MCP_WORKFLOW_DRAFTER_PROVIDER=openai` (draft-patch adapter selection; supported: `openai`, `local`)
- `MCP_OPENAI_WORKFLOW_MODEL=gpt-4.1-mini` (planner model name passed to the selected workflow planner adapter)
- `MCP_LOCAL_WORKFLOW_BASE_URL=<base-url>` (required for `MCP_WORKFLOW_PLANNER_PROVIDER=local` or `MCP_WORKFLOW_DRAFTER_PROVIDER=local`; expected to expose an OpenAI-compatible `/v1/chat/completions` workflow endpoint aligned with the `local_llm` planner and draft smoke contracts)
- `OPENAI_API_KEY=<secret>` (required for OpenAI semantic retrieval/workflow planning; never exposed by `/config`)

## HTTP endpoints

### Health/config

- `GET /health` -> `{ "ok": true }`
- `GET /config` -> `{ "notes_root": "/notes", "mcp_policy_mode": "allow_all", "mcp_policy_modes_supported": ["allow_all", "read_only"], "mcp_retrieval_mode": "lexical", "mcp_retrieval_modes_supported": ["lexical", "semantic"], "mcp_semantic_provider_enabled": false, "mcp_semantic_provider": "openai", "mcp_semantic_configured": false, "mcp_semantic_ingestion_enabled": false, "mcp_openai_embedding_model": "text-embedding-3-small", "mcp_openai_vector_store_id": null, "mcp_openai_configured": false, "mcp_local_semantic_base_url": null, "mcp_local_semantic_configured": false, "mcp_workflow_planner_enabled": false, "mcp_workflow_planner_provider": "openai", "mcp_workflow_drafter_provider": "openai", "mcp_openai_workflow_model": "gpt-4.1-mini", "mcp_openai_workflow_configured": false, "mcp_local_workflow_base_url": null, "mcp_local_workflow_configured": false, "mcp_workflow_planner_configured": false, "mcp_workflow_drafter_configured": false }` (values depend on environment)

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
  - Response: `{ "query": "alpha", "limit": 5, "chunks": [{"content":"alpha beta","score":1,"metadata":{"path":"root.md","chunk_index":0,"snippet_offset":{"start":0,"end":5}},"explanation":{"matched_terms":["alpha"],"matched_term_count":1}}] }`
  - `metadata` is the canonical grounding metadata for each chunk. Query results no longer expose `path`, `chunk_index`, or `snippet_offset` at top level.
  - `explanation` is the canonical bounded match-rationale container. `matched_terms` lists unique query tokens with token-boundary matches in the returned chunk content, in query order. `matched_term_count` is the size of that list.
  - `metadata.snippet_offset` is a grounding hint. `start` is a zero-based inclusive character index and `end` is an exclusive character index (Ruby slice style: `content[start...end]`). It is `null` when no lexical token overlap is found in a returned chunk (for example, semantic hit with non-overlapping text).
  - Default limit: `5`, max limit: `50`.

### Workflow Planning API

- `POST /mcp/workflow/plan`
  - Produces a planning-only MCP action sequence for a natural-language intent.
  - Request: `{ "intent": "update today's note", "context": { ...optional object... } }`
  - Optional context hint: `context.path` (`.md` relative path) asks the server to include a bounded note preview and retrieval/index status snapshot in planner context.
  - Canonical draft handoff action: `{"action":"workflow.draft_patch","reason":"...","params":{"instruction":"...","path":"notes/today.md","context":{...optional object...}}}`
  - Response: `{ "intent": "...", "provider": "openai|local", "rationale": "...", "actions": [{"action":"notes.read","reason":"...","params":{"path":"notes/today.md"}},{"action":"workflow.draft_patch","reason":"...","params":{"instruction":"...","path":"notes/today.md","context":{"source":"planner"}}}] }`
  - Safety note: this endpoint does not execute actions; it returns proposed steps only.

- `POST /mcp/workflow/draft_patch`
  - Produces a dry-run single-file unified diff draft from an instruction and explicit target path.
  - Request: `{ "action": "workflow.draft_patch", "params": { "instruction": "add today's summary", "path": "notes/today.md", "context": { ...optional object... } } }`
  - Response: `{ "patch": "--- a/notes/today.md\n+++ b/notes/today.md\n..." }`
  - Provider note: the drafter path follows `MCP_WORKFLOW_DRAFTER_PROVIDER`. When set to `local`, `mirai` sends the same bounded request to `MCP_LOCAL_WORKFLOW_BASE_URL` and normalizes either a raw unified diff or a JSON `{ "patch": "..." }` response down to the existing patch string contract.
  - Safety note: this endpoint validates draft shape but does not apply/commit changes.

- `POST /mcp/workflow/apply_patch`
  - Produces and applies a single-file unified diff from the canonical `workflow.draft_patch` action envelope.
  - Request: `{ "action": "workflow.draft_patch", "params": { "instruction": "add today's summary", "path": "notes/today.md", "context": { ...optional object... } } }`
  - Response: `{ "path": "notes/today.md", "hunk_count": 1, "net_line_delta": 1, "patch": "--- a/notes/today.md\n+++ b/notes/today.md\n..." }`
  - Contract note: this endpoint reuses the draft-request contract from `/mcp/workflow/draft_patch` and the mutation safety boundary from `/mcp/patch/apply`; operators can apply a planner-produced `workflow.draft_patch` action without reshaping the payload.
  - Policy note: this path is treated as a mutation and is denied in `read_only` mode.

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
- `invalid_workflow_intent` (400)
- `invalid_workflow_draft` (400)
- `planner_unavailable` (503)
- `draft_unavailable` (503)
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
