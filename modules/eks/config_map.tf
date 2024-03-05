resource "kubernetes_config_map" "application_config" {
  metadata {
    name      = "application-config"
    namespace = var.namespace
  }
  data = {
    db-url = "jdbc:postgresql://${var.db_url}:${var.db_port}/postgres"
  }
  depends_on = [kubectl_manifest.namespace]
}