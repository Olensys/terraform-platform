# AWS and Google pairs

Capabilities that exist on both clouds, and the repo that provides each. "upstream" means the registry module is used directly (see [conventions](conventions.md#use-upstream-directly)); "later" means no module is planned yet.

| Capability | AWS | Google |
|------------|-----|--------|
| Naming, tags, labels | `terraform-null-naming` | `terraform-null-naming` |
| DNS records | `terraform-cloudflare-dns` | `terraform-cloudflare-dns` |
| Network | `terraform-aws-vpc` | `terraform-google-network` |
| Container platform | `terraform-aws-ecs-cluster` | `terraform-google-gke-cluster` |
| Container service | `terraform-aws-ecs-service` | `terraform-google-cloud-run-service` |
| Functions | `terraform-aws-lambda-function` | `terraform-google-cloud-function` |
| Object storage | `terraform-aws-s3-bucket` | `terraform-google-gcs-bucket` |
| Static site / CDN | `terraform-aws-static-site` | `terraform-google-https-lb` + `terraform-google-gcs-bucket` |
| L7 load balancer | `terraform-aws-alb` | `terraform-google-https-lb` |
| WAF | upstream `wafv2` (later) | `terraform-google-cloud-armor` |
| Image registry | `terraform-aws-ecr-repository` | `terraform-google-artifact-registry` |
| Secrets / parameters | `terraform-aws-ssm-parameters` | `terraform-google-secret-manager` |
| Queue | `terraform-aws-sqs-queue` | upstream `pubsub` |
| Relational DB | upstream `rds` (later) | `terraform-google-cloud-sql` |
| Cache | upstream `elasticache` (later) | `terraform-google-memorystore-redis` |
| Identity | `terraform-aws-cognito-user-pool` | `terraform-google-identity-platform` |
| CI identity | `terraform-aws-github-oidc-role` | `terraform-google-github-workload-identity` |
| Service identity | IAM role inside each module | `terraform-google-service-account` |
| Certificates | `terraform-aws-acm-certificate` | managed cert inside `terraform-google-https-lb` |
| Email | `terraform-aws-ses-domain` | none |
| Workflow | `terraform-aws-step-function` | none |
| HTTP API gateway | `terraform-aws-http-api` | none |
| Log export | CloudWatch inside each module | `terraform-google-log-export` |
| Bastion | none | `terraform-google-bastion-host` |
