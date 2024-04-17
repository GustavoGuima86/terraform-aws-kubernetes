resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = var.istio_namespace
  }
  depends_on = [module.eks]
}

resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = var.istio_namespace
  version    = var.istio_version

  values = [
    file("${path.module}/values/values-istio.yaml")
  ]

  depends_on = [kubectl_manifest.namespace, kubernetes_namespace.istio_system, helm_release.kube_prometheus]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = var.istio_namespace
  version    = var.istio_version
  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = var.istio_namespace
  version    = var.istio_version
  depends_on = [helm_release.istiod]
}

resource "helm_release" "kiali" {
  name       = "kiali"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-server"
  namespace  = var.namespace
  depends_on = [helm_release.istio_ingress, kubernetes_namespace.istio_system]
  values = [
    file("${path.module}/values/values-kiali.yaml")
  ]
}

resource "kubectl_manifest" "Istio_Ingress" {
  yaml_body  = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /kiali
    alb.ingress.kubernetes.io/success-codes: "200,302"
  finalizers:
  - ingress.k8s.aws/resources
  name: kieli
  namespace: ${var.namespace}
spec:
  ingressClassName: alb
  defaultBackend:
    service:
      name: kiali
      port:
        number: 20001
  YAML
  depends_on = [helm_release.istio_ingress]
}
