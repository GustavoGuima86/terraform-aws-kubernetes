data "aws_caller_identity" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.20.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.eks_version
  cluster_endpoint_public_access = true
  kms_key_owners                 = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns    = {}
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false
  manage_aws_auth_configmap     = true
  # create_aws_auth_configmap = true
  aws_auth_roles = [
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = "${var.auth_role_sso}"
      username = "AWSAdministratorAccess:{{SessionName}}"
      groups = [
        "system:masters"
      ]
    }
  ]
  aws_auth_accounts = [
    "${data.aws_caller_identity.current.account_id}",
  ]

  eks_managed_node_groups = {
    k8s = {
      instance_types = [
        "t3.medium"
      ]

      min_size     = 1
      max_size     = 2
      desired_size = 2

    }
  }
}


# Todo: aws_iam_service_linked_role can only be destroyed after all EKS resources have been destroyed
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}
module "ebs_csi" {

  source = "../ebs-csi-driver"

  cluster_name                     = var.cluster_name
  eks_open_id_connect_provider_url = module.eks.oidc_provider
  account_owner_id                 = data.aws_caller_identity.current.account_id
  aws_region                       = var.targetRegion

  #depends_on = [helm_release.karpenter]
}

################################################################################
# aws alb controller
################################################################################


module "eks_blueprints_kubernetes_addons" {

  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = var.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_version   = module.eks.cluster_version

  # EKS Managed Add-ons
  eks_addons = {}

  # Add-ons
  enable_metrics_server     = true
  enable_cluster_autoscaler = false

  #### AWS ALB CONTROLLER
  # Enable AWS ALB Controller
  enable_aws_load_balancer_controller = var.enable_aws_alb_controller_rollout

  aws_load_balancer_controller = {
    values = ["vpcID: ${var.vpc_id}"]
  }

  depends_on = [
    helm_release.karpenter

  ]
}

# Allow AWS ALB Controller access to Control Plane

resource "aws_security_group_rule" "ingress_allow_access_from_control_plane" {

  security_group_id = module.eks.cluster_primary_security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow access from control plane to webhook port of AWS load balancer controller"
}
