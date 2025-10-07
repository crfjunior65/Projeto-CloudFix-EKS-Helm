output "vpc_id" {
  value = module.networking.vpc_id
}

output "db_instance_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_instance_id" {
  value = module.rds.db_instance_id
}

output "db_instance_name" {
  value = module.rds.db_instance_name
}

output "db_instance_username" {
  value = module.rds.db_instance_username
}

output "db_instance_password" {
  description = "Senha da instância do banco de dados (marcada como sensível)."
  value       = module.rds.db_instance_password
  sensitive   = true
}

output "k8s_name" {
  value = module.eks.k8s_name
}

output "azs_avaliable" {
  value = data.aws_availability_zones.available.names
}

# Valkey Outputs
output "valkey_endpoint" {
  description = "Endpoint primário do Valkey"
  value       = module.valkey.valkey_endpoint
}

output "valkey_port" {
  description = "Porta do Valkey"
  value       = module.valkey.valkey_port
}

output "valkey_reader_endpoint" {
  description = "Endpoint de leitura do Valkey"
  value       = module.valkey.valkey_reader_endpoint
}

# EKS Users Outputs
output "eks_viewer_role_arn" {
  description = "ARN do IAM role para visualização EKS"
  value       = module.eks_users.eks_viewer_role_arn
}

# RDS Scheduler Outputs
output "rds_scheduler_lambda_name" {
  description = "Nome da função Lambda RDS Scheduler"
  value       = module.rds_scheduler.lambda_function_name
}

output "rds_scheduler_start_time" {
  description = "Horário de início do RDS (08:00 Brasília)"
  value       = "08:00 Brasília (11:00 UTC) - Segunda a Sexta"
}

output "rds_scheduler_stop_time" {
  description = "Horário de parada do RDS (18:00 Brasília)"
  value       = "18:00 Brasília (21:00 UTC) - Segunda a Sexta"
}
