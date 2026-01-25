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
    namespace       = local.aws_lb_controller_sa_namespace
    service_account = local.aws_lb_controller_sa_name
  }

  associations = {
    controller = {
      service_account = local.aws_lb_controller_sa_name
      namespace       = local.aws_lb_controller_sa_namespace
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
  cluster_name    = var.cluster_name
  service_account = local.secrets_csi_driver_sa_name
  namespace       = local.secrets_csi_driver_sa_namespace

  role_arn   = module.aws_ebs_csi_pod_identity_secret.iam_role_arn
  depends_on = [module.eks]
}

# Data source to get the Route53 hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# IAM policy for external-dns
data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.main.zone_id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]
    resources = ["*"]
  }
}

# IAM policy
resource "aws_iam_policy" "external_dns" {
  name        = "${var.cluster_name}-external-dns-policy"
  description = "Policy for external-dns to manage Route53 records"
  policy      = data.aws_iam_policy_document.external_dns.json
}

# EKS Pod Identity for external-dns
module "external_dns_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.5"

  name = "${var.cluster_name}-external-dns"

  additional_policy_arns = {
    external_dns = aws_iam_policy.external_dns.arn
  }

  associations = {
    external_dns = {
      cluster_name    = var.cluster_name
      namespace       = local.external_dns_sa_namespace
      service_account = local.external_dns_sa_name
    }
  }

}

# ==============================================================================
# Falco Runtime Security Pod Identity
# ==============================================================================

# IAM policy for Falco (CloudWatch Logs, SNS, SQS)
data "aws_iam_policy_document" "falco" {
  # CloudWatch Logs permissions
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}/falco*"
    ]
  }

  # SNS permissions (optional, for alerts)
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:falco-*"
    ]
  }

  # SQS permissions (optional, for event queuing)
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ]
    resources = [
      "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:falco-*"
    ]
  }
}

# IAM policy
resource "aws_iam_policy" "falco" {
  name        = "${var.cluster_name}-falco-policy"
  description = "Policy for Falco to send events to CloudWatch, SNS, and SQS"
  policy      = data.aws_iam_policy_document.falco.json
}

# EKS Pod Identity for Falco
module "falco_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.5"

  name = "${var.cluster_name}-falco"

  additional_policy_arns = {
    falco = aws_iam_policy.falco.arn
  }

  associations = {
    falco = {
      cluster_name    = var.cluster_name
      namespace       = local.falco_sa_namespace
      service_account = local.falco_sa_name
    }
  }

}