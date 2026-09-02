// Package rds provides a Pulumi component resource for an AWS RDS PostgreSQL instance
// with encryption, automated backups, parameter group, and subnet group.
// Mirrors infra/terraform/modules/aws/rds.
//
// Usage:
//
//	db, err := rds.NewDatabase(ctx, "app", &rds.Args{
//	    Identifier:   pulumi.String("app-db"),
//	    Project:      pulumi.String("my-project"),
//	    Environment:  pulumi.String("production"),
//	    DBName:       pulumi.String("appdb"),
//	    DBUsername:   pulumi.String("appuser"),
//	    DBPassword:   cfg.RequireSecret("dbPassword"),
//	    SubnetIDs:    vpc.PrivateSubnetIDs,
//	    VpcID:        vpc.VpcID,
//	    AppSGID:      app.SecurityGroupID,
//	})
package rds

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/rds"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the RDS component.
type Args struct {
	// Identifier is the RDS instance identifier.
	Identifier pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// DBName is the initial database name.
	DBName pulumi.StringInput
	// DBUsername is the master username.
	DBUsername pulumi.StringInput
	// DBPassword is the master password (use a secret).
	DBPassword pulumi.StringInput
	// SubnetIDs are the subnets for the DB subnet group.
	SubnetIDs pulumi.StringArrayInput
	// VpcID is the VPC for the DB security group.
	VpcID pulumi.StringInput
	// AppSGID is the application security group allowed to connect.
	AppSGID pulumi.StringInput
	// InstanceClass defaults to db.t3.micro.
	InstanceClass pulumi.StringInput
	// Engine defaults to postgres.
	Engine pulumi.StringInput
	// EngineVersion defaults to 15.
	EngineVersion pulumi.StringInput
	// ParameterGroupFamily defaults to postgres15. Must match EngineVersion.
	ParameterGroupFamily pulumi.StringInput
	// Port defaults to 5432.
	Port pulumi.IntInput
	// AllocatedStorage defaults to 20 GB.
	AllocatedStorage pulumi.IntInput
	// BackupRetentionDays defaults to 7.
	BackupRetentionDays pulumi.IntInput
	// DeletionProtection prevents accidental deletion. Default: false.
	// Set true for any database holding real data.
	DeletionProtection pulumi.BoolInput
	// SkipFinalSnapshot skips the final snapshot on destroy. Default: false,
	// which means a final snapshot IS taken.
	SkipFinalSnapshot pulumi.BoolInput
}

// Database is the component resource output.
type Database struct {
	pulumi.ResourceState

	Endpoint        pulumi.StringOutput `pulumi:"endpoint"`
	Port            pulumi.IntOutput    `pulumi:"port"`
	DBName          pulumi.StringOutput `pulumi:"dbName"`
	SecurityGroupID pulumi.StringOutput `pulumi:"securityGroupId"`
}

// NewDatabase creates a new RDS PostgreSQL component resource.
func NewDatabase(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Database, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Database{}
	err := ctx.RegisterComponentResource("udap:aws:RdsDatabase", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/rds"),
	}

	// Resolve optional inputs to their documented defaults. Never
	// type-assert a pulumi Input to a concrete type — callers legitimately
	// pass Outputs from other resources, which would panic.
	engine := args.Engine
	if engine == nil {
		engine = pulumi.String("postgres")
	}

	engineVersion := args.EngineVersion
	if engineVersion == nil {
		engineVersion = pulumi.String("15")
	}

	paramFamily := args.ParameterGroupFamily
	if paramFamily == nil {
		paramFamily = pulumi.String("postgres15")
	}

	instanceClass := args.InstanceClass
	if instanceClass == nil {
		instanceClass = pulumi.String("db.t3.micro")
	}

	allocatedStorage := args.AllocatedStorage
	if allocatedStorage == nil {
		allocatedStorage = pulumi.Int(20)
	}

	backupRetention := args.BackupRetentionDays
	if backupRetention == nil {
		backupRetention = pulumi.Int(7)
	}

	port := args.Port
	if port == nil {
		port = pulumi.Int(5432)
	}

	deletionProtection := args.DeletionProtection
	if deletionProtection == nil {
		deletionProtection = pulumi.Bool(false)
	}

	skipFinalSnapshot := args.SkipFinalSnapshot
	if skipFinalSnapshot == nil {
		skipFinalSnapshot = pulumi.Bool(false)
	}

	// DB Security Group
	sg, err := ec2.NewSecurityGroup(ctx, fmt.Sprintf("%s-db-sg", name), &ec2.SecurityGroupArgs{
		VpcId:       args.VpcID,
		Description: pulumi.Sprintf("Security group for RDS %s", args.Identifier),
		Ingress: ec2.SecurityGroupIngressArray{
			&ec2.SecurityGroupIngressArgs{
				FromPort:              port,
				ToPort:                port,
				Protocol:              pulumi.String("tcp"),
				SourceSecurityGroupId: args.AppSGID,
				Description:           pulumi.String("Database port from app"),
			},
		},
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Subnet Group
	subnetGroup, err := rds.NewSubnetGroup(ctx, fmt.Sprintf("%s-subnet-group", name), &rds.SubnetGroupArgs{
		SubnetIds: args.SubnetIDs,
		Tags:      tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Parameter Group
	paramGroup, err := rds.NewParameterGroup(ctx, fmt.Sprintf("%s-params", name), &rds.ParameterGroupArgs{
		Family: paramFamily,
		Parameters: rds.ParameterGroupParameterArray{
			&rds.ParameterGroupParameterArgs{
				Name:  pulumi.String("log_connections"),
				Value: pulumi.String("1"),
			},
			&rds.ParameterGroupParameterArgs{
				Name:  pulumi.String("log_disconnections"),
				Value: pulumi.String("1"),
			},
		},
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// RDS Instance
	instance, err := rds.NewInstance(ctx, fmt.Sprintf("%s-db", name), &rds.InstanceArgs{
		Identifier:              args.Identifier,
		Engine:                  engine,
		EngineVersion:           engineVersion,
		InstanceClass:           instanceClass,
		AllocatedStorage:        allocatedStorage,
		DbName:                  args.DBName,
		Username:                args.DBUsername,
		Password:                args.DBPassword,
		Port:                    port,
		DbSubnetGroupName:       subnetGroup.Name,
		ParameterGroupName:      paramGroup.Name,
		VpcSecurityGroupIds:     pulumi.StringArray{sg.ID()},
		StorageEncrypted:        pulumi.Bool(true),
		PubliclyAccessible:      pulumi.Bool(false),
		BackupRetentionPeriod:   backupRetention,
		DeletionProtection:      deletionProtection,
		SkipFinalSnapshot:       skipFinalSnapshot,
		FinalSnapshotIdentifier: pulumi.Sprintf("%s-final-snapshot", args.Identifier),
		Tags:                    tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.Endpoint = instance.Address
	component.Port = instance.Port
	component.DBName = instance.DbName.Elem()
	component.SecurityGroupID = sg.ID().ToStringOutput()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"endpoint":        component.Endpoint,
		"port":            component.Port,
		"dbName":          component.DBName,
		"securityGroupId": component.SecurityGroupID,
	})

	return component, nil
}
