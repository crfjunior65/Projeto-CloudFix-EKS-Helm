variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN do OIDC provider do EKS"
  type        = string
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}

variable "prefix" {
  description = "Prefixo do projeto (herdado da raiz)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, hml)"
  type        = string

}
