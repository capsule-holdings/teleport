output "cluster_endpoint" {
  description = "GKE cluster public endpoint"
  value       = data.google_container_cluster.default.private_cluster_config[0].public_endpoint
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = data.google_container_cluster.default.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "teleport_service_account_key" {
  description = "Teleport service account key"
  value       = module.teleport_service_account.keys["teleport-helm"]
  sensitive   = true
}
