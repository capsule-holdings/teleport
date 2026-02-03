variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "domain_name" {
  description = "Domain name for Teleport"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "teleport_service_account_key" {
  description = "Teleport service account key JSON"
  type        = string
  sensitive   = true
}

variable "teleport_version" {
  description = "Teleport Helm chart version"
  type        = string
}
