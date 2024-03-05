resource "helm_release" "ebs_csi_driver" {
  name             = "ebs-csi-driver"
  namespace        = var.namespace
  create_namespace = "true"
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  version          = "2.18.0"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_iam_role.arn
  }

  # We have to set the region manually here
  # kube-system workloads are running on Fargate which do no have EC2 Metadata Service (which is used in the default region detection for external-secrets)
  set {
    name  = "controller.region"
    value = var.aws_region
  }
}