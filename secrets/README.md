<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.app_full_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.app_full_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.app_full_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.secret_vars](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN do OIDC Provider do EKS (caso vá usar IRSA) | `string` | `"arn:aws:iam::886121092353:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EA505A07389D047CD97EC76096F34D68"` | no |
| <a name="input_rds_arn"></a> [rds\_arn](#input\_rds\_arn) | ARN do cluster ou instância RDS | `string` | `"*"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy to | `string` | `"us-east-1"` | no |
| <a name="input_s3_arn"></a> [s3\_arn](#input\_s3\_arn) | ARN do bucket S3 utilizado (ex: arn:aws:s3:::seu-bucket/*) | `string` | `"*"` | no |
| <a name="input_secretVars"></a> [secretVars](#input\_secretVars) | Variáveis sensíveis do projeto que serão armazenadas no Secret Manager | `map(string)` | `{}` | no |
| <a name="input_secrets_description"></a> [secrets\_description](#input\_secrets\_description) | Descricao do segredo | `string` | `"ID utilizado para integração com o serviço Shield"` | no |
| <a name="input_secrets_name"></a> [secrets\_name](#input\_secrets\_name) | Nome do segredo | `string` | `"secrets-shield-id"` | no |
| <a name="input_serviceaccount_name"></a> [serviceaccount\_name](#input\_serviceaccount\_name) | Nome do ServiceAccount no EKS | `string` | `"app-sa"` | no |
| <a name="input_serviceaccount_namespace"></a> [serviceaccount\_namespace](#input\_serviceaccount\_namespace) | Namespace do ServiceAccount no EKS | `string` | `"default"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags padrão para o bucket S3 | `map(string)` | <pre>{<br>  "Environment": "homologation",<br>  "ManagedBy": "terraform",<br>  "Owner": "devops-team",<br>  "Projeto": "cloudfix"<br>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
