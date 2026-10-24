#!/usr/bin/env bash
# Apply branch and tag rulesets to Olensys terraform-* repositories.
# Usage: protect-main.sh [--dry-run] [repo...]   (default: every Olensys/terraform-* repo)
set -euo pipefail

ORG="Olensys"
ACTIONS_APP_ID=15368
dry_run=false
repos=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    -h|--help) echo "usage: $0 [--dry-run] [repo...]"; exit 0 ;;
    *) repos+=("$arg") ;;
  esac
done

if [ "${#repos[@]}" -eq 0 ]; then
  while IFS= read -r r; do repos+=("$r"); done < <(gh repo list "$ORG" --limit 200 --json name -q '.[].name | select(startswith("terraform-"))' | sort)
fi

branch_json() {
  local with_checks=$1
  jq -n --argjson checks "$with_checks" --argjson app "$ACTIONS_APP_ID" '
    {name: "main-protection", target: "branch", enforcement: "active",
     conditions: {ref_name: {include: ["~DEFAULT_BRANCH"], exclude: []}},
     bypass_actors: [{actor_id: 1, actor_type: "OrganizationAdmin", bypass_mode: "pull_request"}],
     rules: ([
       {type: "deletion"}, {type: "non_fast_forward"}, {type: "required_linear_history"},
       {type: "pull_request", parameters: {
         required_approving_review_count: 1, dismiss_stale_reviews_on_push: true,
         require_code_owner_review: false, require_last_push_approval: false,
         required_review_thread_resolution: true,
         allowed_merge_methods: ["squash"]}}]
       + (if $checks then [{type: "required_status_checks", parameters: {
           strict_required_status_checks_policy: true,
           required_status_checks: [
             {context: "ci / Static checks", integration_id: $app},
             {context: "ci / Validate and test (terraform)", integration_id: $app},
             {context: "ci / Validate and test (tofu)", integration_id: $app}]}}] else [] end))}'
}

tag_json() {
  jq -n '
    {name: "release-tags", target: "tag", enforcement: "active",
     conditions: {ref_name: {include: ["refs/tags/v*"], exclude: []}},
     # No creation rule: release-please creates tags with github.token; existing tags cannot be moved or deleted.
     bypass_actors: [{actor_id: 1, actor_type: "OrganizationAdmin", bypass_mode: "always"}],
     rules: [{type: "update"}, {type: "deletion"}, {type: "non_fast_forward"}]}'
}

apply() { # repo name json
  local repo=$1 name=$2 json=$3 id
  if $dry_run; then
    echo "--- $ORG/$repo ruleset $name"; echo "$json"; return
  fi
  id=$(gh api "repos/$ORG/$repo/rulesets" --jq ".[] | select(.name == \"$name\") | .id")
  if [ -n "$id" ]; then
    echo "$json" | gh api -X PUT "repos/$ORG/$repo/rulesets/$id" --input - --jq '"updated \(.name) (\(.id))"'
  else
    echo "$json" | gh api -X POST "repos/$ORG/$repo/rulesets" --input - --jq '"created \(.name) (\(.id))"'
  fi
}

for repo in "${repos[@]}"; do
  repo=${repo#"$ORG/"}
  # Repos without a ci.yml (terraform-platform, terraform-workflows) get no status-check rule.
  if out=$(gh api "repos/$ORG/$repo/contents/.github/workflows/ci.yml" --silent 2>&1); then
    checks=true
  elif grep -q "HTTP 404" <<<"$out"; then
    checks=false
  else
    echo "error: cannot determine whether $repo has ci.yml: $out" >&2
    exit 1
  fi
  echo "== $repo (status checks: $checks)"
  apply "$repo" main-protection "$(branch_json "$checks")"
  if [ "$repo" = "terraform-workflows" ]; then
    echo "skipped tag ruleset"
  else
    apply "$repo" release-tags "$(tag_json)"
  fi
done
