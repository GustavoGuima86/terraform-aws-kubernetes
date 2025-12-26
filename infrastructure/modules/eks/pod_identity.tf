module "aws_ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.5.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
}

module "aws_lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.5.0"

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

}

module "aws_ebs_csi_pod_identity_secret" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.5.0"

  name = "aws-ebs-csi-secret"

  # Additional policy statements
  policy_statements = [
    {
      sid    = "SecretsAccess"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = [data.aws_secretsmanager_secret.secrets.arn]
    }
  ]

  trust_policy_statements = [
    {
      effect = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["pods.eks.amazonaws.com"]
        }
      ]
      actions = ["sts:AssumeRole"]
    }
  ]

  # External secrets configuration
  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = [data.aws_secretsmanager_secret.secrets.arn]
  external_secrets_create_permission    = true
}

data "aws_secretsmanager_secret" "secrets" {
  arn = var.db_secret_arn
}

resource "aws_eks_pod_identity_association" "secrets_csi" {
  cluster_name = var.cluster_name
  service_account = "secret-sci"
  namespace = "kube-system"

  role_arn = module.aws_ebs_csi_pod_identity_secret.iam_role_arn
  depends_on = [module.eks]
}
