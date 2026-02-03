variable "domain_name" {
  description = "Domain name for Teleport"
  type        = string
}

variable "github_client_id" {
  description = "GitHub OAuth App Client ID"
  type        = string
}

variable "github_client_secret_name" {
  description = "Secret Manager secret name for GitHub OAuth App Client Secret"
  type        = string
}

variable "github_organization" {
  description = "GitHub organization name"
  type        = string
}

variable "teleport_identity_secret_name" {
  description = "Secret Manager secret name for Teleport identity file"
  type        = string
}
