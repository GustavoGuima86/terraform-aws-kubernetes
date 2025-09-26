# Prepare EIP for NAT gateway
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}
data "aws_availability_zones" "available" {}


resource "aws_eip" "eks_natgw_eip" {}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  name    = var.vpc_name
  cidr    = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 52)]

  enable_dns_hostnames = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Reuse EIP for NAT
  reuse_nat_ips       = true
  external_nat_ip_ids = [aws_eip.eks_natgw_eip.id]
  external_nat_ips    = [aws_eip.eks_natgw_eip.public_ip]

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery"         = var.cluster_name
  }
}