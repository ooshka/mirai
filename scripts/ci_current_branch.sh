#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ci_current_branch.sh <command>

Commands:
  push     Push the current branch to origin and set upstream.
  trigger  Manually trigger the CI workflow for the current branch.
  list     List recent CI runs for the current branch.
  view     View the latest CI run for the current branch.
  watch    Watch the latest CI run for the current branch.
  assert   Exit zero only when the latest CI run completed successfully.
  verify   Push the current branch, wait for the HEAD run, and require success.
EOF
}

current_branch() {
  git branch --show-current
}

current_head_sha() {
  git rev-parse HEAD
}

latest_run_id() {
  local branch="$1"

  gh run list --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId'
}

latest_run_json() {
  local branch="$1"

  gh run list --branch "$branch" --limit 1 --json conclusion,status --jq '.[0]'
}

latest_run_id_for_head() {
  local branch="$1"
  local sha="$2"

  gh run list --branch "$branch" --limit 20 --json databaseId,headSha |
    jq -r --arg sha "$sha" 'map(select(.headSha == $sha))[0].databaseId // empty'
}

require_branch() {
  BRANCH="$(current_branch)"

  if [[ -z "$BRANCH" ]]; then
    printf 'error: could not determine current branch\n' >&2
    exit 1
  fi
}

require_run_id() {
  local run_id="$1"

  if [[ -z "$run_id" ]]; then
    printf 'error: no GitHub Actions run found for branch %s\n' "$BRANCH" >&2
    exit 1
  fi
}

push_branch() {
  git push -u origin "$BRANCH"
}

trigger_workflow() {
  gh workflow run CI --ref "$BRANCH"
}

wait_for_head_run_id() {
  local sha="$1"
  local attempts=20
  local delay_seconds=3
  local run_id=""

  for (( attempt = 1; attempt <= attempts; attempt += 1 )); do
    run_id="$(latest_run_id_for_head "$BRANCH" "$sha")"

    if [[ -n "$run_id" ]]; then
      printf '%s\n' "$run_id"
      return 0
    fi

    sleep "$delay_seconds"
  done

  printf 'error: no GitHub Actions run found for HEAD %s on branch %s\n' "$sha" "$BRANCH" >&2
  exit 1
}

verify_head_run() {
  local sha="$1"
  local run_id

  run_id="$(wait_for_head_run_id "$sha")"
  gh run watch "$run_id"
  test "$(gh run view "$run_id" --json conclusion --jq '.conclusion')" = "success"
}

COMMAND="${1:-}"

if [[ -z "$COMMAND" ]]; then
  usage >&2
  exit 1
fi

require_branch

case "$COMMAND" in
  push)
    push_branch
    ;;
  trigger)
    trigger_workflow
    ;;
  list)
    gh run list --branch "$BRANCH" --limit 10
    ;;
  view)
    RUN_ID="$(latest_run_id "$BRANCH")"
    require_run_id "$RUN_ID"
    gh run view "$RUN_ID"
    ;;
  watch)
    RUN_ID="$(latest_run_id "$BRANCH")"
    require_run_id "$RUN_ID"
    gh run watch "$RUN_ID"
    ;;
  assert)
    RUN_JSON="$(latest_run_json "$BRANCH")"

    if [[ -z "$RUN_JSON" ]]; then
      printf 'error: no GitHub Actions run found for branch %s\n' "$BRANCH" >&2
      exit 1
    fi

    STATUS="$(printf '%s' "$RUN_JSON" | jq -r '.status')"
    CONCLUSION="$(printf '%s' "$RUN_JSON" | jq -r '.conclusion')"

    test "$STATUS" = "completed"
    test "$CONCLUSION" = "success"
    ;;
  verify)
    HEAD_SHA="$(current_head_sha)"
    push_branch
    verify_head_run "$HEAD_SHA"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    printf 'error: unknown command %s\n\n' "$COMMAND" >&2
    usage >&2
    exit 1
    ;;
esac
