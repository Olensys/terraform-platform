# Conventions

## Repository layout

```
main.tf            resources and module calls
variables.tf       inputs, ordered per docs/interface.md
outputs.tf         outputs per the output contract
versions.tf        terraform and provider constraints
metadata.yaml      catalog metadata (read by scripts/catalog.py)
examples/minimal/  smallest working usage, exercised in CI
tests/             terraform test files (*.tftest.hcl)
README.md          usage, inputs and outputs
```

The primary resource is named `this` (`aws_s3_bucket.this`). Multiple resources of the same type use descriptive names.

## Version constraints

- `required_version = ">= 1.5.0"` (compatible with Terraform and OpenTofu).
- Providers: `aws >= 6.0, < 7.0`; `google >= 6.0, < 8.0`; `cloudflare >= 5.0, < 6.0`; `random >= 3.5, < 4.0`.
- Upstream registry modules are pinned to an exact version (`version = "6.0.0"`, no ranges).

## metadata.yaml

```yaml
name: <repo name>
cloud: aws | google | common
tier: primitive | capability | blueprint
maturity: experimental | stable | deprecated
description: <one line>
owners: [platform]
upstream: null | "<registry source> <version>"
pairs_with: null | "<repo name>"
registry_name: <repo name>
deprecated: null | { removal: YYYY-MM-DD, replacement: <repo> }
```

## Commits and releases

- Commits follow Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, with `!` or a `BREAKING CHANGE:` footer for breaking changes.
- Releases are cut from `main` by the shared release workflow: commit types determine the semver bump and a `vX.Y.Z` tag plus GitHub release are created.
- Consumers pin by tag: `source = "git::https://github.com/Olensys/<module>.git?ref=vX.Y.Z"`.

## Deprecation policy

- Two majors are supported at a time: N and N-1.
- A deprecated module or major sets `maturity: deprecated` and `deprecated: { removal, replacement }` in `metadata.yaml`.
- Each breaking major ships an `UPGRADE-vX.md` describing every changed input, output and resource address, with `moved` blocks where possible.
- The removal date is at least 90 days after the deprecation is announced.

## Use upstream directly

When a registry module is already a good fit, there is no Olensys wrapper. Use it directly, pinned exactly:

| Cloud  | Module | Version |
|--------|--------|---------|
| AWS    | `terraform-aws-modules/security-group/aws` | 6.0.0 |
| AWS    | `terraform-aws-modules/sns/aws` | 7.2.0 |
| AWS    | `terraform-aws-modules/dynamodb-table/aws` | 5.5.2 |
| AWS    | `terraform-aws-modules/kms/aws` | 4.2.2 |
| AWS    | `terraform-aws-modules/eventbridge/aws` | 4.3.3 |
| AWS    | `terraform-aws-modules/ec2-instance/aws` | pin at first use |
| Google | `terraform-google-modules/pubsub/google` | 8.8.1 |
| Google | `terraform-google-modules/kms/google` | 4.2.1 |
| Google | `terraform-google-modules/cloud-dns/google` | 7.2.1 |
| Google | `terraform-google-modules/project-factory/google//modules/project_services` | 18.4.0 |

Pass `context`-derived `tags` or `labels` into these modules from `terraform-null-naming` so naming stays consistent.
