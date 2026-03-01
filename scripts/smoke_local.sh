#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:4567}"
CURL_BIN="${CURL_BIN:-curl}"

RESP_STATUS=""
RESP_BODY=""
WORK_DIR="$(mktemp -d)"
PATCH_APPLIED=0
PATCH_REVERTED=0
REVERT_PATCH_PAYLOAD=""
SMOKE_MARKER="mirai-smoke-marker-$$"

log() {
  printf '[smoke] %s\n' "$*"
}

fail() {
  printf '[smoke][error] %s\n' "$*" >&2
  exit 1
}

request() {
  local method="$1"
  local path="$2"
  local data="${3-}"
  local output

  if [[ -n "$data" ]]; then
    output="$("$CURL_BIN" -sS -X "$method" -H "Content-Type: application/json" --data "$data" -w $'\n%{http_code}' "$BASE_URL$path")"
  else
    output="$("$CURL_BIN" -sS -X "$method" -w $'\n%{http_code}' "$BASE_URL$path")"
  fi

  RESP_STATUS="${output##*$'\n'}"
  RESP_BODY="${output%$'\n'*}"
}

assert_status() {
  local expected="$1"
  local context="$2"

  [[ "$RESP_STATUS" == "$expected" ]] || fail "$context (expected status $expected, got $RESP_STATUS, body: $RESP_BODY)"
}

json_assert() {
  local expression="$1"
  local message="$2"

  if ! printf '%s' "$RESP_BODY" | ruby -rjson -e 'data = JSON.parse(STDIN.read); exit(eval(ARGV[0]) ? 0 : 1)' "$expression"; then
    fail "$message (body: $RESP_BODY)"
  fi
}

cleanup() {
  local exit_code=$?
  set +e

  if [[ "$PATCH_APPLIED" -eq 1 && "$PATCH_REVERTED" -eq 0 && -n "$REVERT_PATCH_PAYLOAD" ]]; then
    log "cleanup: attempting reverse patch apply"
    request "POST" "/mcp/patch/apply" "$REVERT_PATCH_PAYLOAD"
    if [[ "$RESP_STATUS" == "200" ]]; then
      PATCH_REVERTED=1
      log "cleanup: reverse patch apply succeeded"
    else
      printf '[smoke][warn] cleanup reverse patch failed (status %s, body: %s)\n' "$RESP_STATUS" "$RESP_BODY" >&2
    fi
  fi

  rm -rf "$WORK_DIR"
  exit "$exit_code"
}

trap cleanup EXIT

log "checking health endpoint"
request "GET" "/health"
assert_status "200" "GET /health"
json_assert 'data["ok"] == true' "health response missing ok=true"

log "checking config endpoint"
request "GET" "/config"
assert_status "200" "GET /config"
json_assert 'data["notes_root"].is_a?(String) && !data["notes_root"].empty?' "config response missing notes_root"

log "listing notes"
request "GET" "/mcp/notes"
assert_status "200" "GET /mcp/notes"
json_assert 'data["notes"].is_a?(Array)' "notes list response missing notes array"

NOTE_PATH="$(printf '%s' "$RESP_BODY" | ruby -rjson -e 'data = JSON.parse(STDIN.read); notes = data.fetch("notes"); abort("no markdown notes available for smoke test") if notes.empty?; print notes.first')"
export SMOKE_NOTE_PATH="$NOTE_PATH"
ENCODED_NOTE_PATH="$(ruby -ruri -e 'print URI.encode_www_form_component(ARGV[0])' "$NOTE_PATH")"

log "reading note: $NOTE_PATH"
request "GET" "/mcp/notes/read?path=$ENCODED_NOTE_PATH"
assert_status "200" "GET /mcp/notes/read"
json_assert 'data["path"] == ENV.fetch("SMOKE_NOTE_PATH")' "read response path mismatch"
ORIGINAL_CONTENT="$(printf '%s' "$RESP_BODY" | ruby -rjson -e 'data = JSON.parse(STDIN.read); print data.fetch("content")')"

ORIGINAL_FILE="$WORK_DIR/original.md"
MODIFIED_FILE="$WORK_DIR/modified.md"
FORWARD_PATCH_FILE="$WORK_DIR/forward.patch"
REVERSE_PATCH_FILE="$WORK_DIR/reverse.patch"
printf '%s' "$ORIGINAL_CONTENT" > "$ORIGINAL_FILE"

