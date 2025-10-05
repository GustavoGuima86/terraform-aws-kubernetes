data "aws_secretsmanager_secret" "secrets" {
  arn = var.db_secret_arn
}

# Helm install of the CSI driver
resource "helm_release" "secrets-store-csi-driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.5.4"
  namespace  = "kube-system"
  timeout    = 10 * 60

  set = [{
    name  = "syncSecret.enabled"
    value = "true"
  },
  {
    name  = "enableSecretRotation"
    value = "true"
  }]
}

# Apply AWS provider manifests
data "kubectl_file_documents" "aws-secrets-manager" {
  content = file("${path.module}/secret_manager/aws-secrets-manager.yaml")
}

resource "kubectl_manifest" "aws-secrets-manager" {
  for_each           = data.kubectl_file_documents.aws-secrets-manager.manifests
  yaml_body          = each.value
  server_side_apply  = true
  force_conflicts    = true
}

# IAM Role for Pod Identity
resource "aws_iam_role" "secrets_csi" {
  name = "secrets-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Condition = {
          StringEquals = {
            "eks:cluster-name": module.eks.cluster_name,
            "aws:SourceAccount": data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "aws:SourceArn": "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"
          }
        }
      }
    ]
  })
}

// IAM Policy for Secrets Manager access
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

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "secrets_csi_attach" {
  policy_arn = aws_iam_policy.secrets_csi.arn
  role       = aws_iam_role.secrets_csi.name
}

# Pod Identity Association
# resource "aws_eks_pod_identity_association" "secrets_csi" {
#   cluster_name    = module.eks.cluster_name
#   namespace       = var.namespace
#   service_account = "csi-secrets-store-provider-aws"  # Updated to match the ServiceAccount in aws-secrets-manager.yaml
#   role_arn        = aws_iam_role.secrets_csi.arn
# }

# Service Account for Secrets CSI
resource "kubectl_manifest" "secrets_csi_sa" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-sci
  namespace: ${var.namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${module.aws_ebs_csi_pod_identity.iam_role_arn}
YAML
  depends_on = [kubectl_manifest.namespace]
  server_side_apply = true
}

# SecretProviderClass definition
resource "kubectl_manifest" "secrets" {
  yaml_body = <<YAML
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


