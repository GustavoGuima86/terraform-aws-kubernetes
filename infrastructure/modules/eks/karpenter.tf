module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.10.1"

  cluster_name                    = module.eks.cluster_name
  create_pod_identity_association = true
  create_access_entry             = false

  depends_on = [module.eks]
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = module.eks.cluster_name
  namespace       = var.karpenter_namespace
  service_account = "karpenter"
  role_arn        = module.karpenter.iam_role_arn

  depends_on = [module.karpenter]
}

resource "aws_iam_policy" "karpenter_describe_policy" {
  name_prefix = "karpenter-describe-policy-"
  policy      = data.aws_iam_policy_document.karpenter_describe_policy.json
  description = "Grants additional describe permissions for Karpenter"
}

data "aws_iam_policy_document" "karpenter_describe_policy" {
  statement {
    sid    = "ExplicitDescribe"
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_describe_policy_attachment" {
  role       = module.karpenter.iam_role_name
  policy_arn = aws_iam_policy.karpenter_describe_policy.arn
}