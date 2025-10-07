output "iam_role_arn" {
  description = "ARN da IAM role do AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "iam_role_name" {
  description = "Nome da IAM role do AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.name
}
