resource "kubernetes_namespace_v1" "teleport" {
  metadata {
    name = "teleport"
  }
}

resource "kubernetes_cluster_role_binding_v1" "teleport_admins" {
  metadata {
    name = "teleport-admins"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "Group"
    name      = "teleport-admins"
    api_group = "rbac.authorization.k8s.io"
  }
}

module "kube_agent" {
  source = "../../modules/kube-agent"

  project_id            = var.project_id
  env                   = var.env
  gke_cluster_name      = var.gke_cluster_name
  teleport_proxy_addr   = var.teleport_proxy_addr
  teleport_version      = var.teleport_version
  teleport_cluster_name = var.teleport_cluster_name
  namespace             = kubernetes_namespace_v1.teleport.metadata[0].name
}
