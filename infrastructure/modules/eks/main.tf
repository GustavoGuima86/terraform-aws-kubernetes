################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.10.1"

  name                   = var.cluster_name
  kubernetes_version     = var.eks_version
  endpoint_public_access = true

  kms_key_owners = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  addons = {
    coredns = {
      most_recent    = true
      resolve_conflicts = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      resolve_conflicts = "OVERWRITE"
    }
    metrics-server = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      pod_identity_association = [
        {
          service_account = "ebs-csi-controller-sa"
          role_arn        = module.aws_ebs_csi_pod_identity.iam_role_arn
        }
      ]
      aws-secrets-store-csi-driver-provider = {
        most_recent = true
      }
    }
  }

    vpc_id     = var.vpc_id
    subnet_ids = var.private_subnets
    control_plane_subnet_ids = var.intra_subnets

    # not possible to simulate a proper env for now
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
        ami_type = "BOTTLEROCKET_ARM_64"
        instance_types = ["t4g.large"]

        min_size     = 3
        max_size     = 5
        desired_size = 3

        subnet_ids = var.private_subnets

        attach_cluster_primary_security_group = true

        iam_role_additional_policies = {
          AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        }

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
}

################################################################################
# Velero Backup S3 Bucket
################################################################################

resource "aws_s3_bucket" "velero_backups" {
  bucket = "${var.cluster_name}-velero-backups"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-velero-backups"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}