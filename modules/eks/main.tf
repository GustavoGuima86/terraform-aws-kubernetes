################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.3.1"

  name                   = var.cluster_name
  kubernetes_version                = var.eks_version
  endpoint_public_access = true

  kms_key_owners                 = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
    aws-ebs-csi-driver = {}
    metrics-server = {
      most_recent = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets

  # Fargate profiles use the cluster primary security group so these are not utilized
  # create_node_security_group    = true
  access_entries = {
    super-admin = {
      principal_arn = local.SSO_AdministratorAccess_role

      policy_associations = {
        cluster-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    managed_node = {
      ami_type       = "AL2023_x86_64_STANDARD" # validate possible dynamically AIM assignment
      instance_types = ["t2.medium"]

      min_size = 1
      max_size = 3
      desired_size = 1

      subnet_ids =  var.private_subnets // module.vpc.private_subnets

      iam_role_additional_policies = {
        sqs_policy = aws_iam_policy.karpenter_policy.arn
      }

      labels = {
        "karpenter.sh/controller" = "true"
      }
    }
  }
  iam_role_additional_policies = {
    volume_policy = aws_iam_policy.extra_policies_cluster.arn
  }
  enable_cluster_creator_admin_permissions = false

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_iam_policy" "extra_policies_cluster" {
  name   = "extra_policies_cluster"
  policy = data.aws_iam_policy_document.extra-policy.json
}

data "aws_iam_policy_document" "extra-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:CreateTags",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]
    resources = ["*"]
  }
}


# # Todo: aws_iam_service_linked_role can only be destroyed after all EKS resources have been destroyed
# resource "aws_iam_service_linked_role" "spot" {
#   aws_service_name = "spot.amazonaws.com"
# }
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


# module "eks_blueprints_kubernetes_addons" {
#
#   source = "aws-ia/eks-blueprints-addons/aws"
#
#   cluster_name      = var.cluster_name
#   cluster_endpoint  = module.eks.cluster_endpoint
#   oidc_provider_arn = module.eks.oidc_provider_arn
#   cluster_version   = module.eks.cluster_version
#
#   # EKS Managed Add-ons
#   eks_addons = {}
#
#   # Add-ons
#   enable_metrics_server     = true
#   enable_cluster_autoscaler = false
#
#   #### AWS ALB CONTROLLER
#   # Enable AWS ALB Controller
#   enable_aws_load_balancer_controller = var.enable_aws_alb_controller_rollout
#
#   aws_load_balancer_controller = {
#     values = ["vpcID: ${var.vpc_id}"]
#   }
#
#   depends_on = [
#     helm_release.karpenter
#
#   ]
# }

# # Allow AWS ALB Controller access to Control Plane
#
# resource "aws_security_group_rule" "ingress_allow_access_from_control_plane" {
#
#   security_group_id = module.eks.cluster_primary_security_group_id
#   type              = "ingress"
#   protocol          = "tcp"
#   from_port         = 8080
#   to_port           = 8080
#   cidr_blocks       = [var.vpc_cidr]
#   description       = "Allow access from control plane to webhook port of AWS load balancer controller"
# }

module "argocd" {
  source = "../argocd"

  domain_name = var.domain_name
  namespace   = "argocd"
}
