resource "kubectl_manifest" "namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.namespace}
spec:
  finalizers:
  - kubernetes
YAML
}

resource "helm_release" "kube_prometheus" {
  name             = local.kube_prometheus
  namespace        = var.namespace
  create_namespace = "true"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "56.21.1"

  values     = [local.values_grafana]
  depends_on = [helm_release.loki]
}

resource "kubectl_manifest" "grafana_ingress" {
  yaml_body  = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /api/health
  finalizers:
  - ingress.k8s.aws/resources
  name: grafana
  namespace: ${var.namespace}
spec:
  ingressClassName: alb
  defaultBackend:
    service:
      name: kube-prometheus-grafana
      port:
        number: 80
  YAML
  depends_on = [helm_release.kube_prometheus]
}

resource "random_password" "password_grafana" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]<>:?"
}
resource "aws_ssm_parameter" "password_grafana" {
  name  = "Password_Grafana"
  type  = "String"
  value = random_password.password_grafana.result
}



