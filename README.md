# terraform-platform

Catalog, conventions and tooling for the Olensys Terraform/OpenTofu module library.

- [Interface contract](docs/interface.md)
- [Conventions](docs/conventions.md)
- [AWS and Google pairs](docs/pairs.md)
- [Adopting the module library](docs/migration.md)
- [Proposals](docs/proposals/README.md)
- [Runbook: dedicated test project and account with budget caps](docs/runbooks/test-accounts.md)
- [Contributing](CONTRIBUTING.md)

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/new-module.sh <name> <cloud> <description>` | Create a module repo from the template and seed `metadata.yaml` |
| `scripts/fleet.sh "<pr title>" <script>` | Run a script across every module repo and open PRs (needs `multi-gitter`) |
| `scripts/consumers.sh [module]` | Find consumers of a module under `$WORKSPACE` (default `$HOME/workspace`) |
| `scripts/catalog.py --write\|--check` | Regenerate or verify the table below |
| `scripts/sweeper/` | Weekly leaked-resource sweeper; dry-run by default on manual dispatch. A local dry run against the test project is the owner's job once credentials exist: `bash scripts/sweeper/gcp-sweep.sh <project> true` |
| `scripts/protect-main.sh [--dry-run] [repo...]` | Apply the `main-protection` and `release-tags` rulesets to every `Olensys/terraform-*` repo (idempotent; run after adding a repo) |

## Setup

All repositories in this library are public and Apache-2.0 licensed. The nightly `catalog` workflow uses the default `GITHUB_TOKEN`; enable "Allow GitHub Actions to create and approve pull requests" in this repo's Actions settings so it can open the refresh PR. `catalog.py` exits 2 if it cannot reach this repo.

## Catalog

<!-- BEGIN_CATALOG -->
| Module | Cloud | Tier | Maturity | Description | Pairs with | Latest tag |
|---|---|---|---|---|---|---|
| [`terraform-platform`](https://github.com/Olensys/terraform-platform) | common | platform | stable | Catalog, conventions and tooling for the Olensys module library |  | - |
| [`terraform-workflows`](https://github.com/Olensys/terraform-workflows) | common | platform | n/a | Reusable GitHub Actions workflows: module-ci, module-release, module-integration |  | v1 |
| [`terraform-module-template`](https://github.com/Olensys/terraform-module-template) | common | platform | n/a | Template repository every module repo is created from |  | - |
| [`terraform-null-naming`](https://github.com/Olensys/terraform-null-naming) | common | capability | stable | Renders a context object into resource names, AWS tags and GCP labels |  | v1.0.1 |
| [`terraform-cloudflare-dns`](https://github.com/Olensys/terraform-cloudflare-dns) | common | capability | stable | Cloudflare DNS records from a map; used for ACM and SES validation and CNAMEs |  | v1.1.0 |
| [`terraform-aws-s3-bucket`](https://github.com/Olensys/terraform-aws-s3-bucket) | aws | capability | stable | Private, encrypted, TLS-only S3 bucket with optional versioning, lifecycle and CORS | `terraform-google-gcs-bucket` | v1.1.2 |
| [`terraform-aws-ecs-cluster`](https://github.com/Olensys/terraform-aws-ecs-cluster) | aws | capability | stable | ECS cluster on Fargate with Container Insights and capacity provider strategy | `terraform-google-gke-cluster` | v1.0.4 |
| [`terraform-aws-ecs-service`](https://github.com/Olensys/terraform-aws-ecs-service) | aws | capability | stable | Fargate ECS service with task definition, container definitions, scoped IAM, optional ALB ingress, autoscaling and alarms | `terraform-google-cloud-run-service` | v1.1.0 |
| [`terraform-aws-lambda-function`](https://github.com/Olensys/terraform-aws-lambda-function) | aws | capability | stable | Lambda function with scoped IAM, log retention, tracing, optional schedule, event sources and SSM-sourced environment | `terraform-google-cloud-function` | v1.1.0 |
| [`terraform-aws-ssm-parameters`](https://github.com/Olensys/terraform-aws-ssm-parameters) | aws | capability | stable | SSM Parameter Store parameters under an environment-scoped path, SecureString by default | `terraform-google-secret-manager` | v1.1.0 |
| [`terraform-aws-ecr-repository`](https://github.com/Olensys/terraform-aws-ecr-repository) | aws | capability | stable | ECR repository with immutable tags, scan on push and a lifecycle policy that keeps the last N images | `terraform-google-artifact-registry` | v1.1.0 |
| [`terraform-aws-sqs-queue`](https://github.com/Olensys/terraform-aws-sqs-queue) | aws | capability | stable | SQS queue with a dead-letter queue by default, server-side encryption always on, optional FIFO |  | v1.0.3 |
| [`terraform-aws-acm-certificate`](https://github.com/Olensys/terraform-aws-acm-certificate) | aws | capability | stable | ACM certificate with Route53 or external DNS validation, EC P-256 key, create-before-destroy |  | v1.1.0 |
| [`terraform-aws-static-site`](https://github.com/Olensys/terraform-aws-static-site) | aws | capability | stable | Static website on CloudFront with a private S3 origin behind Origin Access Control, HTTPS-only, SPA fallback | `terraform-google-https-lb` | v1.0.4 |
| [`terraform-aws-alb`](https://github.com/Olensys/terraform-aws-alb) | aws | capability | stable | Application Load Balancer with HTTPS-only listeners, HTTP redirect, TLS 1.3 policy and a managed security group | `terraform-google-https-lb` | v1.0.3 |
| [`terraform-aws-vpc`](https://github.com/Olensys/terraform-aws-vpc) | aws | capability | stable | VPC with public and private subnets across AZs, NAT gateway strategy, DNS and least-privilege flow logs | `terraform-google-network` | v1.0.4 |
| [`terraform-aws-github-oidc-role`](https://github.com/Olensys/terraform-aws-github-oidc-role) | aws | capability | stable | IAM role assumable by GitHub Actions through OIDC, scoped to named repositories, environments and branches | `terraform-google-github-workload-identity` | v1.0.4 |
| [`terraform-aws-cognito-user-pool`](https://github.com/Olensys/terraform-aws-cognito-user-pool) | aws | capability | stable | Cognito user pool with hardened defaults, app clients, hosted UI domain, federated identity providers and Lambda triggers | `terraform-google-identity-platform` | v1.1.0 |
| [`terraform-aws-ses-domain`](https://github.com/Olensys/terraform-aws-ses-domain) | aws | capability | stable | SES domain identity with Easy DKIM, custom MAIL FROM, DMARC guidance, configuration set and event notifications |  | v1.1.0 |
| [`terraform-aws-step-function`](https://github.com/Olensys/terraform-aws-step-function) | aws | capability | stable | Step Functions state machine with full logging, X-Ray tracing and an execution role scoped to the Lambda functions it invokes |  | v1.0.2 |
| [`terraform-aws-http-api`](https://github.com/Olensys/terraform-aws-http-api) | aws | capability | stable | API Gateway HTTP API with Lambda proxy routes, access logging, throttling, CORS and an optional custom domain |  | v1.2.0 |
| [`terraform-google-network`](https://github.com/Olensys/terraform-google-network) | google | capability | stable | VPC network with subnets, flow logs, Cloud NAT, private service access and an optional Serverless VPC Access connector | `terraform-aws-vpc` | v1.1.2 |
| [`terraform-google-gke-cluster`](https://github.com/Olensys/terraform-google-gke-cluster) | google | capability | stable | Private GKE cluster with Workload Identity, shielded nodes, release channel and node pools from a map | `terraform-aws-ecs-cluster` | v1.1.2 |
| [`terraform-google-service-account`](https://github.com/Olensys/terraform-google-service-account) | google | capability | stable | Service account with project roles, optional GKE Workload Identity binding and impersonation grants; keys forbidden in prod |  | v1.1.2 |
| [`terraform-google-github-workload-identity`](https://github.com/Olensys/terraform-google-github-workload-identity) | google | capability | stable | Workload Identity Federation pool and GitHub OIDC provider, restricted to one GitHub organisation, with per-repository service account bindings | `terraform-aws-github-oidc-role` | v1.1.2 |
| [`terraform-google-gcs-bucket`](https://github.com/Olensys/terraform-google-gcs-bucket) | google | capability | stable | Cloud Storage bucket with uniform access, public access prevention, optional versioning, lifecycle, CORS and IAM | `terraform-aws-s3-bucket` | v1.1.2 |
| [`terraform-google-artifact-registry`](https://github.com/Olensys/terraform-google-artifact-registry) | google | capability | stable | Artifact Registry repository with immutable Docker tags, cleanup policies that keep the last N versions, and reader and writer IAM | `terraform-aws-ecr-repository` | v1.1.2 |
| [`terraform-google-secret-manager`](https://github.com/Olensys/terraform-google-secret-manager) | google | capability | stable | Secret Manager secrets from a map with optional initial versions, CMEK and accessor IAM | `terraform-aws-ssm-parameters` | v1.1.2 |
| [`terraform-google-cloud-sql`](https://github.com/Olensys/terraform-google-cloud-sql) | google | capability | stable | Cloud SQL instance with private IP only, enforced TLS, backups with PITR, HA in prod and generated passwords stored in Secret Manager |  | v1.1.2 |
| [`terraform-google-memorystore-redis`](https://github.com/Olensys/terraform-google-memorystore-redis) | google | capability | stable | Memorystore for Redis Cluster with AUTH and in-transit encryption, a Private Service Connect connection policy, and HA in prod |  | v1.2.1 |
| [`terraform-google-cloud-run-service`](https://github.com/Olensys/terraform-google-cloud-run-service) | google | capability | stable | Cloud Run v2 service with a dedicated service account, secret-backed environment, scaling, VPC egress, internal ingress by default and optional Eventarc triggers | `terraform-aws-ecs-service` | v1.1.2 |
| [`terraform-google-cloud-function`](https://github.com/Olensys/terraform-google-cloud-function) | google | capability | stable | Cloud Functions gen2 with a dedicated service account, secret-backed environment, HTTP or event triggers, and a versioned source bucket | `terraform-aws-lambda-function` | v1.1.2 |
| [`terraform-google-https-lb`](https://github.com/Olensys/terraform-google-https-lb) | google | capability | stable | Global external HTTPS load balancer with managed certificates, HTTP redirect, serverless NEG, NEG and bucket backends, optional CDN and Cloud Armor | `terraform-aws-alb` | v1.1.2 |
| [`terraform-google-cloud-armor`](https://github.com/Olensys/terraform-google-cloud-armor) | google | capability | stable | Cloud Armor security policy with OWASP preconfigured rules, IP allow and deny lists, rate limiting and adaptive protection |  | v1.1.2 |
| [`terraform-google-log-export`](https://github.com/Olensys/terraform-google-log-export) | google | capability | stable | Project log sink with a filter and exclusions, exporting to a Cloud Logging bucket, Cloud Storage or BigQuery with the writer identity granted |  | v1.1.2 |
| [`terraform-google-identity-platform`](https://github.com/Olensys/terraform-google-identity-platform) | google | capability | stable | Identity Platform project configuration with sign-in providers, authorized domains, MFA state and blocking functions | `terraform-aws-cognito-user-pool` | v1.1.2 |
| [`terraform-google-bastion-host`](https://github.com/Olensys/terraform-google-bastion-host) | google | capability | stable | Bastion VM with no external IP, IAP-only SSH, OS Login and shielded VM, for named members |  | v1.1.2 |
<!-- END_CATALOG -->

## Backlog

See [BACKLOG.md](BACKLOG.md) for agreed work that has not started.
