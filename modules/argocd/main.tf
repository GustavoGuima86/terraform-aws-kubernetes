resource "helm_release" "argo" {
  name       = "argo"
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.2"

  values = [
    file("${path.module}/values/values-argocd.yaml")
  ]

  depends_on = [kubectl_manifest.namespace]
}

resource "kubectl_manifest" "argo_Ingress" {
  yaml_body  = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
  finalizers:
  - ingress.k8s.aws/resources
  name: argo
  namespace: ${var.namespace}
spec:
  ingressClassName: alb
  defaultBackend:
    service:
      name: argo-argocd-server
      port:
        number: 80
  YAML
}

resource "helm_release" "argo_apps" {
  name       = "argo-apps"
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "1.6.2"

  values = [
    file("${path.module}/values/values-argocd-apps.yaml")
  ]

  depends_on = [helm_release.argo]
}