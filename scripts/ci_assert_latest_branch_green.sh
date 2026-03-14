#!/usr/bin/env bash
set -euo pipefail

current_branch() {
  git branch --show-current
}

latest_run_json() {
  local branch="$1"

  gh run list --branch "$branch" --limit 1 --json conclusion,status --jq '.[0]'
}

BRANCH="$(current_branch)"

if [[ -z "$BRANCH" ]]; then
  printf 'error: could not determine current branch\n' >&2
  exit 1
fi

RUN_JSON="$(latest_run_json "$BRANCH")"

if [[ -z "$RUN_JSON" ]]; then
  printf 'error: no GitHub Actions run found for branch %s\n' "$BRANCH" >&2
  exit 1
fi

STATUS="$(printf '%s' "$RUN_JSON" | jq -r '.status')"
CONCLUSION="$(printf '%s' "$RUN_JSON" | jq -r '.conclusion')"

test "$STATUS" = "completed"
test "$CONCLUSION" = "success"
