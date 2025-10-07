<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.11.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_metric_alarm.cloudfix_app_memory_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cloudfix_app_pod_count_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cluster_cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.cluster_memory_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the EKS cluster | `string` | n/a | yes |
| <a name="input_dashboard_definitions"></a> [dashboard\_definitions](#input\_dashboard\_definitions) | A map of CloudWatch dashboard definitions, where the key is the dashboard name and the value is the JSON body. | `map(string)` | `{}` | no |
| <a name="input_db_instance_identifier"></a> [db\_instance\_identifier](#input\_db\_instance\_identifier) | The identifier of the RDS database instance | `string` | n/a | yes |
| <a name="input_node_group_asg_name"></a> [node\_group\_asg\_name](#input\_node\_group\_asg\_name) | The name of the Auto Scaling Group for the EKS nodes | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefixo do projeto (herdado da raiz) | `string` | `""` | no |
| <a name="input_services_to_monitor"></a> [services\_to\_monitor](#input\_services\_to\_monitor) | A list of specific services to create detailed alarms for. | <pre>list(object({<br>    name          = string<br>    namespace     = string<br>    min_pod_count = number<br>    cpu_threshold = number<br>    mem_threshold = number<br>  }))</pre> | `[]` | no |
| <a name="input_sns_topic_arn_for_alarms"></a> [sns\_topic\_arn\_for\_alarms](#input\_sns\_topic\_arn\_for\_alarms) | The ARN of the SNS topic to send alarm notifications to | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
