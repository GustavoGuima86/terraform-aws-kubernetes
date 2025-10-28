resource "helm_release" "agent_operator" {
  name       = "agent-operator"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana-agent-operator"
  version    = "0.5.0"
}

resource "helm_release" "rollout_operator" {
  name       = "rollout-operator"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "rollout-operator"
  version    = "0.19.0"
}