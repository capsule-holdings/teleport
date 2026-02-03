output "teleport_service_ip" {
  description = "Teleport service load balancer IP"
  value       = data.kubernetes_service_v1.teleport.status[0].load_balancer[0].ingress[0].ip
}
