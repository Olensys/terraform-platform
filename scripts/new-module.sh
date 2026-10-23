#!/usr/bin/env bash
# Create a new module repo from the template and seed its metadata.
# Usage: scripts/new-module.sh <name> <aws|google|common> <description>
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <name> <aws|google|common> <description>" >&2
  exit 2
fi
name=$1; cloud=$2; description=$3

case "$cloud" in aws|google|common) ;; *) echo "cloud must be aws, google or common" >&2; exit 2 ;; esac
case "$description" in *"|"*|*"&"*|*"/"*) echo "description must not contain | & or /" >&2; exit 2 ;; esac

gh repo create "Olensys/$name" --public --template Olensys/terraform-module-template \
  --description "$description" --clone
gh repo edit "Olensys/$name" --add-topic terraform-module
cd "$name"

# Portable in-place edit (BSD and GNU sed).
for f in metadata.yaml README.md; do
  sed -i.bak "s|__NAME__|$name|g; s|__CLOUD__|$cloud|g; s|__DESCRIPTION__|$description|g" "$f"
  rm -f "$f.bak"
done

git commit -am "chore: seed metadata for $name"
git push
