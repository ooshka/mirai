#!/usr/bin/env bash
set -euo pipefail

ruby workflow_operator.rb \
  --instruction "Please add a sub-section to the tofu cooking to describe the pan technique" \
  --path today.md \
  --profile local \
  --apply \
  --yes
