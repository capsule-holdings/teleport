variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "router_name" {
  description = "Router name"
  type        = string
}

variable "nat_ip_count" {
  description = "Number of NAT IPs to create"
  type        = number
  default     = 1
}

variable "domain_name" {
  description = "Domain name for Teleport"
  type        = string
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "github_client_id" {
  description = "GitHub OAuth App Client ID"
  type        = string
}

variable "github_organization" {
  description = "GitHub organization name"
  type        = string
}

variable "teleport_version" {
  description = "Teleport Helm chart version"
  type        = string
}
