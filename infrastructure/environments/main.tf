module "vpc" {
  source = "../modules/vpc"

  vpc_cidr     = var.vpc_cidr
  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}

module "rds" {
  source = "../modules/aws-rds"

  database_configuration = var.database_configurations
  private_subnet_ids   = module.vpc.private_subnets
  public_subnet_ids    = module.vpc.public_subnets
  subnet_private_cidrs = module.vpc.private_subnets_cidr_blocks
  vpc_id               = module.vpc.vpc_id
}

module "eks" {
  source = "../modules/eks"

  eks_version                       = var.eks_version
  private_subnets                   = module.vpc.private_subnets
  intra_subnets                     = module.vpc.intra_subnets
  vpc_id                            = module.vpc.vpc_id
  cluster_name                      = var.cluster_name

  db_secret_arn = module.rds.rds_database_secret_arn
}



# Create AWS resources for observability (S3 buckets, IAM roles)
# Helm charts are deployed by ArgoCD from k8s/ directory
module "observability" {
  source = "../modules/observability"

  cluster_name      = module.eks.cluster_name
  namespace         = var.observability_namespace
  loki_bucket_name  = var.loki_bucket_name
  mimir_bucket_name = var.mimir_bucket_name

  depends_on = [module.eks]
}
