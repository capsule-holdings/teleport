variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "env" {
  description = "Environment name (prd, stg)"
  type        = string
}

variable "gke_cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "teleport_proxy_addr" {
  description = "Teleport proxy address"
  type        = string
}

variable "teleport_version" {
  description = "Teleport version"
  type        = string
}

variable "teleport_cluster_name" {
  description = "Teleport cluster name for OIDC joining"
  type        = string
}
