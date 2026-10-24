# Runbook: dedicated test project and account with budget caps

### A.1 Google Cloud test project

1. **Create the project** (console: IAM & Admin → Create project, or CLI):
   ```bash
   gcloud projects create olensys-tf-test --name="olensys-tf-test" --set-as-default
   gcloud billing projects link olensys-tf-test --billing-account=<BILLING_ACCOUNT_ID>
   gcloud services enable compute.googleapis.com container.googleapis.com sqladmin.googleapis.com \
     redis.googleapis.com run.googleapis.com cloudfunctions.googleapis.com eventarc.googleapis.com \
     secretmanager.googleapis.com artifactregistry.googleapis.com logging.googleapis.com \
     iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com servicenetworking.googleapis.com \
     identitytoolkit.googleapis.com cloudbilling.googleapis.com cloudbuild.googleapis.com pubsub.googleapis.com
   ```
2. **Workload identity for GitHub** — use the library's own module from any workstation (local state is fine for this one-off):
   The module binds exact subjects (no wildcards, by design), so list the 16 Google module repos; `branches = ["main"]` is the default and matches the new trigger (push to `main`, schedule and dispatch all run on `main`).
   ```hcl
   locals {
     context = { organization = "olensys", environment = "shared", application = "ci", owner = "platform", cost_center = "eng" }
     google_repos = ["terraform-google-network", "terraform-google-gke-cluster", "terraform-google-service-account",
       "terraform-google-github-workload-identity", "terraform-google-gcs-bucket", "terraform-google-artifact-registry",
       "terraform-google-secret-manager", "terraform-google-cloud-sql", "terraform-google-memorystore-redis",
       "terraform-google-cloud-run-service", "terraform-google-cloud-function", "terraform-google-https-lb",
       "terraform-google-cloud-armor", "terraform-google-log-export", "terraform-google-identity-platform",
       "terraform-google-bastion-host", "terraform-platform"]   # terraform-platform runs the sweeper
   }
   module "naming" { source = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"; context = local.context }
   module "ci_sa" {
     source     = "git::https://github.com/Olensys/terraform-google-service-account.git?ref=v1.1.0"
     name       = "github-integration"
     context    = local.context
     project_id = "olensys-tf-test"
     labels     = module.naming.labels
   }
   module "ci_identity" {
     source       = "git::https://github.com/Olensys/terraform-google-github-workload-identity.git?ref=v1.1.0"
     name         = "github"
     context      = local.context
     project_id   = "olensys-tf-test"
     github_org   = "Olensys"
     repositories = { for r in local.google_repos : r => { service_account_email = module.ci_sa.email } }
     labels       = module.naming.labels
   }
   output "provider" { value = module.ci_identity.provider_name }
   output "sa"       { value = module.ci_sa.email }
   ```
   Grant the service account `roles/editor` **on the test project only** plus `roles/iam.serviceAccountAdmin`, `roles/resourcemanager.projectIamAdmin` and `roles/logging.configWriter` (the examples create service accounts, IAM bindings and log sinks). Copy `provider` into the org secret `GCP_WORKLOAD_IDENTITY_PROVIDER` and `sa` into `GCP_SERVICE_ACCOUNT`. Adding a module repo later means adding one name to `google_repos` and re-applying.
