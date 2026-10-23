#!/usr/bin/env bash
# List who consumes Olensys modules: repo, file, pinned ref.
#
# Usage: scripts/consumers.sh [module-name]
#   module-name  e.g. terraform-aws-s3-bucket; omit to list every Olensys module source.
# Env:  WORKSPACE  directory to search (default: $HOME/workspace)
set -euo pipefail

workspace=${WORKSPACE:-$HOME/workspace}
module=${1:-}

if [ ! -d "$workspace" ]; then
  echo "workspace not found: $workspace" >&2
  exit 1
fi

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
printf 'REPO\tFILE\tREF\n'
if [ -n "$module" ]; then
  pattern="source[[:space:]]*=.*Olensys/${module}([.\"?/&[:space:]]|\$)"
else
  pattern="source[[:space:]]*=.*Olensys/terraform-"
fi
{ grep -rnE --include='*.tf' --include='*.hcl' --include='*.tofu' \
  --exclude-dir=.terraform --exclude-dir=.git --exclude-dir=node_modules \
  "$pattern" "$workspace" 2>/dev/null || true; } |
while IFS= read -r hit; do
  file=${hit%%:*}
  rest=${hit#*:}; rest=${rest#*:}
  ref=$(printf '%s' "$rest" | sed -n 's/.*[?&]ref=\([^"&]*\).*/\1/p')
  dir=$(dirname "$file")
  repo=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)
  repo=$(basename "${repo:-$dir}")
  printf '%s\t%s\t%s\n' "$repo" "${file#"$workspace"/}" "${ref:-"(none)"}"
done > "$tmp"
cat "$tmp"
if [ ! -s "$tmp" ]; then echo "no consumers found" >&2; fi
