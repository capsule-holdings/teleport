locals {
  kube_agent_clusters = {
    project-b-prod       = "https://container.googleapis.com/v1/projects/project-b-prod/locations/asia-northeast1/clusters/default"
    project-b-staging       = "https://container.googleapis.com/v1/projects/project-b-staging/locations/asia-northeast1/clusters/default"
    project-a-prod   = "https://container.googleapis.com/v1/projects/project-a-prod/locations/asia-northeast1/clusters/prod-standard"
    project-a-staging = "https://container.googleapis.com/v1/projects/project-a-staging/locations/asia-northeast1/clusters/staging"
  }

  teleport_provision_tokens = {
    for cluster, issuer in local.kube_agent_clusters :
    "kube-${cluster}" => {
      name            = "kube-agent-${cluster}"
      roles           = ["Kube"]
      issuer          = issuer
      service_account = "teleport:teleport-kube-agent"
    }
  }
}

resource "teleport_provision_token" "agent" {
  for_each = local.teleport_provision_tokens

  version = "v2"

  metadata = {
    name = each.value.name
  }

  spec = {
    roles       = each.value.roles
    join_method = "kubernetes"

    kubernetes = {
      type = "oidc"
      oidc = {
        issuer = each.value.issuer
      }
      allow = [
        {
          service_account = each.value.service_account
        }
      ]
    }
  }
}
