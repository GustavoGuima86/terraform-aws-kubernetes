################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.3.1"

  name                   = var.cluster_name
  kubernetes_version     = var.eks_version
  endpoint_public_access = true

  kms_key_owners = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  # Enable IRSA
  enable_irsa = true

  addons = {
    coredns = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    metrics-server = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      pod_identity_association = [{
        service_account = "ebs-csi-controller-sa"
        role_arn = module.aws_ebs_csi_pod_identity.iam_role_arn
      }]
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
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 1

      subnet_ids = var.private_subnets

      # Ensure proper taints and labels
      labels = {
        "karpenter.sh/controller" = "true"
      }
    }
  }
  enable_cluster_creator_admin_permissions = false

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}




