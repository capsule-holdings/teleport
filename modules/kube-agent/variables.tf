variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "env" {
  description = "Environment (stg, prd)"
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
  description = "Teleport Helm chart version"
  type        = string
}

variable "teleport_cluster_name" {
  description = "Teleport cluster name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}
