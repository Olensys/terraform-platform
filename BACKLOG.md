# Backlog

Work that is agreed but not started. One line of context per item; details live in the linked docs.

## Promote the remaining experimental modules

Six modules are `experimental` only because their integration apply needs an input the test accounts do not have. Everything else about them (code, unit tests, CI) is green.

| Module | Needs | Unblocked by |
|---|---|---|
| terraform-aws-acm-certificate | DNS validation of a certificate | a test subdomain with DNS we control |
| terraform-aws-static-site | `certificate_arn`, `domain_names` | the ACM certificate above |
| terraform-aws-alb | `certificate_arn` | the ACM certificate above |
| terraform-google-https-lb | `domain`, `service_name` | the subdomain plus a Cloud Run service in the test project |
| terraform-aws-http-api | `lambda_arn` | a Lambda in the test account, or let the example create one |
| terraform-cloudflare-dns | a zone and an API token | the subdomain delegated to Cloudflare, token stored as an org secret |

Plan: delegate one throwaway subdomain to Cloudflare, store `CLOUDFLARE_API_TOKEN` and `TF_VAR_zone_id` at org level, validate the ACM example through Cloudflare, reuse the certificate for ALB and static-site, point the HTTPS load balancer at a record in that subdomain, make the HTTP API example create its own Lambda. Two green runs each, then one-line promotion PRs.

## Release automation

- Store a fine-grained PAT as org secret `RELEASE_PLEASE_TOKEN` so release PRs are authored by a user and run CI (today bot PRs wait for approval and show as failed runs when merged with the admin bypass).
- Once that PAT exists, add the `creation` rule back to the `release-tags` ruleset in `scripts/protect-main.sh`.

## Integration trigger and docs hygiene

- Add `examples/**` to the integration `paths` filter in the 30 repos that do not have it yet (template, lambda-function and cloud-function already do).
- Replace stale "nightly" wording in `tests/complete.tftest.hcl` headers and READMEs (about 40 files) with the on-change plus weekly cadence.

## Central configuration as code

A private `terraform-ops` stack using the GitHub provider that writes org secrets and `TF_VAR_*` variables from the test-account bootstrap outputs, with remote state in the test project's bucket. Today those values are set by hand with `gh`.

## Identity hardening (optional)

Add `owner_id` and `repository_id` inputs to the two GitHub identity modules so trust can bind on exact immutable subjects instead of `@*` wildcards.

## Budget hard stop on GCP

The budget and alerts exist; the stop-billing function that detaches billing at 100 percent is not deployed. Deploy it if a hard cap is wanted (see docs/runbooks/test-accounts.md A.1 step 5).

## Follow-ups from the section 1 fix wave (2026-10-25)

- Upgrade order for consumers: terraform-cloudflare-dns ≥ 1.1.0 before terraform-aws-ses-domain ≥ 1.1.0 (the MX record now carries `priority`, which older cloudflare-dns silently drops, so the record plans but fails at apply).
- terraform-aws-acm-certificate: `validation_records` is keyed by record names that are known only after the certificate exists, so a fresh deploy that feeds it into terraform-cloudflare-dns needs a two-step apply (`-target=module.cert` first). A redesign keyed by something known at plan time would remove that step.
- terraform-cloudflare-dns: SRV records need weight, port and target (the provider's `data` block), which the module does not expose; only MX priority is usable today.

## Blueprints and rich examples

Compose the modules into opinionated, end-to-end blueprints (one per typical workload per cloud) and add `examples/complete` to the modules that only have `examples/minimal`. Starts with a design conversation; nothing decided yet.
