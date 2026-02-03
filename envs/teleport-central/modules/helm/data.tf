data "kubernetes_service_v1" "teleport" {
  metadata {
    name      = "teleport"
    namespace = kubernetes_namespace_v1.teleport.metadata[0].name
  }

  depends_on = [helm_release.teleport_cluster]
}
