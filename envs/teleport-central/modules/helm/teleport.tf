resource "helm_release" "teleport_cluster" {
  name       = "teleport"
  repository = "https://charts.releases.teleport.dev"
  chart      = "teleport-cluster"
  version    = var.teleport_version
  namespace  = kubernetes_namespace_v1.teleport.metadata[0].name

  values = [yamlencode({
    chartMode   = "gcp"
    clusterName = var.domain_name

    image = "public.ecr.aws/gravitational/teleport-distroless-debug"

    gcp = {
      projectId              = var.project_id
      backendTable           = "teleport-helm-backend"
      auditLogTable          = "teleport-helm-events"
      auditLogMirrorOnStdout = false
      sessionRecordingBucket = "teleport-helm-sessions"
    }

    highAvailability = {
      replicaCount = 2
      certManager = {
        enabled    = true
        issuerName = "letsencrypt-production"
      }
    }

    podSecurityPolicy = {
      enabled = false
    }
  })]
}
