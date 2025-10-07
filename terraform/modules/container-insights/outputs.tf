output "cloudwatch_agent_role_arn" {
  description = "ARN da IAM role do CloudWatch Agent"
  value       = aws_iam_role.cloudwatch_agent.arn
}