ruby -e '
  original = File.binread(ARGV[0])
  updated = original.dup
  updated << "\n" unless updated.empty? || updated.end_with?("\n")
  updated << "#{ARGV[2]}\n"
  File.binwrite(ARGV[1], updated)
' "$ORIGINAL_FILE" "$MODIFIED_FILE" "$SMOKE_MARKER"

diff -u --label "a/$NOTE_PATH" --label "b/$NOTE_PATH" "$ORIGINAL_FILE" "$MODIFIED_FILE" > "$FORWARD_PATCH_FILE" || true
diff -u --label "a/$NOTE_PATH" --label "b/$NOTE_PATH" "$MODIFIED_FILE" "$ORIGINAL_FILE" > "$REVERSE_PATCH_FILE" || true
[[ -s "$FORWARD_PATCH_FILE" ]] || fail "failed to build forward patch"
[[ -s "$REVERSE_PATCH_FILE" ]] || fail "failed to build reverse patch"

FORWARD_PATCH_PAYLOAD="$(ruby -rjson -e 'print JSON.generate({patch: File.read(ARGV[0])})' "$FORWARD_PATCH_FILE")"
REVERT_PATCH_PAYLOAD="$(ruby -rjson -e 'print JSON.generate({patch: File.read(ARGV[0])})' "$REVERSE_PATCH_FILE")"

log "rebuilding index"
request "POST" "/mcp/index/rebuild"
assert_status "200" "POST /mcp/index/rebuild"
json_assert 'data["notes_indexed"].is_a?(Integer) && data["notes_indexed"] >= 1' "rebuild response missing notes_indexed"
json_assert 'data["chunks_indexed"].is_a?(Integer) && data["chunks_indexed"] >= 1' "rebuild response missing chunks_indexed"

log "checking index status after rebuild"
request "GET" "/mcp/index/status"
assert_status "200" "GET /mcp/index/status after rebuild"
json_assert 'data["present"] == true' "status should report artifact present after rebuild"
json_assert 'data["stale"] == false || data["stale"] == true' "status stale field should be boolean when present"
json_assert 'data["artifact_age_seconds"].is_a?(Integer) && data["artifact_age_seconds"] >= 0' "status missing artifact_age_seconds"
json_assert 'data["notes_present"].is_a?(Integer) && data["notes_present"] >= 1' "status missing notes_present"

log "proposing patch"
request "POST" "/mcp/patch/propose" "$FORWARD_PATCH_PAYLOAD"
assert_status "200" "POST /mcp/patch/propose"
json_assert 'data["path"] == ENV.fetch("SMOKE_NOTE_PATH")' "patch propose path mismatch"
json_assert 'data["hunk_count"].is_a?(Integer) && data["hunk_count"] >= 1' "patch propose missing hunk_count"

log "applying patch"
request "POST" "/mcp/patch/apply" "$FORWARD_PATCH_PAYLOAD"
assert_status "200" "POST /mcp/patch/apply"
json_assert 'data["path"] == ENV.fetch("SMOKE_NOTE_PATH")' "patch apply path mismatch"
PATCH_APPLIED=1

log "checking index invalidation after patch apply"
request "GET" "/mcp/index/status"
assert_status "200" "GET /mcp/index/status after patch apply"
json_assert 'data["present"] == false' "status should report missing artifact after patch apply invalidation"

log "rebuilding index after patch apply"
request "POST" "/mcp/index/rebuild"
assert_status "200" "POST /mcp/index/rebuild after patch apply"

QUERY_PARAM="$(ruby -ruri -e 'print URI.encode_www_form_component(ARGV[0])' "$SMOKE_MARKER")"
log "querying rebuilt index"
request "GET" "/mcp/index/query?q=$QUERY_PARAM&limit=1"
assert_status "200" "GET /mcp/index/query"
json_assert 'data["limit"] == 1' "query response limit mismatch"
json_assert 'data["chunks"].is_a?(Array) && !data["chunks"].empty?' "query response missing chunks"
json_assert 'data["chunks"][0]["path"].is_a?(String) && data["chunks"][0]["chunk_index"].is_a?(Integer) && data["chunks"][0]["content"].is_a?(String)' "query chunk shape mismatch"
json_assert 'data["chunks"].any? { |chunk| chunk["path"] == ENV.fetch("SMOKE_NOTE_PATH") }' "query did not include smoke note path"

log "reverting patch for cleanup"
request "POST" "/mcp/patch/apply" "$REVERT_PATCH_PAYLOAD"
assert_status "200" "POST /mcp/patch/apply (cleanup revert)"
PATCH_REVERTED=1

log "smoke test completed successfully"
