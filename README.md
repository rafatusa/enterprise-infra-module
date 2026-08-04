# ec2-from-modules

A minimal AWS EC2 consumer project that provisions a VPC + Security Group + EC2 instance by sourcing modules directly from the [`terraform-enterprise-modules`](https://github.com/rafatusa/terraform-enterprise-modules) library.

**Only two inputs required:** `project_name` and `aws_region`.

---

## Architecture

```
Engineer ──SSH/HTTP──▶ EC2 Instance (t3.micro, Ubuntu 22.04)
                            │
                     Security Group (ports 22, 80)
                            │
                    VPC (10.0.0.0/16)
                            │
              ┌─────────────┴─────────────┐
         Public Subnet              Private Subnet
         10.0.1.0/24                10.0.10.0/24
```

All Terraform sourced from:
```
github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/vpc?ref=v1.0.0
github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/security-group?ref=v1.0.0
github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/ec2?ref=v1.0.0
```

---

## Usage

### Deploy via UDAP platform
Set two pipeline variables before deploying:

| Variable | Example | Notes |
|---|---|---|
| `TF_VAR_project_name` | `my-project` | Lowercase alphanumeric + hyphens |
| `TF_VAR_aws_region` | `us-east-1` | Any AWS region |

### Deploy manually
```bash
cd infra/
terraform init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="key=ec2-from-modules/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform apply \
  -var="project_name=my-project" \
  -var="aws_region=us-east-1"
```

---

## Outputs

| Output | Description |
|---|---|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP address |
| `public_dns` | Public DNS hostname |
| `vpc_id` | VPC ID |
| `security_group_id` | Security group ID |

---

## Module Sources

This project consumes the enterprise module library at `v1.0.0`. To upgrade:
1. Update the `?ref=` tag in `infra/main.tf`
2. Run `terraform init -upgrade`
3. Review the plan before applying

---

## CI/CD Pipeline

```
lint → validate → provision → configure → verify
```

- **lint**: tflint + tfsec on infra/
- **validate**: terraform validate
- **provision**: terraform apply (creates VPC + SG + EC2)
- **configure**: reads terraform outputs (public IP)
- **verify**: HTTP health-check with retries against port 80
