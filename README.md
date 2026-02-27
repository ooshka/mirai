# mirai
Personal OS

## Read-only MCP endpoints

The app exposes a minimal read-only notes API backed by `NOTES_ROOT`.

- `GET /mcp/notes`
  - Returns all markdown notes under `NOTES_ROOT` as relative paths.
  - Response shape: `{ "notes": ["path/to/note.md"] }`

- `GET /mcp/notes/read?path=relative/path.md`
  - Reads one markdown note under `NOTES_ROOT`.
  - Response shape: `{ "path": "relative/path.md", "content": "..." }`

### Safety constraints

All note reads are validated before touching disk:

- paths are treated as untrusted input
- absolute paths are rejected
- traversal outside `NOTES_ROOT` is rejected
- only `.md` files are allowed

Error responses:

- invalid path: HTTP `400`, code `invalid_path`
- invalid extension: HTTP `400`, code `invalid_extension`
- missing file: HTTP `404`, code `not_found`

## MCP patch endpoints

The app also exposes a constrained patch workflow for markdown notes under `NOTES_ROOT`.

- `POST /mcp/patch/propose`
  - Validates a unified diff payload without writing.
  - Request JSON: `{ "patch": "..." }`
  - Response shape: `{ "path": "relative/path.md", "hunk_count": 1, "net_line_delta": 2 }`

- `POST /mcp/patch/apply`
  - Validates and applies the patch to an existing markdown note.
  - Request JSON: `{ "patch": "..." }`
  - Response shape: `{ "path": "relative/path.md", "hunk_count": 1, "net_line_delta": 2 }`

### Patch constraints

- only single-file unified diffs are supported
- both file headers must target the same path
- only `.md` files under `NOTES_ROOT` are allowed
- malformed/unsupported patch shapes are rejected

### Patch error responses

- invalid patch shape: HTTP `400`, code `invalid_patch`
- invalid path: HTTP `400`, code `invalid_path`
- invalid extension: HTTP `400`, code `invalid_extension`
- missing target file: HTTP `404`, code `not_found`
- patch conflict: HTTP `409`, code `conflict`
- git commit failure: HTTP `500`, code `git_error`
