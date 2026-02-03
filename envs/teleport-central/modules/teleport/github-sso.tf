resource "teleport_github_connector" "github" {
  version = "v3"
  metadata = {
    name = "github"
  }
  spec = {
    client_id     = var.github_client_id
    client_secret = data.google_secret_manager_secret_version.github_client_secret.secret_data
    redirect_url  = "https://${var.domain_name}/v1/webapi/github/callback"
    display       = "GitHub"
    teams_to_roles = [
      {
        organization = var.github_organization
        team         = "root"
        roles        = ["root"]
      },
      {
        organization = var.github_organization
        team         = "admin"
        roles        = ["prd", "stg"]
      },
      {
        organization = var.github_organization
        team         = "standard"
        roles        = ["request_prd", "stg"]
      },
      {
        organization = var.github_organization
        team         = "lite"
        roles        = ["stg"]
      },
    ]
  }
}
