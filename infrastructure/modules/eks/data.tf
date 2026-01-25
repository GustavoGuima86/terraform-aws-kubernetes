# Retrieve the EKS cluster details
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_iam_roles" "SSO_AdministratorAccess_role" {
  name_regex = "AWSReservedSSO_AWSAdministratorAccess.*"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ==============================================================================
# Service Account Configuration
# Centralized definitions for all K8s service accounts used with EKS Pod Identity
# ==============================================================================

locals {
  # AWS Load Balancer Controller
  aws_lb_controller_sa_name      = "aws-load-balancer-controller"
  aws_lb_controller_sa_namespace = "kube-system"

  # Karpenter
  karpenter_sa_name      = "karpenter"
  karpenter_sa_namespace = "karpenter"

  # External DNS
  external_dns_sa_name      = "external-dns"
  external_dns_sa_namespace = "external-dns"

  # Velero
  velero_sa_name      = "velero-sa"
  velero_sa_namespace = "velero"

  # Falco Runtime Security
  falco_sa_name      = "falco"
  falco_sa_namespace = "falco"

  # EBS CSI Controller
  ebs_csi_controller_sa_name      = "ebs-csi-controller-sa"
  ebs_csi_controller_sa_namespace = "kube-system"

  # Secrets Store CSI Driver
  secrets_csi_driver_sa_name      = "secret-sci"
  secrets_csi_driver_sa_namespace = "kube-system"
}
