# terraform-platform

Catalog, conventions and tooling for the Olensys Terraform/OpenTofu module library.

- [Interface contract](docs/interface.md)
- [Conventions](docs/conventions.md)
- [AWS and Google pairs](docs/pairs.md)
- [Proposals](docs/proposals/README.md)

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/new-module.sh <name> <cloud> <description>` | Create a module repo from the template and seed `metadata.yaml` |
| `scripts/fleet.sh "<pr title>" <script>` | Run a script across every module repo and open PRs (needs `multi-gitter`) |
| `scripts/consumers.sh [module]` | Find consumers of a module under `$WORKSPACE` (default `$HOME/workspace`) |
| `scripts/catalog.py --write\|--check` | Regenerate or verify the table below |

## Catalog

<!-- BEGIN_CATALOG -->
| Module | Cloud | Tier | Maturity | Description | Pairs with | Latest tag |
|---|---|---|---|---|---|---|
| [`terraform-platform`](https://github.com/Olensys/terraform-platform) | common | platform | stable | Catalog, conventions and tooling for the Olensys module library |  | - |
| `terraform-workflows` | common | platform | planned |  |  | - |
| `terraform-module-template` | common | platform | planned |  |  | - |
| `terraform-null-naming` | common | capability | planned |  |  | - |
| `terraform-cloudflare-dns` | common | capability | planned |  |  | - |
| `terraform-aws-s3-bucket` | aws | capability | planned |  |  | - |
| `terraform-aws-ecs-cluster` | aws | capability | planned |  |  | - |
| `terraform-aws-ecs-service` | aws | capability | planned |  |  | - |
| `terraform-aws-lambda-function` | aws | capability | planned |  |  | - |
| `terraform-aws-ssm-parameters` | aws | capability | planned |  |  | - |
| `terraform-aws-ecr-repository` | aws | capability | planned |  |  | - |
| `terraform-aws-sqs-queue` | aws | capability | planned |  |  | - |
| `terraform-aws-acm-certificate` | aws | capability | planned |  |  | - |
| `terraform-aws-static-site` | aws | capability | planned |  |  | - |
| `terraform-aws-alb` | aws | capability | planned |  |  | - |
| `terraform-aws-vpc` | aws | capability | planned |  |  | - |
| `terraform-aws-github-oidc-role` | aws | capability | planned |  |  | - |
| `terraform-aws-cognito-user-pool` | aws | capability | planned |  |  | - |
| `terraform-aws-ses-domain` | aws | capability | planned |  |  | - |
| `terraform-aws-step-function` | aws | capability | planned |  |  | - |
| `terraform-aws-http-api` | aws | capability | planned |  |  | - |
| `terraform-google-network` | google | capability | planned |  |  | - |
| `terraform-google-gke-cluster` | google | capability | planned |  |  | - |
| `terraform-google-service-account` | google | capability | planned |  |  | - |
| `terraform-google-github-workload-identity` | google | capability | planned |  |  | - |
| `terraform-google-gcs-bucket` | google | capability | planned |  |  | - |
| `terraform-google-artifact-registry` | google | capability | planned |  |  | - |
| `terraform-google-secret-manager` | google | capability | planned |  |  | - |
| `terraform-google-cloud-sql` | google | capability | planned |  |  | - |
| `terraform-google-memorystore-redis` | google | capability | planned |  |  | - |
| `terraform-google-cloud-run-service` | google | capability | planned |  |  | - |
| `terraform-google-cloud-function` | google | capability | planned |  |  | - |
| `terraform-google-https-lb` | google | capability | planned |  |  | - |
| `terraform-google-cloud-armor` | google | capability | planned |  |  | - |
| `terraform-google-log-export` | google | capability | planned |  |  | - |
| `terraform-google-identity-platform` | google | capability | planned |  |  | - |
| `terraform-google-bastion-host` | google | capability | planned |  |  | - |
<!-- END_CATALOG -->
