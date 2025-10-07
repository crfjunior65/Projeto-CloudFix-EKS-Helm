# Data source para obter account ID atual
data "aws_caller_identity" "current" {}

# IAM Role para usuários visualizarem EKS
resource "aws_iam_role" "eks_viewer_role" {
  name = "${var.prefix}-${var.project_name}-eks-viewer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = length(var.trusted_users_arns) > 0 ? var.trusted_users_arns : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.prefix}-${var.project_name}-eks-viewer-role"
  })
}

# Policy para visualizar recursos EKS
resource "aws_iam_policy" "eks_viewer_policy" {
  name = "${var.prefix}-${var.project_name}-eks-viewer-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Anexar policy ao role
resource "aws_iam_role_policy_attachment" "eks_viewer_attachment" {
  role       = aws_iam_role.eks_viewer_role.name
  policy_arn = aws_iam_policy.eks_viewer_policy.arn
}
