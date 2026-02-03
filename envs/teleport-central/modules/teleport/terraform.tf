terraform {
  required_providers {
    teleport = {
      source  = "terraform.releases.teleport.dev/gravitational/teleport"
      version = "18.6.4"
    }
  }
}

provider "teleport" {
  addr                 = "${var.domain_name}:443"
  identity_file_base64 = base64encode(data.google_secret_manager_secret_version.teleport_terraform.secret_data)
}
