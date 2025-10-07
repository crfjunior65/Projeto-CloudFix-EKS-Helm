variable "prefix" {
  description = "Prefix to project name"
  type        = string
}

variable "project_name" {
  description = "Name to project for tagging and identification purposes"
  type        = string
}

variable "trusted_users_arns" {
  description = "List of IAM user ARNs that can assume the EKS viewer role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags padrão para todos os recursos"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, hml)"
  type        = string

}
