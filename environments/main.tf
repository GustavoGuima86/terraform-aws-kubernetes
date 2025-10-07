module "ecr" {
  source = "../modules/ecr_repo"

  service_name          = var.service_name
  expiration_after_days = 10
}


module "vpc" {
  source = "../modules/vpc"

  vpc_cidr     = var.vpc_cidr
  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}

module "rds" {
  source = "../modules/aws-rds"

  database_configuration = var.database_configurations

  providers = {
    aws.this = aws
  }
  private_subnet_ids   = module.vpc.private_subnets
  public_subnet_ids    = module.vpc.public_subnets
  subnet_private_cidrs = module.vpc.private_subnets_cidr_blocks
  vpc_id               = module.vpc.vpc_id
}

# resource "random_string" "secret_suffix" {
#   length  = 8
#   special = false
#   upper   = false
# }
#
# resource "aws_secretsmanager_secret" "example" {
#   name        = "my-secret-${random_string.secret_suffix.result}"
#   description = "Example secret managed by Terraform"
#
#   force_overwrite_replica_secret = true
# }

# ---------------------------------------------------------
# Store a Secret Value
# ---------------------------------------------------------
# resource "aws_secretsmanager_secret_version" "example" {
#   secret_id     = aws_secretsmanager_secret.example.id
#   secret_string = jsonencode({
#     username = "admin"
#     password = "SuperSecurePassword123!"
#   })
# }

module "eks" {
  source = "../modules/eks"

  enable_eks_karpenter_rollout      = var.enable_eks_karpenter_rollout
  eks_version                       = var.eks_version
  private_subnets                   = module.vpc.private_subnets
  intra_subnets                     = module.vpc.intra_subnets
  vpc_id                            = module.vpc.vpc_id
  namespace                         = var.namespaces
  namespace_labeling                = var.namespace_labeling
  vpc_cidr                          = var.vpc_cidr
  enable_aws_alb_controller_rollout = var.enable_aws_alb_controller_rollout
  targetRegion                      = var.targetRegion
  cluster_name                      = var.cluster_name
  auth_role_sso                     = var.auth_role_sso

  db_secret_arn = module.rds.rds_database_secret_arn

  db_port = module.rds.rds_database_port
  db_url  = module.rds.rds_database_url
}

# module "ebs-csi-driver" {
#   source = "../modules/ebs-csi-driver"
#   cluster_name                       = module.eks.cluster_name                       # Required by providers provider
#   cluster_endpoint                   = module.eks.cluster_endpoint                   # Required by providers provider
#   cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data # Required by providers
# }
#
module "observability" {
  source                             = "../modules/observability"
  namespace                          = var.observability_namespace
  loki_bucket_name                   = var.loki_bucket_name
  mimir_bucket_name                  = var.mimir_bucket_name
  oidc_id                            = module.eks.oidc_id                            # Required by Roles to access S3 from EKS using RBAC / Service account
  cluster_name                       = module.eks.cluster_name                       # Required by providers provider
  cluster_endpoint                   = module.eks.cluster_endpoint                   # Required by providers provider
  eks_oidc_provider_arn              = module.eks.eks_oidc_provider_arn              # Required by Roles to access S3 from EKS using RBAC / Service account
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data # Required by providers
}

module "argocd" {
  source                             = "../modules/argocd"
  namespace                          = var.namespaces
  cluster_name                       = module.eks.cluster_name                       # Required by providers provider
  cluster_endpoint                   = module.eks.cluster_endpoint                   # Required by providers provider
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data # Required by providers
}