resource "kubernetes_role_v1" "teleport_secret_reader" {
  metadata {
    name      = "teleport-secret-reader"
    namespace = kubernetes_namespace_v1.teleport.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "teleport_secret_reader" {
  metadata {
    name      = "teleport-secret-reader-binding"
    namespace = kubernetes_namespace_v1.teleport.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.teleport_secret_reader.metadata[0].name
  }

  subject {
    kind = "User"
    name = "${var.project_id}-plan@${var.project_id}.iam.gserviceaccount.com"
  }
}
