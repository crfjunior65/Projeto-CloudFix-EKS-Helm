variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o cluster será criado"
  type        = string
}


variable "eks_version" {
  description = "Versão do cluster EKS"
  type        = string
  #default     = "1.29"
}

variable "subnet_ids" {
  description = "IDs das subnets onde o cluster será criado"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs dos security groups para o cluster"
  type        = list(string)
}

variable "node_group_name" {
  description = "Nome do node group"
  type        = string
  default     = "cloudfix-hml-apps" # Defina o valor desejado na chamada do módulo ou no tfvars
}

variable "node_group_instance_types" {
  description = "Tipos de instância para os nós do EKS"
  type        = list(string)
  #default     = ["t3.medium"] #["t3.micro"]
}

# node_group_name          = "cloudfix-nodes"
# node_group_desired_size  = 2
# node_group_max_size      = 3
# node_group_min_size      = 1
# node_group_disk_size     = 20


variable "node_group_desired_size" {
  description = "Número desejado de nós no node group"
  type        = number
  #default     = 2
}

variable "node_group_min_size" {
  description = "Número mínimo de nós no node group"
  type        = number
  #default     = 1
}

variable "node_group_max_size" {
  description = "Número máximo de nós no node group"
  type        = number
  #default     = 5
}

variable "tags" {
  description = "Tags comuns para todos os recursos"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Ambiente de implantação (ex: dev, hml, prod)"
  type        = string
  default     = "hml"
}

variable "prefix" {
  description = "Prefixo do projeto (herdado da raiz)"
  type        = string
  default     = ""
}
