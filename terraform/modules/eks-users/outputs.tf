output "eks_viewer_role_arn" {
  description = "ARN do IAM role para visualização EKS"
  value       = aws_iam_role.eks_viewer_role.arn
}

output "eks_viewer_role_name" {
  description = "Nome do IAM role para visualização EKS"
  value       = aws_iam_role.eks_viewer_role.name
}
