locals {
  name                                         = "ex-${basename(path.cwd)}"
  SSO_AdministratorAccess_role                 = tolist(data.aws_iam_roles.SSO_AdministratorAccess_role.arns)[0]
  oidc_url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_id  = regex("id/([A-Fa-f0-9-]+)$", local.oidc_url)[0]
}