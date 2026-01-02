module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.10.1"

  cluster_name                    = module.eks.cluster_name
  create_pod_identity_association = true
  create_access_entry             = false

  depends_on = [module.eks]
}

# Pod Identity Association for Karpenter Controller
resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = module.eks.cluster_name
  namespace       = var.karpenter_namespace
  service_account = "karpenter"
  role_arn        = module.karpenter.iam_role_arn

  depends_on = [module.karpenter]
}



