# Configurações AWS
region     = "us-east-1"
awsProfile = "crfjunior-outlook"

# EKS Configuration
eks_cluster_name          = "cloudfix-cluster"
node_group_instance_types = ["t3.medium"] ###  , "t3.large"]
eks_version               = "1.33"
# Recursos do Cluster
node_group_name         = "cloudfix-nodes"
node_group_desired_size = 2
node_group_max_size     = 4
node_group_min_size     = 2
node_group_disk_size    = 20

# Network Configuration
vpc_cidr = "10.0.0.0/16"
num_azs  = 2
#subnets_public      = local.public_subnets_cidrs
#eks_private_subnets = local.eks_subnets_cidrs
#rds_private_subnets = local.rds_subnets_cidrs

# RDS Configuration
rds_instance_class = "db.t3.micro"
rds_storage        = 50
db_name            = "cloudfix"
db_username        = "cloudfix"
db_password        = "cloudfix_password"

# Monitoring Configuration
monitoring_sns_topic_arn = ""
monitored_services = [
  {
    name          = "cloudfix-app"
    namespace     = "default"
    min_pod_count = 2
    cpu_threshold = 80
    mem_threshold = 80
  }
]

# Tags Configuration
tags = {
  Environment = "homologation"
  Projeto     = "cloudfix"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
}

# Deploy de teste (nginx) - Em produção: false
deploy_test_app = true

# Valkey Configuration
valkey_engine_version = "8.0"
valkey_num_nodes      = 1

project_name = "cloudfix"
prefix       = "cloudfix"
environment  = "hml"
