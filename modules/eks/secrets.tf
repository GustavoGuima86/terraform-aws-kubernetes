data "aws_secretsmanager_secret" "secrets" {
  arn = var.db_secret_arn
}

locals {
  eks_open_id_connect_provider_url_replaced = replace(module.eks.oidc_provider, "https://", "")
  irsa_oidc_provider_url                    = replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")
}

resource "helm_release" "secrets-store-csi-driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.3.4"
  namespace  = "kube-system"
  timeout    = 10 * 60

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
  set {
    name  = "enableSecretRotation"
    value = "true"
  }

}

data "kubectl_file_documents" "aws-secrets-manager" {
  content = file("${path.module}/secret_manager/aws-secrets-manager.yaml")
}
# https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

resource "kubectl_manifest" "aws-secrets-manager" {
  for_each  = data.kubectl_file_documents.aws-secrets-manager.manifests
  yaml_body = each.value
}

# Trusted entities
data "aws_iam_policy_document" "secrets_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

# Role
resource "aws_iam_role" "secrets_csi" {
  assume_role_policy = data.aws_iam_policy_document.secrets_csi_assume_role_policy.json
  name               = "secrets-csi-role"
}

# Policy
resource "aws_iam_policy" "secrets_csi" {
  name = "secrets-csi-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      Resource = [data.aws_secretsmanager_secret.secrets.arn]
    }]
  })
}


# Policy Attachment
resource "aws_iam_role_policy_attachment" "secrets_csi" {
  policy_arn = aws_iam_policy.secrets_csi.arn
  role       = aws_iam_role.secrets_csi.name
}

# Service Account
resource "kubectl_manifest" "secrets_csi_sa" {
  yaml_body  = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-sci
  namespace: ${var.namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.secrets_csi.arn}
YAML
  depends_on = [kubectl_manifest.namespace]
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
