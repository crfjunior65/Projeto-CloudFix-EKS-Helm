# Cluster EKS
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]

  tags = var.tags
}

# SOLUÇÃO DEFINITIVA: Launch Template para nomear as instâncias EC2.
# Este recurso atua como um "molde" para as instâncias do Node Group, garantindo a aplicação correta das tags.
resource "aws_launch_template" "eks_nodes" {
  name = "${var.cluster_name}-${var.node_group_name}-lt"

  # Especifica as tags que serão aplicadas diretamente nas instâncias EC2.
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        # Tag de nomeação para as instâncias EC2, aplicada diretamente via Launch Template.
        Name = "${var.cluster_name}-${var.node_group_name}-node"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.subnet_ids

  # Aponta o Node Group para usar o Launch Template definido acima.
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  # Suas variáveis do terraform.tfvars
  # node_group_name         = var.node_group_name
  # node_group_desired_size = var.node_group_desired_size
  # node_group_max_size     = var.node_group_max_size
  # node_group_min_size     = var.node_group_min_size
  # node_group_disk_size    = var.node_group_disk_size


  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  # O tipo de instância continua aqui, pois não foi especificado no Launch Template.
  instance_types = var.node_group_instance_types

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]

  labels = {
    Name = "eks-node-${var.environment}-${var.node_group_name}"
  }

  # As tags aqui são aplicadas ao Auto Scaling Group, não diretamente às instâncias.
  # A tag 'Name' da instância agora é controlada exclusivamente pelo Launch Template.
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}
