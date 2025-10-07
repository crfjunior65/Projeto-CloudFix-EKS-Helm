#____________________________________________________________________________
#-------------------------- Secret Manager ----------------------------------
#____________________________________________________________________________

resource "aws_secretsmanager_secret" "secret" {
  name        = var.secrets_name
  description = var.secrets_description
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "secret_vars" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode(var.secretVars)
}
#____________________________________________________________________________
#-------------------------- Variáveis Gerais --------------------------------
#____________________________________________________________________________


variable "secrets_name" {
  description = "Nome do segredo"
  type        = string
  default     = "secrets-shield-id"
}

variable "secrets_description" {
  description = "Descricao do segredo"
  type        = string
  default     = "ID utilizado para integração com o serviço Shield"
}

variable "secretVars" {
  description = "Variáveis sensíveis do projeto que serão armazenadas no Secret Manager"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags padrão para o bucket S3"
  type        = map(string)
  default = {
    Environment = "homologation"
    Projeto     = "cloudfix"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}

#____________________________________________________________________________
#---------------------- Variáveis de Permissões AWS -------------------------
#____________________________________________________________________________

variable "s3_arn" {
  description = "ARN do bucket S3 utilizado (ex: arn:aws:s3:::seu-bucket/*)"
  type        = string
  default     = "*"
}

variable "rds_arn" {
  description = "ARN do cluster ou instância RDS"
  type        = string
  default     = "*"
}

variable "oidc_provider_arn" {
  description = "ARN do OIDC Provider do EKS (caso vá usar IRSA)"
  type        = string
  default     = "arn:aws:iam::886121092353:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EA505A07389D047CD97EC76096F34D68"
}

variable "serviceaccount_namespace" {
  description = "Namespace do ServiceAccount no EKS"
  type        = string
  default     = "default"
}
variable "serviceaccount_name" {
  description = "Nome do ServiceAccount no EKS"
  type        = string
  default     = "app-sa"
}

#____________________________________________________________________________
#---------------------- IAM Role e Policy para EKS/IRSA ---------------------
#____________________________________________________________________________

# IAM Role para EKS (IRSA) — ajuste o assume_role_policy conforme o serviço se necessário
resource "aws_iam_role" "app_full_access" {
  name = "AppFullAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "arn:aws:iam::", "")}:sub" = "system:serviceaccount:${var.serviceaccount_namespace}:${var.serviceaccount_name}"
          }
        }
      }
    ]
  })
}

# IAM Policy agregando permissões para vários serviços AWS
resource "aws_iam_policy" "app_full_policy" {
  name        = "AppFullPolicy"
  description = "Permite acesso aos principais recursos do projeto"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [aws_secretsmanager_secret.secret.arn]
      },
      # S3
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = var.s3_arn
      },
      # CloudWatch Logs (para logs de aplicação)
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# Anexar policy à role
resource "aws_iam_role_policy_attachment" "app_full_attach" {
  role       = aws_iam_role.app_full_access.name
  policy_arn = aws_iam_policy.app_full_policy.arn
}
