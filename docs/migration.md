# Adopting the module library

## How adoption works

- Each repository provides one capability; adopt them one at a time.
- Pin every module with `?ref=vX.Y.Z` and upgrade deliberately.
- All modules share the `context` object and the `tags` / `labels` contract described in [interface.md](interface.md).
- Run `terraform plan` first and read it before anything else.
- Resources that must survive are brought in with `import` blocks (Terraform 1.5 or later); everything else is accepted as recreated.
- Run `scripts/consumers.sh` to list every workspace that already consumes a module.

## Capability map

| Capability | Repo | Keep (import) | Recreated | Watch for |
|------------|------|---------------|-----------|-----------|
| Naming, tags, labels | `terraform-null-naming` | Nothing | Nothing, no state to keep | Names are computed from `context`; compare generated names with existing ones before switching |
| DNS records | `terraform-cloudflare-dns` | Nothing, no state to keep | Records are recreated by the plan | Lower the TTL first so a brief gap is not cached |
| Network (AWS) | `terraform-aws-vpc` | VPC, subnets, NAT | Route tables and endpoints if not imported | CIDRs are computed, so prefer a fresh VPC per environment |
| Network (Google) | `terraform-google-network` | Network, subnets, router, NAT | Serverless access connector | Secondary ranges must match what the cluster already uses |
| Container platform (AWS) | `terraform-aws-ecs-cluster` | Cluster | Capacity provider associations | Container Insights setting changes settings in place |
| Container platform (Google) | `terraform-google-gke-cluster` | Cluster, node pool | Node pool if its settings must change | Node pool changes can drain nodes; plan a maintenance window |
| Container service (AWS) | `terraform-aws-ecs-service` | Service, target group, listener rule | New task-definition revision | Deployments now wait for steady state |
| Container service (Google) | `terraform-google-cloud-run-service` | Service, trigger | Revision names | Traffic split and ingress defaults |
| Functions (AWS) | `terraform-aws-lambda-function` | Function, log group | IAM role | Environment values sourced from SSM must exist before apply |
| Functions (Google) | `terraform-google-cloud-function` | Functions | Source bucket | Source archive is rebuilt, so expect a new revision |
| Object storage (AWS) | `terraform-aws-s3-bucket` | Bucket | Public website buckets move to static-site | Public access block and TLS-only policy are now on |
| Object storage (Google) | `terraform-google-gcs-bucket` | Bucket | Nothing, unless ACLs are in use | Uniform bucket-level access becomes true; check ACL users first |
| Static site / CDN (AWS) | `terraform-aws-static-site` | Bucket, distribution, certificate, DNS records | Nothing; OAI to OAC is an in-place update | Cache behaviour and error pages |
| L7 load balancer (Google) | `terraform-google-https-lb` | Load balancer resources | Managed certificate (gets a random suffix) | Certificate provisioning takes time after cutover |
| L7 load balancer (AWS) | `terraform-aws-alb` | ALB, listeners | Rules not imported | Listener rules owned by services stay with the service module |
| WAF (Google) | `terraform-google-cloud-armor` | Policies | Rules that are reordered | Rule priorities must be unique |
| Image registry (AWS) | `terraform-aws-ecr-repository` | Repository | Nothing | Tag mutability becomes IMMUTABLE; re-pushing a tag fails |
| Image registry (Google) | `terraform-google-artifact-registry` | Repository | Nothing | Immutable tags are on |
| Secrets / parameters (AWS) | `terraform-aws-ssm-parameters` | Parameters, after moving values | Parameters whose path changes | Path convention is `/<env>/<name>/<key>`; update readers |
| Secrets / parameters (Google) | `terraform-google-secret-manager` | Secrets | Secret versions | Values are never read back; supply them again |
| Queue (AWS) | `terraform-aws-sqs-queue` | Queues | Nothing | A dead-letter queue is added where missing |
| Relational DB (Google) | `terraform-google-cloud-sql` | Instance, databases, users | Nothing | Edition is pinned to ENTERPRISE |
| Cache (Google) | `terraform-google-memorystore-redis` | Instance | Nothing | Tier and version are not changed in place |
| Identity (AWS) | `terraform-aws-cognito-user-pool` | Pool, clients, domain | Nothing | Variable names differ from other wrappers |
| Identity (Google) | `terraform-google-identity-platform` | Config | Nothing | One config per project |
| CI identity (AWS) | `terraform-aws-github-oidc-role` | OIDC provider, role | Policy attachments | Subject claims must match the repositories that deploy |
| CI identity (Google) | `terraform-google-github-workload-identity` | Service accounts, pool, provider | IAM bindings (authoritative to additive) | Additive bindings do not remove old members |
| Service identity (Google) | `terraform-google-service-account` | Service accounts | IAM bindings | Bindings change from authoritative to additive |
| Certificates (AWS) | `terraform-aws-acm-certificate` | Certificate | Validation records | Certificates used by listeners must be created before destroy |
| Email (AWS) | `terraform-aws-ses-domain` | Identity, imported as `aws_sesv2_email_identity` | DKIM and validation records | Identity moves from v1 to v2 resources |
| Workflow (AWS) | `terraform-aws-step-function` | State machine | Role | Definition is rendered from the module inputs |
| HTTP API gateway (AWS) | `terraform-aws-http-api` | API, stages, routes | Nothing | Authorizers and custom domains |
| Log export (Google) | `terraform-google-log-export` | Sink, destination | Nothing | Sink writer identity needs access to the destination |
| Bastion (Google) | `terraform-google-bastion-host` | Nothing | Instance | Access is through IAP; no state to keep |

## Maturity and release policy

- Every module starts as `experimental`.
- A module is promoted to `stable` after two green integration runs on `main` plus one green weekly sweep. Integration applies run on push to `main` that touches Terraform files, weekly on Sunday 03:00 UTC, and on manual dispatch.
- release-please owns releases after 1.0.1. It now runs in manifest mode, honouring each repo's `release-please-config.json` and `.release-please-manifest.json`, and will take over once the org setting below is enabled.
- Releases to date were cut manually (tags and GitHub Releases) because the org currently blocks Actions from opening pull requests.
- (Historical) the 1.0.1 fleet release was cut manually because the org currently blocks Actions from opening pull requests.

## Owner checklist

- [ ] Enable "Allow GitHub Actions to create and approve pull requests" at org level.
- [ ] Set `TF_VAR_*` repository variables and cloud credentials for `integration.yml` in each module repo (names are listed in the terraform-workflows README).
- [ ] Set the `SWEEPER_AWS_ACCOUNT_ID` and `SWEEPER_GCP_PROJECT_ID` repository variables on terraform-platform, run the `sweeper` workflow once with `dry_run=true` and read the output before trusting it.
