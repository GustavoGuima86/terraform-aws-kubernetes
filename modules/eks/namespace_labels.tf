resource "kubernetes_labels" "namespacelabel_default" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = var.namespace_labeling
  }
  labels = {
    "istio-injection" = "enabled"
  }
  depends_on = [kubectl_manifest.namespace]
}