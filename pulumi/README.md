# Pulumi Go Component Library

A production-grade **Pulumi** infrastructure component library for AWS and Azure, written in Go.
This library is the Pulumi counterpart to the [Terraform module library](../infra/) in this same repo.

## Structure

```
pulumi/
├── go.mod                         # Single Go module
├── modules/
│   ├── aws/
│   │   ├── vpc/                   # VPC + subnets + NAT + IGW
│   │   ├── ec2/                   # EC2 instance + SG + IAM profile
│   │   ├── eks/                   # EKS cluster + managed node group + OIDC
│   │   ├── rds/                   # RDS PostgreSQL + subnet group + SG
│   │   ├── s3/                    # S3 bucket + encryption + versioning
│   │   ├── security-group/        # Configurable security group
│   │   ├── iam-role/              # IAM role + trust policy + instance profile
│   │   ├── kms/                   # KMS key + alias + rotation
│   │   └── cloudwatch/            # Log group + alarms + dashboard
│   └── azure/
│       ├── resource-group/        # Resource Group + optional lock
│       ├── vnet/                  # VNet + subnets + service endpoints
│       ├── nsg/                   # NSG + configurable security rules
│       ├── managed-identity/      # User-assigned Managed Identity + role assignments
│       ├── log-analytics/         # Log Analytics Workspace + Container Insights
│       └── aks/                   # AKS cluster + RBAC + monitoring + autoscale
└── packages/
    ├── aws-eks/                   # Full EKS environment (composes all AWS modules)
    └── azure-aks/                 # Full AKS environment (composes all Azure modules)
```

## Component Resource Pattern

Every module is a **Pulumi Component Resource** — a reusable, composable abstraction that:
- Groups related cloud resources under a single logical resource
- Exposes a typed `Args` struct for inputs
- Exposes a typed component struct for outputs
- Registers all child resources with `pulumi.Parent(component)` for correct lifecycle management

```go
// Component resource pattern used in every module
type MyComponent struct {
    pulumi.ResourceState
    Output pulumi.StringOutput `pulumi:"output"`
}

func NewMyComponent(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*MyComponent, error) {
    component := &MyComponent{}
    ctx.RegisterComponentResource("udap:aws:MyComponent", name, component, opts...)
    // ... create child resources with pulumi.Parent(component)
    ctx.RegisterResourceOutputs(component, pulumi.Map{...})
    return component, nil
}
```

## Usage

### Individual Module

```go
import (
    "github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/vpc"
    "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
    pulumi.Run(func(ctx *pulumi.Context) error {
        v, err := vpc.NewVpc(ctx, "prod", &vpc.Args{
            Name:        pulumi.String("prod"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            AvailabilityZones: pulumi.StringArray{
                pulumi.String("us-east-1a"),
                pulumi.String("us-east-1b"),
            },
            PublicSubnetCidrs:  pulumi.StringArray{pulumi.String("10.0.1.0/24"), pulumi.String("10.0.2.0/24")},
            PrivateSubnetCidrs: pulumi.StringArray{pulumi.String("10.0.10.0/24"), pulumi.String("10.0.11.0/24")},
        })
        if err != nil {
            return err
        }
        ctx.Export("vpcId", v.VpcID)
        return nil
    })
}
```

### Full EKS Environment (solution package)

```go
import (
    awseks "github.com/rafatusa/terraform-enterprise-modules/pulumi/packages/aws-eks"
    "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
    pulumi.Run(func(ctx *pulumi.Context) error {
        env, err := awseks.NewEnvironment(ctx, "prod", &awseks.Args{
            ClusterName: pulumi.String("prod-eks"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            Region:      pulumi.String("us-east-1"),
        })
        if err != nil {
            return err
        }
        ctx.Export("clusterEndpoint", env.ClusterEndpoint)
        ctx.Export("vpcId", env.VpcID)
        return nil
    })
}
```

### Full AKS Environment (solution package)

```go
import (
    azureaks "github.com/rafatusa/terraform-enterprise-modules/pulumi/packages/azure-aks"
    "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
    pulumi.Run(func(ctx *pulumi.Context) error {
        env, err := azureaks.NewEnvironment(ctx, "prod", &azureaks.Args{
            ClusterName: pulumi.String("prod-aks"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            Location:    pulumi.String("eastus"),
        })
        if err != nil {
            return err
        }
        ctx.Export("clusterName", env.ClusterName)
        ctx.Export("resourceGroupName", env.ResourceGroupName)
        return nil
    })
}
```

## Referencing a Specific Version

Pin the module version in your `go.mod`:

```go
require (
    github.com/rafatusa/terraform-enterprise-modules/pulumi v1.1.0
)
```

Or use `go get`:

```bash
go get github.com/rafatusa/terraform-enterprise-modules/pulumi@v1.1.0
```

## Module Outputs

### AWS Modules

| Module | Key Outputs |
|--------|-------------|
| `aws/vpc` | `VpcID`, `PublicSubnetIDs`, `PrivateSubnetIDs`, `InternetGatewayID` |
| `aws/ec2` | `InstanceID`, `PublicIP`, `PrivateIP`, `SecurityGroupID`, `IamRoleARN` |
| `aws/eks` | `ClusterName`, `ClusterEndpoint`, `ClusterARN`, `OIDCProviderURL`, `NodeGroupARN` |
| `aws/rds` | `Endpoint`, `Port`, `DBName`, `SecurityGroupID` |
| `aws/s3` | `BucketID`, `BucketARN`, `BucketName` |
| `aws/security-group` | `SecurityGroupID`, `SecurityGroupARN` |
| `aws/iam-role` | `RoleARN`, `RoleName`, `InstanceProfileARN`, `InstanceProfileName` |
| `aws/kms` | `KeyID`, `KeyARN`, `AliasARN` |
| `aws/cloudwatch` | `LogGroupName`, `LogGroupARN`, `CPUAlarmARN`, `DashboardName` |

### Azure Modules

| Module | Key Outputs |
|--------|-------------|
| `azure/resource-group` | `ResourceGroupName`, `ResourceGroupID`, `Location` |
| `azure/vnet` | `VNetName`, `VNetID`, `SubnetIDs` |
| `azure/nsg` | `NSGName`, `NSGID` |
| `azure/managed-identity` | `IdentityName`, `PrincipalID`, `ClientID`, `TenantID` |
| `azure/log-analytics` | `WorkspaceName`, `WorkspaceID`, `CustomerID` |
| `azure/aks` | `ClusterName`, `ClusterID`, `KubeconfigRaw`, `NodeResourceGroup` |

## Tagging Convention

All resources are tagged with:
```go
"Project":     <project-name>
"Environment": <environment>
"ManagedBy":   "pulumi"
"Module":      "aws/<module-name>" | "azure/<module-name>"
```
