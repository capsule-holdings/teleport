resource "kubernetes_namespace_v1" "teleport" {
  metadata {
    name = "teleport"

    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}
