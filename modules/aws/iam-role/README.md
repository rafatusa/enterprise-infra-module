# Module: aws/iam-role

Creates an AWS IAM Role with configurable trust policy principals, optional managed policy attachments, optional inline policy, and an EC2 instance profile when `ec2.amazonaws.com` is a principal.

## Usage

```hcl
module "eks_node_role" {
  source = "github.com/your-org/terraform-enterprise-modules//modules/aws/iam-role?ref=v1.0.0"

  name    = "my-app-eks-node-role"
  project = "my-project"

  assume_role_principals = ["ec2.amazonaws.com"]
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
}
```
