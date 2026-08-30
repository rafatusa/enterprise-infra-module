// Package cloudwatch provides a Pulumi component resource for AWS CloudWatch
// with log group, metric alarms, and dashboard.
// Mirrors infra/modules/aws/cloudwatch.
//
// Usage:
//
//	cw, err := cloudwatch.NewMonitoring(ctx, "app", &cloudwatch.Args{
//	    Name:        pulumi.String("app"),
//	    Project:     pulumi.String("my-project"),
//	    Environment: pulumi.String("production"),
//	    InstanceID:  instance.InstanceID,
//	})
package cloudwatch

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/cloudwatch"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the CloudWatch monitoring component.
type Args struct {
	// Name is the base name for all CloudWatch resources.
	Name pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// InstanceID is the EC2 instance to monitor (optional).
	InstanceID pulumi.StringInput
	// LogRetentionDays is the CloudWatch log retention period. Default: 30.
	LogRetentionDays pulumi.IntInput
	// AlarmEmailEndpoint is the SNS email for alarm notifications.
	AlarmEmailEndpoint pulumi.StringInput
	// CPUAlarmThreshold triggers at this CPU %. Default: 80.
	CPUAlarmThreshold pulumi.Float64Input
}

// Monitoring is the component resource output.
type Monitoring struct {
	pulumi.ResourceState

	LogGroupName    pulumi.StringOutput `pulumi:"logGroupName"`
	LogGroupARN     pulumi.StringOutput `pulumi:"logGroupArn"`
	CPUAlarmARN     pulumi.StringOutput `pulumi:"cpuAlarmArn"`
	DashboardName   pulumi.StringOutput `pulumi:"dashboardName"`
}

// NewMonitoring creates a new CloudWatch monitoring component resource.
func NewMonitoring(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Monitoring, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Monitoring{}
	err := ctx.RegisterComponentResource("udap:aws:CloudWatchMonitoring", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/cloudwatch"),
	}

	// Log Group
	logGroup, err := cloudwatch.NewLogGroup(ctx, fmt.Sprintf("%s-logs", name), &cloudwatch.LogGroupArgs{
		Name:            pulumi.Sprintf("/udap/%s", args.Name),
		RetentionInDays: pulumi.Int(30),
		Tags:            tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// CPU Alarm
	var cpuAlarm *cloudwatch.MetricAlarm
	if args.InstanceID != nil {
		cpuAlarm, err = cloudwatch.NewMetricAlarm(ctx, fmt.Sprintf("%s-cpu-alarm", name), &cloudwatch.MetricAlarmArgs{
			AlarmName:          pulumi.Sprintf("%s-high-cpu", args.Name),
			ComparisonOperator: pulumi.String("GreaterThanThreshold"),
			EvaluationPeriods:  pulumi.Int(2),
			MetricName:         pulumi.String("CPUUtilization"),
			Namespace:          pulumi.String("AWS/EC2"),
			Period:             pulumi.Int(300),
			Statistic:          pulumi.String("Average"),
			Threshold:          pulumi.Float64(80),
			AlarmDescription:   pulumi.Sprintf("High CPU on %s", args.Name),
			Dimensions: pulumi.StringMap{
				"InstanceId": args.InstanceID,
			},
			Tags: tags,
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	// Dashboard
	dashboard, err := cloudwatch.NewDashboard(ctx, fmt.Sprintf("%s-dashboard", name), &cloudwatch.DashboardArgs{
		DashboardName: pulumi.Sprintf("%s-dashboard", args.Name),
		DashboardBody: pulumi.Sprintf(`{
			"widgets": [{
				"type": "metric",
				"properties": {
					"title": "%s CPU Utilization",
					"metrics": [["AWS/EC2", "CPUUtilization"]],
					"period": 300,
					"stat": "Average"
				}
			}]
		}`, args.Name),
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.LogGroupName = logGroup.Name
	component.LogGroupARN = logGroup.Arn
	component.DashboardName = dashboard.DashboardName

	if cpuAlarm != nil {
		component.CPUAlarmARN = cpuAlarm.Arn
	} else {
		component.CPUAlarmARN = pulumi.String("").ToStringOutput()
	}

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"logGroupName":  component.LogGroupName,
		"logGroupArn":   component.LogGroupARN,
		"cpuAlarmArn":   component.CPUAlarmARN,
		"dashboardName": component.DashboardName,
	})

	return component, nil
}
