data "google_secret_manager_secret_version" "github_client_secret" {
  secret  = var.github_client_secret_name
  version = "latest"
}

data "google_secret_manager_secret_version" "teleport_terraform" {
  secret  = var.teleport_identity_secret_name
  version = "latest"
}
