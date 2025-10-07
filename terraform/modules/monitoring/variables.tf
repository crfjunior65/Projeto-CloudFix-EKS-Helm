variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "node_group_asg_name" {
  description = "The name of the Auto Scaling Group for the EKS nodes"
  type        = string
}

variable "db_instance_identifier" {
  description = "The identifier of the RDS database instance"
  type        = string
}

variable "sns_topic_arn_for_alarms" {
  description = "The ARN of the SNS topic to send alarm notifications to"
  type        = string
  default     = ""
}

variable "dashboard_definitions" {
  description = "A map of CloudWatch dashboard definitions, where the key is the dashboard name and the value is the JSON body."
  type        = map(string)
  default     = {}
}

variable "services_to_monitor" {
  description = "A list of specific services to create detailed alarms for."
  type = list(object({
    name          = string
    namespace     = string
    min_pod_count = number
    cpu_threshold = number
    mem_threshold = number
  }))
  default = []
}

variable "prefix" {
  description = "Prefixo do projeto (herdado da raiz)"
  type        = string
  default     = ""
}
