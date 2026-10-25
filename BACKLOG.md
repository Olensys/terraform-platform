# Backlog

Work that is agreed but not started. One line of context per item; details live in the linked docs.

## Follow-ups from the promotion wave

- Cloudflare DNS records created by examples have no sweeper handle; a `comment = "olensys-test"` on every example record plus a weekly sweep via the API would close that gap.
- The shared integration workflow exports every `TF_VAR_*` org/repo variable to every run; `terraform test` parses the value of an undeclared variable as HCL, so dotted values (domains) must stay repo-scoped. Skipping variables the example does not declare would remove that constraint.
- `CLOUDFLARE_API_TOKEN` is visible to all repos; narrowing it to the five repos that use it (`--visibility selected`) is an owner item.
- terraform-google-https-lb example: the Cloud Run service has no `roles/run.invoker` binding, so the load balancer answers 403 at runtime; the apply/destroy gate is unaffected.

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
