#!/usr/bin/env bash
# Apply a script to every module repo and open a pull request in each.
#
# Usage: scripts/fleet.sh "<pr title>" <path-to-script> [extra multi-gitter flags]
# Example: scripts/fleet.sh "chore: bump workflow pin" ./bump-workflow-pin.sh
#
# The PR title is also used as the commit message and the branch is derived from it.
# Module repos are every Olensys repo with the `terraform-module` topic.
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: $0 \"<pr title>\" <script> [multi-gitter flags]" >&2
  exit 2
fi

if ! command -v multi-gitter >/dev/null 2>&1; then
  cat >&2 <<'MSG'
multi-gitter is not installed.
Install it with one of:
  brew install lindell/multi-gitter/multi-gitter
  go install github.com/lindell/multi-gitter@latest
See https://github.com/lindell/multi-gitter
MSG
  exit 1
fi

title=$1; script=$2; shift 2
export GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token)}"

repos=$(gh repo list Olensys --topic terraform-module --limit 200 --json name --jq '.[].name' | sed 's|^|Olensys/|' | paste -sd, -)
if [ -z "$repos" ]; then
  echo "no repos with topic terraform-module found" >&2
  exit 1
fi

branch="fleet/$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//' | cut -c1-50)"

multi-gitter run "$script" \
  --repo "$repos" \
  --branch "$branch" \
  --commit-message "$title" \
  --pr-title "$title" \
  "$@"
