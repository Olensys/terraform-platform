# Module interface contract

Every module in the library follows this contract so that modules are interchangeable across clouds and predictable to wire together.

## Variable order

Variables are declared in `variables.tf` in this order:

1. `name` - the resource name. Optional when `context` is enough to derive one.
2. `context` - the shared naming and tagging object (below).
3. `project_id` - Google modules only: it comes first after `context`.
4. Module-specific variables, grouped by concern, required ones first.
5. `tags` (AWS, Cloudflare) or `labels` (Google) - caller-supplied tags, typically `module.naming.tags` / `module.naming.labels`; they win over `context.extra_tags`.

## The `context` object

```hcl
variable "context" {
  type = object({
    organization = string
    environment  = string          # one of dev, staging, prod, test, shared
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
}
```

`environment` is validated against `dev`, `staging`, `prod`, `test`, `shared`.

`terraform-null-naming` renders a context into:

| Output        | Rule |
|---------------|------|
| `name`        | `<organization>-<environment>-<application>[-<component>]`, lowercase, `[a-z0-9-]` |
| `tags`        | `Organization`, `Environment`, `Application`, `Component` (when set), `Owner`, `CostCenter`, `ManagedBy = "terraform"`, plus `extra_tags` |
| `labels`      | the same keys lowercased snake_case; values lowercased with `[^a-z0-9_-]` replaced by `-`, truncated to 63 characters |
| `name_prefix` | `name` truncated to 32 characters |

Callers render `module "naming"` from `terraform-null-naming` and pass `tags = module.naming.tags` (AWS) or `labels = module.naming.labels` (GCP). Every module applies `merge(normalised(context.extra_tags), var.tags|labels)`, so caller `tags`/`labels` win and `extra_tags` is the shared baseline. Google modules normalise `extra_tags` keys and values to label syntax (lowercase, `[^a-z0-9_-]` replaced by `-`, 63 characters) and apply `labels` verbatim.

```hcl
module "naming" {
  source  = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.0"
  context = var.context
}

module "bucket" {
  source  = "git::https://github.com/Olensys/terraform-aws-s3-bucket.git?ref=v1.1.0"
  name    = "assets"
  context = var.context
  tags    = module.naming.tags # GCP modules: labels = module.naming.labels
}
```

## Toggle naming

Boolean switches that enable optional resources are named `create_<thing>` (for example `create_log_group`). Switches that turn a behaviour on use `enable_<feature>` (for example `enable_versioning`). Never use negative names such as `disable_*`. Toggles default to the secure option.

Known deviations kept until 2.0: `versioning_enabled` (s3-bucket, gcs-bucket), `auth_enabled`, `transit_encryption` (memorystore-redis), `adaptive_protection` (cloud-armor), `http_redirect` (https-lb), `spa_fallback` (static-site).

## Output contract

Every module exposes:

- `id` - the primary identifier of the main resource.
- `name` - the rendered resource name.
- `arn` (AWS) or `self_link` (Google) - the canonical reference. Cloudflare and `null` modules omit it.

`terraform-cloudflare-dns` has no `name`, `tags` or `arn` (records are not taggable); `terraform-null-naming` has no `id` (it creates nothing).

Additional outputs are named after the resource they expose (`role_arn`, `log_group_name`). Outputs for sensitive values are marked `sensitive = true`.

## Wrapper ceiling

A module that wraps an upstream registry module exposes at most **15 inputs** beyond `name`, `context` and `tags`/`labels`. Anything beyond that is either hard-wired to an opinionated default or the caller is pointed at the upstream module directly (see [use upstream directly](conventions.md#use-upstream-directly)).

## Secure defaults

Every module ships with these defaults; a caller must opt out explicitly:

- Public access blocked.
- Encryption on (at rest).
- TLS enforced (in transit).
- Immutable image tags.
- Log retention set.
- No `authorization_type = "NONE"`.
- No IAM statements with `resources = ["*"]`.
- Partition and region always come from data sources, never hardcoded.

Recommended (not enforced): least-privilege IAM, deletion protection or versioning on stateful `prod` resources, and logging/audit trails wherever the service offers them. Public-facing modules (`alb`, `https-lb`, `static-site`) expose public endpoints by design; the rule applies to storage and data-plane resources behind them.
