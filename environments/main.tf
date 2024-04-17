
module "ecr" {
  source = "../modules/ecr_repo"

  service_name          = var.service_name
  expiration_after_days = 10
  depends_on = [module.vpc]
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
  depends_on = [module.vpc]
}

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
