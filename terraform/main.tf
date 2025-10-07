module "networking" {
  source = "./modules/networking"

  vpc_cidr = var.vpc_cidr

  subnets_public            = local.public_subnets_cidrs
  eks_private_subnets       = local.eks_subnets_cidrs
  rds_private_subnets       = local.rds_subnets_cidrs
  prefix                    = local.prefix_project
  bastion_security_group_id = module.bastion_host.bastion_security_group_id
  environment               = local.environment

  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.num_azs)

  tags = var.tags

}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.eks_cluster_name #  var.project_name
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.eks_private_subnet_ids
  security_group_ids = [module.networking.eks_security_group_id]
  prefix             = local.prefix_project
  eks_version        = var.eks_version # "1.33"
  environment        = local.environment

  node_group_name = var.node_group_name
  #Variable node_group_instance_types = ["t3.medium"]
  node_group_instance_types = var.node_group_instance_types #["t3.micro"]
  node_group_desired_size   = var.node_group_desired_size
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size

  tags = var.tags
}

module "rds" {
  source = "./modules/rds"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  vpc_id                        = module.networking.vpc_id
  subnet_ids                    = module.networking.rds_private_subnet_ids
  security_group_ids            = [module.networking.rds_security_group_id]
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  prefix                        = local.prefix_project
  environment                   = local.environment

  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_storage
  max_allocated_storage   = 100
  backup_retention_period = 7
  skip_final_snapshot     = true # Em produção, definir como false

  tags = var.tags
}

module "valkey" {
  source = "./modules/valkey"

  prefix                = local.prefix_project
  project_name          = var.project_name
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.rds_private_subnet_ids
  eks_security_group_id = module.eks.cluster_security_group_id
  environment           = local.environment

  node_type       = var.valkey_node_type
  num_cache_nodes = var.valkey_num_nodes
  engine_version  = var.valkey_engine_version

  tags = var.tags
}

module "eks_users" {
  source = "./modules/eks-users"

  prefix             = local.prefix_project
  project_name       = var.project_name
  trusted_users_arns = var.trusted_users_arns
  environment        = local.environment

  tags = var.tags
}

module "rds_scheduler" {
  source = "./modules/rds-scheduler"

  prefix                 = local.prefix_project
  project_name           = var.project_name
  db_instance_identifier = module.rds.db_instance_id
  aws_region             = var.region
  environment            = local.environment

  tags = var.tags
}

module "bastion_scheduler" {
  source = "./modules/bastion-scheduler"

  prefix              = local.prefix_project
  project_name        = var.project_name
  bastion_instance_id = module.bastion_host.bastion_instance_id
  aws_region          = var.region
  environment         = local.environment

  tags = var.tags
}

module "bastion_host" {
  source                = "./modules/bastion_host"
  prefix                = local.prefix_project
  project_name          = var.project_name
  bastion_instance_type = var.bastion_instance_type
  key_name              = var.key_name
  tags                  = var.tags
  environment           = local.environment

  vpc_id                = module.networking.vpc_id
  public_subnet_id      = module.networking.public_subnet_ids[0]
  rds_security_group_id = module.networking.rds_security_group_id
}


module "aws_load_balancer_controller" {
  source = "./modules/aws-load-balancer-controller"

  cluster_name      = module.eks.k8s_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  prefix            = local.prefix_project
  environment       = local.environment

  tags = var.tags
}

# Helm release para instalar o AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "${module.eks.k8s_name}-aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = module.eks.k8s_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller.iam_role_arn
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.networking.vpc_id
  }
}

module "container_insights" {
  source = "./modules/container-insights"

  cluster_name      = module.eks.k8s_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  tags = var.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  cluster_name             = module.eks.k8s_name
  node_group_asg_name      = module.eks.node_group_asg_name
  db_instance_identifier   = module.rds.db_instance_id
  sns_topic_arn_for_alarms = var.monitoring_sns_topic_arn
  prefix                   = local.prefix_project

  services_to_monitor = var.monitored_services
}


locals {
  cwagent_config_json_content = jsonencode({
    agent = {
      region = "{{region_name}}"
    },
    metrics = {
      metrics_collected = {
        kubernetes = {
          cluster_name                = "{{cluster_name}}"
          metrics_collection_interval = 60
          container_insights          = true
        }
      },
      append_dimensions = {
        ClusterName = "{{cluster_name}}"
      }
    },
    logs = {
      metrics_collected = {
        kubernetes = {
          cluster_name                = "{{cluster_name}}"
          metrics_collection_interval = 60
        }
      },
      force_flush_interval = 5
    }
  })
}

# CloudWatch Observability Addon (oficial AWS)
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = module.eks.k8s_name
  addon_name   = "amazon-cloudwatch-observability"
  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller
  ]
}

module "ecr" {
  source = "./modules/ecr"

  prefix      = local.prefix_project
  environment = local.environment

  tags = var.tags
}

# Aguardar addon estar pronto
resource "time_sleep" "wait_for_cloudwatch" {
  depends_on      = [aws_eks_addon.cloudwatch_observability]
  create_duration = "60s"
}
