resource "aws_iam_role" "ebs_csi_iam_role" {
  name               = local.ebs_csi_iam_role
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    sid     = "TerraformEKSExtSecretIdentity"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_owner_id}:oidc-provider/${local.eks_open_id_connect_provider_url_replaced}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_open_id_connect_provider_url_replaced}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_policy" "ebs_csi_iam_role_policy" {
  name        = "${local.ebs_csi_iam_role}-policy"
  description = "External Secrets IAM Policy"
  policy      = file("${path.module}/policy_document.json")

}

resource "aws_iam_role_policy_attachment" "ebs_csi_iam_role_policy_attachment" {
  policy_arn = aws_iam_policy.ebs_csi_iam_role_policy.arn
  role       = aws_iam_role.ebs_csi_iam_role.name
}