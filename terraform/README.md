<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.15.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_load_balancer_controller"></a> [aws\_load\_balancer\_controller](#module\_aws\_load\_balancer\_controller) | ./modules/aws-load-balancer-controller | n/a |
| <a name="module_bastion_host"></a> [bastion\_host](#module\_bastion\_host) | ./modules/bastion_host | n/a |
| <a name="module_bastion_scheduler"></a> [bastion\_scheduler](#module\_bastion\_scheduler) | ./modules/bastion-scheduler | n/a |
| <a name="module_container_insights"></a> [container\_insights](#module\_container\_insights) | ./modules/container-insights | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ./modules/ecr | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_eks_users"></a> [eks\_users](#module\_eks\_users) | ./modules/eks-users | n/a |
| <a name="module_monitoring"></a> [monitoring](#module\_monitoring) | ./modules/monitoring | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | ./modules/rds | n/a |
| <a name="module_rds_scheduler"></a> [rds\_scheduler](#module\_rds\_scheduler) | ./modules/rds-scheduler | n/a |
| <a name="module_valkey"></a> [valkey](#module\_valkey) | ./modules/valkey | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.cloudfix_dashboard_funcional_completo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_eks_addon.cloudwatch_observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [time_sleep.wait_for_cloudwatch](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_LABEL"></a> [LABEL](#input\_LABEL) | Tipo de agregação para métricas (AVG, MAX, MIN, SUM) | `string` | `"AVG"` | no |
| <a name="input_awsProfile"></a> [awsProfile](#input\_awsProfile) | AWS Profile to use for authentication | `string` | `"default"` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | Tipo de instância para o Bastion Host | `string` | `"t3.micro"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Nome do banco de dados | `string` | `"cloudfix-postgres"` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Senha do banco de dados | `string` | `"cloudfix_password"` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Nome de usuário do banco de dados | `string` | `"cloudfix"` | no |
| <a name="input_deploy_test_app"></a> [deploy\_test\_app](#input\_deploy\_test\_app) | Deploy aplicação de teste (nginx). Em produção: false | `bool` | `true` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Nome do cluster EKS | `string` | n/a | yes |
| <a name="input_eks_version"></a> [eks\_version](#input\_eks\_version) | Versão do EKS | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment name, such as 'dev', 'homolog', 'staging', or 'prod'. his categorizes the Network resources by their usage stage | `string` | `"homolog"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Nome do par de chaves SSH para acesso às instâncias EC2 | `string` | `"aws-key-terraform"` | no |
| <a name="input_monitored_services"></a> [monitored\_services](#input\_monitored\_services) | Uma lista de serviços específicos para criar alarmes detalhados. | <pre>list(object({<br>    name          = string<br>    namespace     = string<br>    min_pod_count = number<br>    cpu_threshold = number<br>    mem_threshold = number<br>  }))</pre> | <pre>[<br>  {<br>    "cpu_threshold": 80,<br>    "mem_threshold": 80,<br>    "min_pod_count": 2,<br>    "name": "cloudfix-app",<br>    "namespace": "default"<br>  }<br>]</pre> | no |
| <a name="input_monitoring_sns_topic_arn"></a> [monitoring\_sns\_topic\_arn](#input\_monitoring\_sns\_topic\_arn) | Opcional: O ARN de um tópico SNS para notificações dos alarmes do CloudWatch. | `string` | `""` | no |
| <a name="input_node_group_desired_size"></a> [node\_group\_desired\_size](#input\_node\_group\_desired\_size) | Tamanho desejado do node group do EKS | `number` | `1` | no |
| <a name="input_node_group_disk_size"></a> [node\_group\_disk\_size](#input\_node\_group\_disk\_size) | Tamanho do disco (em GB) para cada nó do node group do EKS | `number` | n/a | yes |
| <a name="input_node_group_instance_types"></a> [node\_group\_instance\_types](#input\_node\_group\_instance\_types) | Tipos de instância para o node group do EKS | `list(string)` | n/a | yes |
| <a name="input_node_group_max_size"></a> [node\_group\_max\_size](#input\_node\_group\_max\_size) | Tamanho máximo do node group do EKS | `number` | `4` | no |
| <a name="input_node_group_min_size"></a> [node\_group\_min\_size](#input\_node\_group\_min\_size) | Tamanho mínimo do node group do EKS | `number` | `1` | no |
| <a name="input_node_group_name"></a> [node\_group\_name](#input\_node\_group\_name) | Nome do node group do EKS | `string` | `"cloudfix-nodes"` | no |
| <a name="input_num_azs"></a> [num\_azs](#input\_num\_azs) | Number of Availability Zones for use (2 or 3) | `number` | `2` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix to project name | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name to project for tagging and identification purposes | `string` | n/a | yes |
| <a name="input_rds_instance_class"></a> [rds\_instance\_class](#input\_rds\_instance\_class) | Classe da instância RDS | `string` | n/a | yes |
| <a name="input_rds_storage"></a> [rds\_storage](#input\_rds\_storage) | Armazenamento inicial do RDS em GB | `number` | `50` | no |
| <a name="input_region"></a> [region](#input\_region) | Region AWS where the Network resources will be deployed, e.g., us-east-1, for the USA North Virginia region | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags padrão para todos os recursos | `map(string)` | <pre>{<br>  "Environment": "homologation",<br>  "ManagedBy": "terraform",<br>  "Owner": "devops-team",<br>  "Projeto": "cloudfix"<br>}</pre> | no |
| <a name="input_trusted_users_arns"></a> [trusted\_users\_arns](#input\_trusted\_users\_arns) | List of IAM user ARNs that can assume the EKS viewer role | `list(string)` | `[]` | no |
| <a name="input_valkey_engine_version"></a> [valkey\_engine\_version](#input\_valkey\_engine\_version) | Valkey engine version | `string` | `"8.0"` | no |
| <a name="input_valkey_node_type"></a> [valkey\_node\_type](#input\_valkey\_node\_type) | Tipo de instância para o Valkey | `string` | `"cache.t3.micro"` | no |
| <a name="input_valkey_num_nodes"></a> [valkey\_num\_nodes](#input\_valkey\_num\_nodes) | Number of Valkey cache nodes | `number` | `2` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block para a VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azs_avaliable"></a> [azs\_avaliable](#output\_azs\_avaliable) | n/a |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | n/a |
| <a name="output_db_instance_id"></a> [db\_instance\_id](#output\_db\_instance\_id) | n/a |
| <a name="output_db_instance_name"></a> [db\_instance\_name](#output\_db\_instance\_name) | n/a |
| <a name="output_db_instance_password"></a> [db\_instance\_password](#output\_db\_instance\_password) | Senha da instância do banco de dados (marcada como sensível). |
| <a name="output_db_instance_username"></a> [db\_instance\_username](#output\_db\_instance\_username) | n/a |
| <a name="output_eks_viewer_role_arn"></a> [eks\_viewer\_role\_arn](#output\_eks\_viewer\_role\_arn) | ARN do IAM role para visualização EKS |
| <a name="output_k8s_name"></a> [k8s\_name](#output\_k8s\_name) | n/a |
| <a name="output_rds_scheduler_lambda_name"></a> [rds\_scheduler\_lambda\_name](#output\_rds\_scheduler\_lambda\_name) | Nome da função Lambda RDS Scheduler |
| <a name="output_rds_scheduler_start_time"></a> [rds\_scheduler\_start\_time](#output\_rds\_scheduler\_start\_time) | Horário de início do RDS (08:00 Brasília) |
| <a name="output_rds_scheduler_stop_time"></a> [rds\_scheduler\_stop\_time](#output\_rds\_scheduler\_stop\_time) | Horário de parada do RDS (18:00 Brasília) |
| <a name="output_valkey_endpoint"></a> [valkey\_endpoint](#output\_valkey\_endpoint) | Endpoint primário do Valkey |
| <a name="output_valkey_port"></a> [valkey\_port](#output\_valkey\_port) | Porta do Valkey |
| <a name="output_valkey_reader_endpoint"></a> [valkey\_reader\_endpoint](#output\_valkey\_reader\_endpoint) | Endpoint de leitura do Valkey |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->
