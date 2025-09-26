# Retrieve the EKS cluster details
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks, module.ebs_csi]
}

data "aws_iam_roles" "SSO_AdministratorAccess_role" {
  name_regex = "AWSReservedSSO_AWSAdministratorAccess.*"
}

data "aws_caller_identity" "current" {}