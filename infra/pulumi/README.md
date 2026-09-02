# Pulumi Go Component Library

A production-grade **Pulumi** infrastructure component library for AWS and Azure, written in Go.
This library is the Pulumi counterpart to the [Terraform module library](../terraform/) in this same repo.

## Structure

```
infra/pulumi/
├── go.mod                         # Single Go module
├── modules/
│   ├── aws/
│   │   ├── vpc/                   # VPC + subnets + NAT + IGW + route tables
│   │   ├── ec2/                   # EC2 instance + SG + IAM profile
│   │   ├── eks/                   # EKS cluster + managed node group + OIDC
│   │   ├── rds/                   # RDS PostgreSQL + subnet group + SG
│   │   ├── s3/                    # S3 bucket + encryption + versioning
│   │   ├── security-group/        # Configurable security group
│   │   ├── iam-role/              # IAM role + trust policy + instance profile
│   │   ├── kms/                   # KMS key + alias + rotation
│   │   └── cloudwatch/            # Log group + alarms + dashboard
│   └── azure/
│       ├── resource-group/        # Resource Group
│       ├── vnet/                  # VNet + subnets
│       ├── nsg/                   # NSG + configurable security rules
│       ├── managed-identity/      # User-assigned Managed Identity + role assignments
│       ├── log-analytics/         # Log Analytics Workspace + Container Insights
│       └── aks/                   # AKS cluster + RBAC + monitoring + autoscale
└── packages/
    ├── aws/
    │   └── aws-eks/               # Full EKS environment (composes AWS modules)
    └── azure/
        └── azure-aks/             # Full AKS environment (composes Azure modules)
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

### Inputs vs plain Go values

Most `Args` fields are `pulumi.Input` types, so you can wire an output of one
component straight into another. A few fields are **plain Go values**
(`[]string`, `*bool`, `bool`) rather than Inputs. That is deliberate: those
values decide **how many resources exist, or whether a resource exists at all**,
which Pulumi must know at construction time — an `Input` is not resolved until
after the graph is built.

The plain-value fields are:

| Module | Field | Type |
|---|---|---|
| `aws/vpc` | `AvailabilityZones`, `PublicSubnetCidrs`, `PrivateSubnetCidrs` | `[]string` |
| `aws/vpc` | `EnableNatGateway` | `*bool` |
| `aws/s3` | `EnableVersioning`, `EnableEncryption`, `BlockPublicAccess` | `*bool` |
| `aws/security-group` | `AllowAllEgress` | `*bool` |
| `aws/security-group` | `IngressRules` | `[]IngressRule` |
| `aws/iam-role` | `ManagedPolicyARNs` | `[]string` |
| `aws/iam-role` | `CreateInstanceProfile` | `bool` |
| `azure/vnet` | `Subnets` | `[]SubnetConfig` |
| `azure/nsg` | `SecurityRules` | `[]SecurityRule` |
| `azure/managed-identity` | `RoleAssignments` | `[]RoleAssignment` |
| `azure/log-analytics` | `EnableContainerInsights` | `bool` |

A `*bool` left as `nil` takes the documented default.

## Usage

### Individual Module

```go
import (
    "github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/aws/vpc"
    "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
    pulumi.Run(func(ctx *pulumi.Context) error {
        v, err := vpc.NewVpc(ctx, "prod", &vpc.Args{
            Name:        pulumi.String("prod"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            CidrBlock:   pulumi.String("10.0.0.0/16"),

            // Plain slices — they determine how many subnets are created.
            AvailabilityZones:  []string{"us-east-1a", "us-east-1b"},
            PublicSubnetCidrs:  []string{"10.0.1.0/24", "10.0.2.0/24"},
            PrivateSubnetCidrs: []string{"10.0.10.0/24", "10.0.11.0/24"},
        })
        if err != nil {
            return err
        }
        ctx.Export("vpcId", v.VpcID)
        ctx.Export("privateSubnetIds", v.PrivateSubnetIDs)
        return nil
    })
}
```

`PublicSubnetIDs` and `PrivateSubnetIDs` are ordered to match their CIDR
slices, so index 0 corresponds to the first CIDR you passed.

### Composing modules

```go
role, err := iamrole.NewRole(ctx, "app", &iamrole.Args{
    Name:              pulumi.String("app-role"),
    Project:           pulumi.String("my-project"),
    Environment:       pulumi.String("production"),
    AssumeRoleService: pulumi.String("ec2.amazonaws.com"),
    ManagedPolicyARNs: []string{
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    },
    CreateInstanceProfile: true,
})
```

### Full EKS Environment (solution package)

```go
import (
    awseks "github.com/rafatusa/enterprise-infra-module/infra/pulumi/packages/aws/aws-eks"
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

The default subnet CIDRs assume exactly two availability zones. Pass
`AvailabilityZones` (a `[]string`) to choose which two.

### Full AKS Environment (solution package)

```go
import (
    azureaks "github.com/rafatusa/enterprise-infra-module/infra/pulumi/packages/azure/azure-aks"
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
    github.com/rafatusa/enterprise-infra-module/infra/pulumi v2.0.0
)
```

Or use `go get`:

```bash
go get github.com/rafatusa/enterprise-infra-module/infra/pulumi@v2.0.0
```

## Module Outputs

### AWS Modules

| Module | Key Outputs |
|--------|-------------|
| `aws/vpc` | `VpcID`, `PublicSubnetIDs`, `PrivateSubnetIDs`, `InternetGatewayID`, `NatGatewayID` |
| `aws/ec2` | `InstanceID`, `PublicIP`, `PrivateIP`, `SecurityGroupID`, `IamRoleARN` |
| `aws/eks` | `ClusterName`, `ClusterEndpoint`, `ClusterARN`, `OIDCProviderURL`, `NodeGroupARN`, `ClusterCaCertificate` |
| `aws/rds` | `Endpoint`, `Port`, `DBName`, `SecurityGroupID` |
| `aws/s3` | `BucketID`, `BucketARN`, `BucketName` |
| `aws/security-group` | `SecurityGroupID`, `SecurityGroupARN` |
| `aws/iam-role` | `RoleARN`, `RoleName`, `InstanceProfileARN`, `InstanceProfileName` |
| `aws/kms` | `KeyID`, `KeyARN`, `AliasARN` |
| `aws/cloudwatch` | `LogGroupName`, `LogGroupARN`, `CPUAlarmARN`, `DashboardName` |

`aws/vpc.NatGatewayID` and `aws/cloudwatch.CPUAlarmARN` are empty strings when
the corresponding resource was not created. `aws/iam-role`'s instance profile
outputs are empty strings when `CreateInstanceProfile` is `false`.

### Azure Modules

| Module | Key Outputs |
|--------|-------------|
| `azure/resource-group` | `ResourceGroupName`, `ResourceGroupID`, `Location` |
| `azure/vnet` | `VNetName`, `VNetID`, `SubnetIDs` |
| `azure/nsg` | `NSGName`, `NSGID` |
| `azure/managed-identity` | `IdentityName`, `IdentityID`, `PrincipalID`, `ClientID`, `TenantID` |
| `azure/log-analytics` | `WorkspaceName`, `WorkspaceID`, `WorkspaceKey`, `CustomerID` |
| `azure/aks` | `ClusterName`, `ClusterID`, `KubeconfigRaw`, `NodeResourceGroup`, `IdentityPrincipalID` |

`azure/vnet.SubnetIDs` is a `StringArrayOutput` ordered to match the `Subnets`
argument — index it positionally. (The Terraform `azure/vnet` module exports a
**map** keyed by subnet name; the two libraries differ here deliberately,
because Go slices preserve order while HCL `for_each` does not.)

`azure/log-analytics` exposes two different identifiers: `WorkspaceID` is the
full Azure **resource ID** (use it for the AKS monitoring addon), while
`CustomerID` is the workspace **GUID** (use it for agent configuration).

Secrets — `azure/log-analytics.WorkspaceKey` and `azure/aks.KubeconfigRaw` —
should never be exported to plaintext stack outputs.

## Differences from the Terraform library

The two libraries cover the same ground but are not line-for-line equivalent:

- The Pulumi `aws-eks` package composes `iam-role`; the Terraform one does not,
  because its `eks` module creates its own cluster and node group roles and an
  extra role would be dead infrastructure.
- `azure/managed-identity` implements role assignments here. The Terraform
  module does not — consumers create `azurerm_role_assignment` themselves
  against the `principal_id` output.
- `azure/vnet` exports subnet IDs as an ordered array here, a name-keyed map in
  Terraform.

## Tagging Convention

All resources are tagged with:
```go
"Project":     <project-name>
"Environment": <environment>
"ManagedBy":   "pulumi"
"Module":      "aws/<module-name>" | "azure/<module-name>"
```
