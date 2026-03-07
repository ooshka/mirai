#!/usr/bin/env bash
set -euo pipefail

# Install gems on first run (or after Gemfile changes) before executing command.
if ! bundle check >/dev/null 2>&1; then
  echo "Installing missing gems with bundle install..."
  bundle install
fi

exec "$@"
