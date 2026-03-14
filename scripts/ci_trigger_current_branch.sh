#!/usr/bin/env bash
set -euo pipefail

current_branch() {
  git branch --show-current
}

BRANCH="$(current_branch)"

if [[ -z "$BRANCH" ]]; then
  printf 'error: could not determine current branch\n' >&2
  exit 1
fi

gh workflow run CI --ref "$BRANCH"
