resource "kubectl_manifest" "namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.namespace}
  annotations:
    istio-injection: enabled
spec:
  finalizers:
  - kubernetes
YAML
}

resource "kubectl_manifest" "serviceaccounts" {
  yaml_body  = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-terraform-module-external-secrets
    meta.helm.sh/release-name: external-secrets
    meta.helm.sh/release-namespace: external-secrets
  labels:
    app.kubernetes.io/instance: external-secrets
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: external-secrets
    app.kubernetes.io/version: v0.8.1
    helm.sh/chart: external-secrets-0.8.1
  name: external-secrets
  namespace: ${var.namespace}
  YAML
  depends_on = [kubectl_manifest.namespace]
}