3. **Shared test network** (one-off, kept): call the `terraform-google-network` module directly with the same subnets as its `examples/minimal` but `enable_nat = false` (no standing NAT charge; the NAT path is still exercised by the module's own integration run), keep its state in the GCS bucket `olensys-tf-test-state` in the project; call it with `context = { organization = "olensys", environment = "shared", application = "ci", owner = "platform", cost_center = "eng" }` so the network is named `olensys-shared-…` and labelled `environment=shared`. Never give kept resources `environment = "test"` or an `olensys-test-` name: the GCP sweeper deletes anything labelled `environment=test` or named `olensys-test-*`. Record `network_self_link`, network and subnet names and the `pods`/`services` range names as the `TF_VAR_*` variables listed in the migration guide.
4. **Budget with alerts** (Billing → Budgets & alerts → Create budget): scope = project `olensys-tf-test`, amount = **$25/month**, thresholds 50 %, 80 %, 100 % actual, email to the billing admins, and tick "Connect a Pub/Sub topic" → create topic `billing-cap`.
5. **Hard cap** — Google budgets alert but do not stop spend; the documented pattern is a function that detaches billing at 100 %:
   ```bash
   gcloud pubsub topics create billing-cap
   git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples && cd nodejs-docs-samples/functions/billing/stop-billing
   gcloud functions deploy stop-billing --gen2 --runtime=nodejs20 --region=us-central1 \
     --entry-point=stopBilling --trigger-topic=billing-cap --set-env-vars=GOOGLE_CLOUD_PROJECT=olensys-tf-test
   ```
   Grant the function's service account `roles/billing.projectManager` on the project (and `roles/billing.user` on the billing account). When the budget fires at 100 %, the function detaches billing; every running resource stops and the next integration run fails at auth — which is the intended outcome. Re-attach with `gcloud billing projects link` after review.
6. **Verify**: run any Google module's `integration` workflow via "Run workflow"; it should authenticate and apply. Then run the sweeper with `dry_run=true` and read the output.

### A.2 AWS test account

1. **Create the account** inside your AWS Organization (console: AWS Organizations → Add an AWS account → Create, name `olensys-tf-test`, email an alias you own) or:
   ```bash
   aws organizations create-account --email tf-test@<your-domain> --account-name olensys-tf-test --role-name OrganizationAccountAccessRole
   ```
   Put it in an OU with an SCP that denies `organizations:LeaveOrganization` and restricts regions to `us-east-1` and the `AWS_REGION` you will use.
2. **OIDC role** — assume `OrganizationAccountAccessRole` into the new account and apply the library module:
   The module binds exact `owner/repo` subjects (no wildcards, by design); list the 16 AWS module repos plus `terraform-platform` (sweeper), `branches = ["main"]`.
   ```hcl
   locals {
     context   = { organization = "olensys", environment = "shared", application = "ci", owner = "platform", cost_center = "eng" }
     aws_repos = ["terraform-aws-s3-bucket", "terraform-aws-ecs-cluster", "terraform-aws-ecs-service", "terraform-aws-lambda-function",
       "terraform-aws-ssm-parameters", "terraform-aws-ecr-repository", "terraform-aws-sqs-queue", "terraform-aws-acm-certificate",
       "terraform-aws-static-site", "terraform-aws-alb", "terraform-aws-vpc", "terraform-aws-github-oidc-role",
       "terraform-aws-cognito-user-pool", "terraform-aws-ses-domain", "terraform-aws-step-function", "terraform-aws-http-api",
       "terraform-platform"]
   }
   module "naming" { source = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"; context = local.context }
   module "ci_role" {
     source       = "git::https://github.com/Olensys/terraform-aws-github-oidc-role.git?ref=v1.0.2"
     name         = "github-integration"
     context      = local.context
     repositories = { for r in local.aws_repos : "Olensys/${r}" => { branches = ["main"] } }
     policy_arns  = ["arn:aws:iam::aws:policy/PowerUserAccess", "arn:aws:iam::aws:policy/IAMFullAccess"]
     tags         = module.naming.tags
   }
   output "role_arn" { value = module.ci_role.arn }
   ```
   The examples create IAM roles and OIDC providers, hence `IAMFullAccess`; this is acceptable only because the account contains nothing else. Set org secrets `AWS_ROLE_ARN` (= `role_arn`) and `AWS_REGION`. Adding a module repo later means adding one name to `aws_repos` and re-applying.
3. **Shared test VPC** (one-off, kept): call the `terraform-aws-vpc` module directly (not through its example) with `nat = "none"` so there is no standing NAT charge, keep its state in the S3 bucket `olensys-tf-test-state`, and record `vpc_id` and `subnet_ids` as repository variables for `terraform-aws-alb` and `terraform-aws-ecs-service`. Create one ECS cluster by calling `terraform-aws-ecs-cluster` directly for `TF_VAR_cluster_arn`, and one ACM certificate for a test subdomain by calling `terraform-aws-acm-certificate` directly for `TF_VAR_certificate_arn`. Do not use the modules' `examples/minimal`: that yields `olensys-test-example`, which the sweeper deletes. Each kept resource (AWS VPC, ECS cluster, ACM certificate, GCP network, both state buckets) gets its own `module "naming"` with `context = { organization = "olensys", environment = "shared", application = "ci", owner = "platform", cost_center = "eng" }`, and the module call takes `name = module.naming.name` and `tags = module.naming.tags` (GCP: `labels = module.naming.labels`). Anything named `olensys-test-*` or tagged `Environment=test` is deleted weekly.
   Every kept resource (VPC, ECS cluster, ACM certificate) must be created with `environment = "shared"` in its `context` (tag `Environment=shared`, names `olensys-shared-…`) and must never carry `environment = "test"` or the `olensys-test-` prefix. The AWS sweeper (`scripts/sweeper/aws-cloud-nuke.yaml`) skips every resource tagged `Environment=shared`, names matching `^olensys-shared-` (VPC, ECS cluster, ACM, S3, CloudFront, IAM), the S3 bucket `olensys-tf-test-state`, the IAM roles `github-integration`, `OrganizationAccountAccessRole`, `AWSBudgetsActionsRole*` and `AWSServiceRole*`, and the GitHub OIDC provider `token.actions.githubusercontent.com`. The sweeper runs with `--region global`, so IAM, S3 and CloudFront leaks are swept too; that exclusion list is the only protection for these resources, so keep the YAML and this paragraph in agreement.

   Sweeper limits: the ACM certificate is protected only by its `Environment=shared` tag (cloud-nuke matches ACM names against the domain, so the `olensys-shared-` name rule does not help). CloudFront distributions are not swept by `--older-than` runs, so a leaked static-site distribution must be removed by hand.
4. **Enable billing alerts** (payer account): Billing → Billing preferences → tick "Receive Billing Alerts". Without this, Budgets cannot evaluate.
5. **Budget with alerts and a hard stop** (in the test account, Billing → Budgets → Create budget → Customize):
   - Cost budget, monthly, **$25**, filter = this account; alerts at 50 % and 80 % actual and 100 % forecasted, to your email.
   - **Budget action** at 100 % actual: action type "Apply IAM policy", policy `arn:aws:iam::aws:policy/AWSDenyAll`, target = the `github-integration` role, execution "Automatic". Budgets needs a service role (the console creates `AWSBudgetsActionsRole`). When it fires, the OIDC role can do nothing until you detach the policy by hand, so no further spend can be created by CI. Running resources are not stopped — the sweeper's next run or a manual `cloud-nuke` is what removes them.
   - Optional second action at 100 %: "Run SSM Automation" `AWS-StopEC2Instance` is not useful here (the examples run Fargate and managed services), so skip it.
6. **Verify**: run `terraform-aws-s3-bucket`'s `integration` workflow by hand; it should authenticate, apply and destroy. Run the sweeper with `dry_run=true` and read the output. Set `SWEEPER_AWS_ACCOUNT_ID` and `SWEEPER_GCP_PROJECT_ID` as repository variables on `terraform-platform`.

### A.3 What this costs when idle

Nothing runs between pushes except the Sunday sweep and the Sunday sweeper. Standing items: the kept test VPC (free without NAT), the kept test network on GCP (free; NAT gateway ≈ $1/month if left on — set `enable_nat = false` on the kept network or accept it), one ECS cluster (free), one ACM certificate (free), two state buckets, both named `olensys-tf-test-state` (cents).

### A.4 Owner checklist for the release and ruleset rollout

Do these in order:

1. Move the floating tag: `cd terraform-workflows && git fetch && git tag -fa v1 -m "v1" 582206b && git push -f origin v1`.
2. Create a fine-grained PAT (Contents: write, Pull requests: write, repositories: all Olensys `terraform-*`) and store it as org secret `RELEASE_PLEASE_TOKEN`.
3. Re-trigger the open release PRs (close and reopen, or push an empty commit on their branch) so CI runs and they become mergeable.
4. Merge terraform-platform PR #2 and close PR #1 BEFORE anyone runs `scripts/protect-main.sh` from main, because main's copy would re-apply the superseded rulesets.
