module "cluster" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/gke-autopilot-cluster"
  version = "43.0.0"

  project_id = var.project_id
  name       = "default"
  location   = var.region

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets["${var.region}/${var.subnet_name}"].name

  private_cluster_config = {
    enable_private_endpoint = false
    enable_private_nodes    = true
  }

  ip_allocation_policy = {
    services_secondary_range_name = "gke-services"
    cluster_secondary_range_name  = "gke-pods"
  }

  master_authorized_networks_config = {
    cidr_blocks = [{
      cidr_block   = "0.0.0.0/0"
      display_name = "all allow"
    }]
  }

  workload_identity_config = {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}
