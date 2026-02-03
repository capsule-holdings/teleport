locals {
  services = [
    "servicenetworking.googleapis.com",
    "container.googleapis.com",
    "secretmanager.googleapis.com",
    "dns.googleapis.com",
  ]
}

resource "google_project_service" "this" {
  for_each = toset(local.services)

  service            = each.value
  disable_on_destroy = false
}

# Infra Module - GCP Infrastructure (Network, GKE, IAM)
module "infra" {
  source = "./modules/gke"

  project_id   = var.project_id
  region       = var.region
  vpc_name     = var.vpc_name
  subnet_name  = var.subnet_name
  router_name  = var.router_name
  nat_ip_count = var.nat_ip_count

  depends_on = [google_project_service.this]
}

# Helm Module - Kubernetes/Helm Resources (Namespace, Cert-Manager, Teleport, DNS)
module "helm" {
  source = "./modules/helm"

  project_id                   = var.project_id
  domain_name                  = var.domain_name
  letsencrypt_email            = var.letsencrypt_email
  teleport_service_account_key = module.infra.teleport_service_account_key
  teleport_version             = var.teleport_version
}

# Teleport Module - Teleport Provider Resources (Roles, Tokens, GitHub SSO)
module "teleport" {
  source = "./modules/teleport"

  domain_name                   = var.domain_name
  github_client_id              = var.github_client_id
  github_client_secret_name     = "teleport-github-oauth-app-client-secret"
  github_organization           = var.github_organization
  teleport_identity_secret_name = "teleport-terraform"
}

# DNS Module - Cloud DNS
module "dns" {
  source  = "terraform-google-modules/cloud-dns/google"
  version = "7.1.0"

  project_id = var.project_id
  type       = "public"
  name       = replace(var.domain_name, ".", "-")
  domain     = "${var.domain_name}."

  recordsets = [
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = [module.helm.teleport_service_ip]
    },
    {
      name    = "*"
      type    = "A"
      ttl     = 300
      records = [module.helm.teleport_service_ip]
    }
  ]
}
