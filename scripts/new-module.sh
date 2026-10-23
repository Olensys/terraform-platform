#!/usr/bin/env bash
# Create a new module repo from the template and seed it.
# Usage: scripts/new-module.sh <name> <aws|google|common> <description>
#
# Testing the seeding logic without GitHub:
#   NEW_MODULE_SEED_DIR=<checkout of the template> scripts/new-module.sh <name> <cloud> <description>
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <name> <aws|google|common> <description>" >&2
  exit 2
fi
name=$1; cloud=$2; description=$3

case "$cloud" in aws|google|common) ;; *) echo "cloud must be aws, google or common" >&2; exit 2 ;; esac
case "$description" in *"|"*|*"&"*|*"/"*) echo "description must not contain | & or /" >&2; exit 2 ;; esac

# Remove `plugin "<id>" { ... }` (and the comment line directly above it) from .tflint.hcl.
drop_tflint_plugin() {
  awk -v id="$1" '
    /^# Delete the ruleset you do not use\.$/ { held = $0; next }
    $0 == "plugin \"" id "\" {" { held = ""; skip = 1; next }
    skip { if ($0 ~ /^}/) { skip = 0 } ; next }
    { if (held != "") { print held; held = "" } print }
  ' .tflint.hcl > .tflint.hcl.tmp && mv .tflint.hcl.tmp .tflint.hcl
}

# Run inside the checked-out repo: replace placeholders everywhere, tailor per cloud, verify.
seed_repo() {
  local f
  git ls-files -z | xargs -0 grep -Il --null -e '__NAME__' -e '__CLOUD__' -e '__DESCRIPTION__' 2>/dev/null |
    while IFS= read -r -d '' f; do
      # Portable in-place edit (BSD and GNU sed).
      sed -i.bak "s|__NAME__|$name|g; s|__CLOUD__|$cloud|g; s|__DESCRIPTION__|$description|g" "$f"
      rm -f "$f.bak"
    done || true

  case "$cloud" in
    common)
      rm -f .github/workflows/integration.yml
      drop_tflint_plugin aws
      drop_tflint_plugin google
      ;;
    aws) drop_tflint_plugin google ;;
    google) drop_tflint_plugin aws ;;
  esac
  # Drop the leftover "delete the ruleset" hints.
  sed -i.bak '/^# Delete the ruleset you do not use\.$/d' .tflint.hcl && rm -f .tflint.hcl.bak

  if git grep -n '__[A-Z]*__' -- . ':!LICENSE'; then
    echo "error: template placeholders remain (listed above)" >&2
    exit 1
  fi
}

if [ -n "${NEW_MODULE_SEED_DIR:-}" ]; then
  cd "$NEW_MODULE_SEED_DIR"
  seed_repo
  exit 0
fi

gh repo create "Olensys/$name" --public --template Olensys/terraform-module-template \
  --description "$description" --clone
gh repo edit "Olensys/$name" --add-topic terraform-module
cd "$name"
seed_repo
git add -A
git commit -m "chore: seed metadata for $name"
git push
