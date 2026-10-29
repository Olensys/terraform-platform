# 0001: terraform-aws-subnet

Status: draft

## Problem

`terraform-aws-vpc` creates the VPC and one public and one private subnet per zone. It cannot add extra subnets to an existing VPC. Workloads such as Lambda functions in their own private subnets end up with hand-written `aws_subnet` resources or an unmaintained module.

There is no registry module for a standalone subnet, so the "use upstream directly" rule does not apply.

## Proposed change

Add `terraform-aws-subnet`: one subnet per module instance (call it with `for_each` for several), with an optional route table association.

- Inputs: `name`, `context`, `create`, `vpc_id`, `cidr_block`, `availability_zone`, `route_table_id`, `map_public_ip_on_launch` (default `false`), `tags`.
- Outputs: `id`, `name`, `arn`, `availability_zone`, `cidr_block`, `route_table_association_id`, `tags`.
- Tier `primitive`, maturity `experimental`; no upstream module.

## Affected modules

New module only. Consumers adopting existing subnets can use `terraform state mv`, since the module names its resources `aws_subnet.this[0]` and `aws_route_table_association.this[0]`.

## Migration or upgrade impact

None for existing modules.

## Alternatives considered

- Extra-subnet inputs on `terraform-aws-vpc`: couples unrelated lifecycles and strains the 15-input wrapper ceiling.
- Plain `aws_subnet` resources in each consumer: no shared secure defaults, and each repo repeats the same code.
