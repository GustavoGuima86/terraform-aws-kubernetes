module "aws_lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0.0"

  name = "aws-lbc"

  attach_aws_lb_controller_policy = true

  association_defaults = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
  }

  associations = {
    controller = {
      service_account = "aws-load-balancer-controller"
      namespace       = "kube-system"
      cluster_name    = module.eks.cluster_name
    }
  }

  depends_on = [module.karpenter]
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.4"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "region"
      value = data.aws_region.current.name
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "podIdentityAssociation.enabled"
      value = "true"
    },
    {
      name  = "enableCertManager"
      value = "false"
    },
    {
      name  = "createIngressClassResource"
      value = "true"
    },
    {
      name  = "ingressClass"
      value = "alb"
    },
    {
      name  = "podIdentityAssociation.enabled"
      value = "true"
    }
  ]

  depends_on = [module.aws_lb_controller_pod_identity, module.karpenter]
}