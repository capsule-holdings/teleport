locals {
  agent_name = "teleport-kube-agent"
}

resource "helm_release" "this" {
  name       = local.agent_name
  repository = "https://charts.releases.teleport.dev"
  chart      = "teleport-kube-agent"
  namespace  = var.namespace
  version    = var.teleport_version

  values = [yamlencode({
    roles               = "kube"
    proxyAddr           = var.teleport_proxy_addr
    teleportClusterName = var.teleport_cluster_name
    kubeClusterName     = "${var.project_id}-${var.gke_cluster_name}"

    joinParams = {
      method    = "kubernetes"
      tokenName = "kube-agent-${var.project_id}"
    }

    joinTokenSecret = {
      name   = "${local.agent_name}-join-token"
      create = true
    }

    labels = {
      "env" = var.env
    }
  })]

  timeout = 300
}
