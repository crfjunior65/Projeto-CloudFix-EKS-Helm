variable "region" {
  description = "Region AWS where the Network resources will be deployed, e.g., us-east-1, for the USA North Virginia region"
  type        = string
  default     = "us-east-1"
}

variable "eks_version" {
  description = "Versão do EKS"
  type        = string
  #default     = "1.33"
}

variable "eks_cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  #default     = "hml-cloudfix-eks-cluster"
}

# node_group_name          = "cloudfix-nodes"
# node_group_desired_size  = 2
# node_group_max_size      = 3
# node_group_min_size      = 1
# node_group_disk_size     = 20
variable "node_group_name" {
  description = "Nome do node group do EKS"
  type        = string
  default     = "cloudfix-nodes"
}
variable "node_group_desired_size" {
  description = "Tamanho desejado do node group do EKS"
  type        = number
  default     = 1
}
variable "node_group_max_size" {
  description = "Tamanho máximo do node group do EKS"
  type        = number
  default     = 4
}
variable "node_group_min_size" {
  description = "Tamanho mínimo do node group do EKS"
  type        = number
  default     = 1
}
variable "node_group_disk_size" {
  description = "Tamanho do disco (em GB) para cada nó do node group do EKS"
  type        = number
  #default     = 20
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "rds_instance_class" {
  description = "Classe da instância RDS"
  type        = string
}

variable "rds_storage" {
  description = "Armazenamento inicial do RDS em GB"
  type        = number
  default     = 50
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "cloudfix-postgres"
}

variable "db_username" {
  description = "Nome de usuário do banco de dados"
  type        = string
  default     = "cloudfix"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
  default     = "cloudfix_password" # Em produção, usar um secret manager
}

variable "tags" {
  description = "Tags padrão para todos os recursos"
  type        = map(string)
  default = {
    Environment = "homologation"
    Projeto     = "cloudfix"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}

variable "node_group_instance_types" {
  description = "Tipos de instância para o node group do EKS"
  type        = list(string)

}

variable "monitoring_sns_topic_arn" {
  description = "Opcional: O ARN de um tópico SNS para notificações dos alarmes do CloudWatch."
  type        = string
  default     = ""
}

variable "monitored_services" {
  description = "Uma lista de serviços específicos para criar alarmes detalhados."
  type = list(object({
    name          = string
    namespace     = string
    min_pod_count = number
    cpu_threshold = number
    mem_threshold = number
  }))
  default = [
    {
      name          = "cloudfix-app"
      namespace     = "default"
      min_pod_count = 2
      cpu_threshold = 80
      mem_threshold = 80
    }
  ]
}

variable "deploy_test_app" {
  description = "Deploy aplicação de teste (nginx). Em produção: false"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Deployment environment name, such as 'dev', 'homolog', 'staging', or 'prod'. his categorizes the Network resources by their usage stage"
  type        = string
  default     = "homolog"
}

#  Variavel solicitado pela AWS na Criação de DashBoards
variable "LABEL" {
  description = "Tipo de agregação para métricas (AVG, MAX, MIN, SUM)"
  type        = string
  default     = "AVG"
}

variable "project_name" {
  description = "Name to project for tagging and identification purposes"
  type        = string
}

variable "valkey_engine_version" {
  description = "Valkey engine version"
  type        = string
  default     = "8.0"
}

variable "valkey_num_nodes" {
  description = "Number of Valkey cache nodes"
  type        = number
  default     = 2
}

variable "num_azs" {
  description = "Number of Availability Zones for use (2 or 3)"
  type        = number
  default     = 2
  validation {
    condition     = var.num_azs >= 2 && var.num_azs <= 3
    error_message = "Number of AZs must be 2 or 3."
  }
}


variable "prefix" {
  description = "Prefix to project name"
  type        = string
  #default     = "cloudfix"
}

variable "key_name" {
  description = "Nome do par de chaves SSH para acesso às instâncias EC2"
  type        = string
  default     = "aws-key-terraform"
}

variable "bastion_instance_type" {
  description = "Tipo de instância para o Bastion Host"
  type        = string
  default     = "t3.micro"
}

# Valkey Variables
variable "valkey_node_type" {
  description = "Tipo de instância para o Valkey"
  type        = string
  default     = "cache.t3.micro"
}


# EKS Users Variables
variable "trusted_users_arns" {
  description = "List of IAM user ARNs that can assume the EKS viewer role"
  type        = list(string)
  default     = []
}
