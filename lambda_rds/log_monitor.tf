# Variáveis para reutilização
variable "app_log_group_name" {
  type        = string
  description = "Nome do log group da aplicação"
  default     = "/aws/application/app-logs"
}

variable "db_instance_identifier" {
  type        = string
  description = "ID da instância RDS"
  default     = "cloudfix"
}

# Lambda para monitoramento de logs
data "archive_file" "log_monitor_zip" {
  type        = "zip"
  source_file = "${path.module}/log_monitor_function.py"
  output_path = "${path.module}/log_monitor_function.zip"
}

resource "aws_lambda_function" "log_monitor_lambda" {
  function_name = "RDSLogMonitor"
  handler       = "log_monitor_function.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.rds_scheduler_role.arn

  filename         = data.archive_file.log_monitor_zip.output_path
  source_code_hash = data.archive_file.log_monitor_zip.output_base64sha256

  environment {
    variables = {
      DB_INSTANCE_IDENTIFIER = var.db_instance_identifier
    }
  }

  timeout = 60
}

# Log Group genérico (cria se não existir)
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = var.app_log_group_name
  retention_in_days = 7

  # Não falha se já existir
  lifecycle {
    ignore_changes = [retention_in_days]
  }
}

# Subscription Filter - Liga logs à Lambda
resource "aws_cloudwatch_log_subscription_filter" "rds_error_filter" {
  name            = "RDSErrorSubscription"
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  filter_pattern  = "?ERROR ?ERRO ?connection ?conexao ?timeout ?refused"
  destination_arn = aws_lambda_function.log_monitor_lambda.arn
}

# Permissão para CloudWatch Logs invocar Lambda
resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_monitor_lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.app_logs.arn}:*"
}

# Outputs para facilitar uso
output "log_group_name" {
  value       = aws_cloudwatch_log_group.app_logs.name
  description = "Nome do log group para sua aplicação usar"
}

output "log_monitor_function_name" {
  value       = aws_lambda_function.log_monitor_lambda.function_name
  description = "Nome da função Lambda de monitoramento"
}

output "help_usage_examples" {
  value = <<-EOT

  📚 EXEMPLOS DE USO EM DIFERENTES AMBIENTES:

  🏢 PRODUÇÃO:
  terraform apply -var="db_instance_identifier=prod-database" -var="app_log_group_name=/aws/application/prod-app"

  🧪 DESENVOLVIMENTO:
  terraform apply -var="db_instance_identifier=dev-db" -var="app_log_group_name=/aws/application/dev-app"

  🔄 STAGING:
  terraform apply -var="db_instance_identifier=staging-rds" -var="app_log_group_name=/aws/lambda/staging-logs"

  📁 OU CRIAR ARQUIVO terraform.tfvars:
  echo 'db_instance_identifier = "minha-rds"' > terraform.tfvars
  echo 'app_log_group_name = "/aws/application/minha-app"' >> terraform.tfvars
  terraform apply

  EOT
}

output "help_discover_rds_instances" {
  value = <<-EOT

  🔍 DESCOBRIR INSTÂNCIAS RDS DISPONÍVEIS:

  aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine]' --output table

  📝 USAR INSTÂNCIA ESPECÍFICA:
  terraform apply -var="db_instance_identifier=SUA-RDS-ID"

  EOT
}

output "help_discover_log_groups" {
  value = <<-EOT

  📋 DESCOBRIR LOG GROUPS EXISTENTES:

  aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output table

  📝 USAR LOG GROUP ESPECÍFICO:
  terraform apply -var="app_log_group_name=/aws/lambda/seu-log-group"

  💡 CRIAR NOVO LOG GROUP:
  aws logs create-log-group --log-group-name /aws/application/minha-app

  EOT
}

output "help_test_configuration" {
  value = <<-EOT

  🧪 TESTAR CONFIGURAÇÃO APÓS DEPLOY:

  1️⃣ Verificar se Lambda foi criada:
  aws lambda get-function --function-name RDSLogMonitor

  2️⃣ Testar envio de log (simular erro):
  aws logs put-log-events --log-group-name ${aws_cloudwatch_log_group.app_logs.name} --log-stream-name test-stream --log-events timestamp=$(date +%s)000,message="ERROR connection failed to database"

  3️⃣ Ver logs da Lambda:
  aws logs filter-log-events --log-group-name /aws/lambda/RDSLogMonitor --start-time $(date -d '5 minutes ago' +%s)000

  EOT
}
