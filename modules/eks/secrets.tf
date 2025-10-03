data "aws_secretsmanager_secret" "secrets" {
  arn = var.db_secret_arn
}
module "external_secrets_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0.0"

  name = "external-secrets"

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = [data.aws_secretsmanager_secret.secrets.arn]
  external_secrets_create_permission    = true

  association_defaults = {
    namespace       = "external-secrets"
    service_account = "external-secrets-sa"
  }

  associations = {
    ex-one = {
      cluster_name = module.eks.cluster_name
    }
  }
}

resource "helm_release" "secrets-store-csi-driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.5.4"
  namespace  = "kube-system"
  timeout    = 10 * 60

  set = [
    {
      name  = "syncSecret.enabled"
      value = "true"
    },
    {
      name  = "enableSecretRotation"
      value = "true"
    },
    {
      name  = "providers.aws.enabled"
      value = "true"
    }
  ]

  depends_on = [module.eks]

}

# resource "helm_release" "secrets-store-csi-driver-provider-aws" {
#   name       = "secrets-store-csi-driver-provider-aws"
#   repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
#   chart      = "secrets-store-csi-driver-provider-aws"
#   namespace  = "kube-system"
#   # version    = "2.1.1"
#
#   depends_on = [helm_release.secrets-store-csi-driver]
# }

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
