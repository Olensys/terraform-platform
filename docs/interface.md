# Module interface contract

Every module in the library follows this contract so that modules are interchangeable across clouds and predictable to wire together.

## Variable order

Variables are declared in `variables.tf` in this order:

1. `name` - the resource name. Optional when `context` is enough to derive one.
2. `context` - the shared naming and tagging object (below).
3. Module-specific variables, grouped by concern, required ones first.
4. `tags` (AWS, Cloudflare) or `labels` (Google) - caller-supplied extras merged over the context-derived set.

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

Modules call `terraform-null-naming` internally; callers pass `context` through unchanged.

## Toggle naming

Boolean switches that enable optional resources are named `create_<thing>` (for example `create_log_group`). Switches that turn a behaviour on use `enable_<feature>` (for example `enable_versioning`). Never use negative names such as `disable_*`. Toggles default to the secure option.

## Output contract

Every module exposes:

- `id` - the primary identifier of the main resource.
- `name` - the rendered resource name.
- `arn` (AWS) or `self_link` (Google) - the canonical reference. Cloudflare and `null` modules omit it.

Additional outputs are named after the resource they expose (`role_arn`, `log_group_name`). Outputs for sensitive values are marked `sensitive = true`.

## Wrapper ceiling

A module that wraps an upstream registry module exposes at most **15 inputs** beyond `name`, `context` and `tags`/`labels`. Anything beyond that is either hard-wired to an opinionated default or the caller is pointed at the upstream module directly (see [use upstream directly](conventions.md#use-upstream-directly)).

## Secure defaults

Unless a caller opts out explicitly, modules ship with:

- Encryption at rest enabled (provider-managed keys at minimum; a CMK input where the service supports it).
- Encryption in transit enforced (TLS only, minimum TLS 1.2).
- No public access: public access blocks on, no `0.0.0.0/0` ingress, no public IPs.
- Least-privilege IAM: no wildcard actions or resources in generated policies.
- Logging and audit trails enabled where the service offers them.
- Deletion protection or versioning on stateful resources in `prod`.
- Required tags or labels always applied from `context`.
