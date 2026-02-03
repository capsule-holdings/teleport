resource "kubernetes_secret_v1" "teleport_gcp_credentials" {
  metadata {
    name      = "teleport-gcp-credentials"
    namespace = kubernetes_namespace_v1.teleport.metadata[0].name
  }

  data = {
    "gcp-credentials.json" = var.teleport_service_account_key
  }
}
