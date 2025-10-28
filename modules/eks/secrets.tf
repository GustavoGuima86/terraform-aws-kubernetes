data "aws_secretsmanager_secret" "secrets" {
  arn = var.db_secret_arn
}

resource "helm_release" "secrets-store-csi-driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.3.4"
  namespace  = "kube-system"
  timeout    = 10 * 60

  set = [{
    name  = "syncSecret.enabled"
    value = "true"
    }, {
    name  = "enableSecretRotation"
    value = "true"
    }]
}

resource "helm_release" "secrets-store-csi-driver-provider-aws" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "2.1.1"

  set = [
    {
      name  = "secrets-store-csi-driver.install"
      value = false
    },
    {
      name  = "serviceAccount.create"
      value = false
    }, {
      name  = "podIdentity.enabled"
      value = true
    }
  ]

  depends_on = [helm_release.secrets-store-csi-driver]
}

resource "kubectl_manifest" "secrets" {
  yaml_body  = <<YAML
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: secret-scp
  namespace: ${var.namespace}
spec:
  provider: aws
  parameters:
    usePodIdentity: "true"
    objects: |
        - objectName: ${data.aws_secretsmanager_secret.secrets.arn}
          objectType: "secretsmanager"
          jmesPath:
            - path: username
              objectAlias: username
            - path: password
              objectAlias: password
  secretObjects:
    - secretName: db-secret
      type: Opaque
      data:
        - objectName: username
          key: username
        - objectName: password
          key: password
YAML
  depends_on = [kubectl_manifest.namespace]
}

# Service Account with Pod Identity annotation
resource "kubectl_manifest" "secrets_csi_sa" {
  yaml_body  = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-sci
  namespace: ${var.namespace}
  # annotations:
  #   eks.amazonaws.com/role-arn: ${module.aws_ebs_csi_pod_identity_secret.iam_role_arn}
YAML
  depends_on = [kubectl_manifest.namespace]
}

module "aws_ebs_csi_pod_identity_secret" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0.0"

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

resource "aws_eks_pod_identity_association" "secrets_csi" {
  cluster_name = var.cluster_name
  namespace       = var.namespace
  service_account = "secret-sci"

  role_arn = module.aws_ebs_csi_pod_identity_secret.iam_role_arn

  depends_on = [module.eks]
}
