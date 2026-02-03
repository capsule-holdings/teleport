data "google_container_cluster" "default" {
  name     = module.cluster.cluster_name
  location = var.region

  depends_on = [module.cluster]
}
