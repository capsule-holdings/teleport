resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.19.2"
  namespace        = kubernetes_namespace_v1.cert_manager.metadata[0].name
  create_namespace = false

  set = [
    {
      name  = "global.leaderElection.namespace"
      value = "cert-manager"
    },
    {
      name  = "installCRDs"
      value = "true"
    }
  ]
}

resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "letsencrypt-production"
      namespace = kubernetes_namespace_v1.teleport.metadata[0].name
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-production"
        }
        solvers = [
          {
            selector = {
              dnsZones = [var.domain_name]
            }
            dns01 = {
              cloudDNS = {
                project = var.project_id
                serviceAccountSecretRef = {
                  name = kubernetes_secret_v1.teleport_gcp_credentials.metadata[0].name
                  key  = "gcp-credentials.json"
                }
              }
            }
          }
        ]
      }
    }
  }
}
