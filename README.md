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
