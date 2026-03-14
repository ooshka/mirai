#!/usr/bin/env bash
set -euo pipefail

current_branch() {
  git branch --show-current
}

latest_run_id() {
  local branch="$1"

  gh run list --branch "$branch" --limit 1 --json databaseId --jq '.[0].databaseId'
}

BRANCH="$(current_branch)"

if [[ -z "$BRANCH" ]]; then
  printf 'error: could not determine current branch\n' >&2
  exit 1
fi

RUN_ID="$(latest_run_id "$BRANCH")"

if [[ -z "$RUN_ID" ]]; then
  printf 'error: no GitHub Actions run found for branch %s\n' "$BRANCH" >&2
  exit 1
fi

gh run view "$RUN_ID"
